#!/usr/bin/env bash
set -euo pipefail

# Rebuild the eight documented MakeHuman/MPFB CC0 characters for Godot 4.4.1.
# The source GLBs use Meshopt, quantized accessors, and WebP, none of which are
# relied on in the shipped Godot import. Conversion is deterministic in source
# selection and preserves mesh/material content apart from PNG resampling.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node -e 'const major = Number(process.versions.node.split(".")[0]); if (major < 20) { console.error("Node.js 20 or newer is required."); process.exit(1); }'
command -v npm >/dev/null || { echo "npm is required." >&2; exit 1; }
COMMIT="7c331e647229364f3160790fe158beedf132075a"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/src" "$TMP/npm" "$ROOT/assets/characters/makehuman_cc0"
curl --fail --location --retry 3 "https://codeload.github.com/kimhongjae94/rubberneck-assets/tar.gz/$COMMIT" -o "$TMP/source.tar.gz"
tar -xzf "$TMP/source.tar.gz" -C "$TMP/src" --strip-components=1
npm install --prefix "$TMP/npm" --no-save --no-package-lock @gltf-transform/cli@4.5.1 sharp@0.35.5
CLI="$TMP/npm/node_modules/@gltf-transform/cli/bin/cli.js"
for name in brad dale ellie gary hollis pickles rosa vance; do
  NODE_PATH="$TMP/npm/node_modules" node "$CLI" copy "$TMP/src/models/$name.glb" "$TMP/$name.meshopt-decoded.glb"
  NODE_PATH="$TMP/npm/node_modules" node "$CLI" dequantize "$TMP/$name.meshopt-decoded.glb" "$TMP/$name.standard.glb"
  NODE_PATH="$TMP/npm/node_modules" node "$CLI" tangents "$TMP/$name.standard.glb" "$TMP/$name.tangent.glb"
  NODE_PATH="$TMP/npm/node_modules" node "$ROOT/tools/convert_makehuman_glb.js" "$TMP/$name.tangent.glb" "$ROOT/assets/characters/makehuman_cc0/$name.glb" "$name"
done
cp "$TMP/src/LICENSE" "$ROOT/assets/characters/makehuman_cc0/CC0-1.0.txt"
cp "$TMP/src/ASSETS.md" "$ROOT/assets/characters/makehuman_cc0/SOURCE_ASSETS.md"
cat > "$ROOT/assets/characters/makehuman_cc0/PROVENANCE.md" <<'EOF'
# MakeHuman-derived CC0 character models

Eight human character models (Brad, Dale, Ellie, Gary, Hollis, Pickles, Rosa, Vance) are from HongJaeKIM94 and contributors in the RUBBERNECK character asset repository, pinned at commit `@SOURCE_COMMIT@`: https://github.com/kimhongjae94/rubberneck-assets/tree/@SOURCE_COMMIT@/models . The source README and asset inventory identify these as MakeHuman/MPFB-derived CC0 models. The source repository's CC0 license and its file-level source notes are preserved alongside the converted models. MakeHuman's system assets are independently identified as CC0 by the MakeHuman FAQ (https://static.makehumancommunity.org/makehuman/faq/are_makehuman_files_free.html); this provenance does not grant rights over unrelated third-party assets. Inspect `SOURCE_ASSETS.md` before redistribution. Blender and MPFB are not used at runtime.

Local modifications: glTF Transform CLI 4.5.1 decoded `EXT_meshopt_compression`, dequantized `KHR_mesh_quantization`, and generated MikkTSpace vertex tangents to remove tangent-reconstruction portability warnings. `tools/convert_makehuman_glb.js` converts embedded WebP images into PNG (resizing only when either dimension exceeds 1024 px) and changes material alpha handling to `MASK` with cutoff 0.36. The model geometry, UVs, skin weights, skeletons, and image pixels (except resampling) were not intentionally altered. Rebuild with `tools/prepare_cc0_characters.sh` (requires curl, tar, npm, and Node.js 20 or newer).

Validation: glTF-Validator `2.0.0-dev.3.10` reported zero errors and zero warnings on all eight converted files. Godot 4.4.1 import/runtime visual compatibility remains unverified. This pipeline and structural checks do not imply visual or runtime acceptance.

Original license is `CC0-1.0.txt`; upstream per-asset inventory is `SOURCE_ASSETS.md`. CC0 does not require attribution; voluntary credit: HongJaeKIM94 and the MakeHuman community.
EOF
sed -i "s/@SOURCE_COMMIT@/$COMMIT/g" "$ROOT/assets/characters/makehuman_cc0/PROVENANCE.md"
