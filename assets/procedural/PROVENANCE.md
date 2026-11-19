# Tung Chung procedural material maps

Seven original, project-generated 256×256 RGBA albedo maps, authored for this repository and licensed as part of PROJECT ASSASSIN. There are no third-party photographs, ripped game assets, references embedded as textures, logos, or real-world station maps. The deterministic generator is `tools/generate_tung_chung_textures.py` and uses only Python's standard library; regenerate from the repository root with:

```sh
python3 tools/generate_tung_chung_textures.py
```

Godot uses the files through `scripts/visuals/station_materials.gd`; material roughness/metallic response and tiling are set there. They are intentionally subtle albedo patterns, not normal maps or a full PBR scan set.

| File | Intended finish |
|---|---|
| `tung_chung_tile.png` | Muted blue-green glazed concourse wall tile with charcoal grout. |
| `tung_chung_terrazzo.png` | Pale mineral floor with fine aggregate flecks. |
| `tung_chung_brushed_metal.png` | Directional satin metal grain for rails, frames and trim. |
| `tung_chung_concrete.png` | Cool, low-frequency architectural concrete variation. |
| `tung_chung_rubber.png` | Dark ribbed anti-slip surface for vehicle floor/thresholds. |
| `tung_chung_train_fabric.png` | Low-contrast woven blue-green seat fabric. |
| `tung_chung_warm_wood.png` | Warm, restrained grain for kiosk/trim accents. |

All maps are deterministic and periodically generated for texture repetition. The script contains the provenance/algorithm; no external texture-generation package is required at runtime or to regenerate.
