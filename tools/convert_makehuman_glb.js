#!/usr/bin/env node
'use strict';

// Canonicalize a decoded MakeHuman GLB for Godot's core glTF importer:
// remove EXT_texture_webp by encoding PNG bufferViews, and keep skinning and
// material alpha masks. This script never edits geometry, UVs or joint weights.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');

if (process.argv.length !== 5) {
  console.error('Usage: convert_makehuman_glb.js input.glb output.glb model-name');
  process.exit(2);
}
const [inputPath, outputPath, modelName] = process.argv.slice(2);

function readChunks(bytes) {
  if (bytes.toString('ascii', 0, 4) !== 'glTF' || bytes.readUInt32LE(4) !== 2) {
    throw new Error(`${inputPath} is not a glTF 2.0 binary`);
  }
  let cursor = 12;
  let json = null;
  let bin = Buffer.alloc(0);
  while (cursor + 8 <= bytes.length) {
    const size = bytes.readUInt32LE(cursor);
    const type = bytes.readUInt32LE(cursor + 4);
    cursor += 8;
    const chunk = bytes.subarray(cursor, cursor + size);
    cursor += size;
    if (type === 0x4e4f534a) json = JSON.parse(chunk.toString('utf8').trim());
    else if (type === 0x004e4942) bin = Buffer.from(chunk);
  }
  if (!json) throw new Error('GLB JSON chunk missing');
  return { json, bin };
}
function align4(value) { return (value + 3) & ~3; }

(async () => {
  const { json, bin: originalBin } = readChunks(fs.readFileSync(inputPath));
  let bin = originalBin;
  let converted = 0;
  for (let imageIndex = 0; imageIndex < (json.images || []).length; imageIndex++) {
    const image = json.images[imageIndex];
    if (image.uri || image.bufferView === undefined) {
      throw new Error(`Unexpected non-embedded image in ${modelName}: ${image.name || imageIndex}`);
    }
    const view = json.bufferViews[image.bufferView];
    if (view.buffer !== 0) throw new Error('Only GLB buffer 0 is supported.');
    const start = view.byteOffset || 0;
    const end = start + view.byteLength;
    const source = bin.subarray(start, end);
    const png = await sharp(source, { failOn: 'error' })
      .resize({ width: 1024, height: 1024, fit: 'inside', withoutEnlargement: true })
      .png({ compressionLevel: 7, adaptiveFiltering: true })
      .toBuffer();
    const offset = align4(bin.length);
    if (offset > bin.length) bin = Buffer.concat([bin, Buffer.alloc(offset - bin.length)]);
    const byteOffset = bin.length;
    const paddedLength = align4(png.length);
    bin = Buffer.concat([bin, png, Buffer.alloc(paddedLength - png.length)]);
    image.bufferView = json.bufferViews.length;
    image.mimeType = 'image/png';
    json.bufferViews.push({ buffer: 0, byteOffset, byteLength: png.length });
    converted++;
  }

  for (const texture of json.textures || []) {
    const webp = texture.extensions && texture.extensions.EXT_texture_webp;
    if (webp) {
      texture.source = webp.source;
      delete texture.extensions.EXT_texture_webp;
      if (Object.keys(texture.extensions).length === 0) delete texture.extensions;
    }
  }
  json.extensionsUsed = (json.extensionsUsed || []).filter((name) => name !== 'EXT_texture_webp' && name !== 'EXT_meshopt_compression' && name !== 'KHR_mesh_quantization');
  json.extensionsRequired = (json.extensionsRequired || []).filter((name) => name !== 'EXT_texture_webp' && name !== 'EXT_meshopt_compression' && name !== 'KHR_mesh_quantization');
  if (json.extensionsUsed.length === 0) delete json.extensionsUsed;
  if (json.extensionsRequired.length === 0) delete json.extensionsRequired;

  // The source export declared every surface BLEND. Character surfaces are
  // opaque or cutout; mask mode preserves lashes/brow cutouts without blend
  // sorting, and makes them eligible for depth/shadow passes.
  for (const material of json.materials || []) {
    material.alphaMode = 'MASK';
    material.alphaCutoff = 0.36;
  }
  json.buffers[0].byteLength = bin.length;
  const jsonChunk = Buffer.from(JSON.stringify(json), 'utf8');
  const jsonPaddedLength = align4(jsonChunk.length);
  const jsonPadded = Buffer.concat([jsonChunk, Buffer.alloc(jsonPaddedLength - jsonChunk.length, 0x20)]);
  const binPaddedLength = align4(bin.length);
  const binPadded = Buffer.concat([bin, Buffer.alloc(binPaddedLength - bin.length)]);
  const totalLength = 12 + 8 + jsonPadded.length + 8 + binPadded.length;
  const header = Buffer.alloc(12);
  header.write('glTF', 0, 'ascii');
  header.writeUInt32LE(2, 4);
  header.writeUInt32LE(totalLength, 8);
  const jsonHeader = Buffer.alloc(8);
  jsonHeader.writeUInt32LE(jsonPadded.length, 0);
  jsonHeader.writeUInt32LE(0x4e4f534a, 4);
  const binHeader = Buffer.alloc(8);
  binHeader.writeUInt32LE(binPadded.length, 0);
  binHeader.writeUInt32LE(0x004e4942, 4);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, Buffer.concat([header, jsonHeader, jsonPadded, binHeader, binPadded]));
  console.log(`${modelName}: ${converted} embedded PNG textures, ${json.nodes.length} nodes, ${json.meshes.length} meshes, ${json.skins.length} skins, ${Math.round(totalLength / 1024)} KiB`);
})().catch((error) => { console.error(error); process.exit(1); });
