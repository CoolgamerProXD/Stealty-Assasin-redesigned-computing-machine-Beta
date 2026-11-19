"""Structural checks for the pinned MakeHuman-derived CC0 GLB conversions."""
import json
import struct
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "characters" / "makehuman_cc0"
MODELS = ("brad", "dale", "ellie", "gary", "hollis", "pickles", "rosa", "vance")


def read_glb(path: Path):
    data = path.read_bytes()
    if data[:4] != b"glTF":
        raise AssertionError(f"{path.name} lacks GLB magic")
    version, total = struct.unpack_from("<II", data, 4)
    if version != 2 or total != len(data):
        raise AssertionError(f"{path.name} has bad GLB header/version/length")
    cursor = 12
    document = None
    chunks = []
    while cursor < len(data):
        length, kind = struct.unpack_from("<II", data, cursor)
        cursor += 8
        chunk = data[cursor:cursor + length]
        if len(chunk) != length:
            raise AssertionError(f"{path.name} has truncated GLB chunk")
        cursor += length
        chunks.append((kind, chunk))
        if kind == 0x4E4F534A:
            document = json.loads(chunk.rstrip(b" \x00"))
    if cursor != len(data) or document is None:
        raise AssertionError(f"{path.name} has incomplete GLB chunks")
    return document, chunks


class Cc0CharacterAssetTests(unittest.TestCase):
    def test_all_eight_converted_skinned_models_have_png_and_no_optional_compression(self):
        digests = set()
        for name in MODELS:
            with self.subTest(model=name):
                path = ASSET_DIR / f"{name}.glb"
                self.assertTrue(path.is_file(), f"missing {path}")
                document, chunks = read_glb(path)
                self.assertEqual(document.get("asset", {}).get("version"), "2.0")
                self.assertGreaterEqual(len(document.get("skins", [])), 1)
                self.assertGreaterEqual(len(document.get("meshes", [])), 1)
                for mesh in document["meshes"]:
                    for primitive in mesh["primitives"]:
                        material_index = primitive.get("material")
                        if material_index is not None and "normalTexture" in document["materials"][material_index]:
                            self.assertIn("TANGENT", primitive["attributes"], "normal-mapped garment meshes need authored MikkTSpace tangents")
                self.assertEqual(document.get("extensionsUsed", []), [])
                self.assertEqual(document.get("extensionsRequired", []), [])
                self.assertEqual(document["buffers"][0]["byteLength"] % 4, 0)
                images = document.get("images", [])
                self.assertTrue(images)
                for image in images:
                    self.assertEqual(image.get("mimeType"), "image/png")
                    self.assertIn(image.get("bufferView"), range(len(document["bufferViews"])))
                    view = document["bufferViews"][image["bufferView"]]
                    payload = next(chunk for kind, chunk in chunks if kind == 0x004E4942)
                    image_data = payload[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
                    self.assertTrue(image_data.startswith(bytes.fromhex("89504e470d0a1a0a")))
                digests.add(path.read_bytes())
        self.assertEqual(len(digests), len(MODELS), "expected eight distinct model files")

    def test_provenance_and_license_are_shipped_with_assets(self):
        self.assertTrue((ASSET_DIR / "CC0-1.0.txt").is_file())
        self.assertTrue((ASSET_DIR / "SOURCE_ASSETS.md").is_file())
        provenance = (ASSET_DIR / "PROVENANCE.md").read_text(encoding="utf-8")
        self.assertIn("7c331e647229364f3160790fe158beedf132075a", provenance)
        self.assertIn("remains unverified", provenance)


if __name__ == "__main__":
    unittest.main()
