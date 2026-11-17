# Visual overhaul research and decisions

**Status:** research baseline plus an initial, unvalidated prototype; not a claim that the visual overhaul is complete. Research was consulted 2026-11-16 before major implementation. A portable Instinct world-grade shader/helper and small seeded procedural face/hair variations have since been added in source, but no Godot runtime, rendered captures, renderer comparison, or Windows target measurement has yet validated them. This project is not licensed to use HITMAN: Codename 47 art, models, textures, sound, code, or other proprietary material. The game is an inspiration/quality reference only; all implementation must be original or independently verified as licensed.

## Project facts established

- Godot **4.4.1**, `gl_compatibility`, 1280×720 project viewport, Windows export preset, and Windows CI export/smoke-test job.
- `scripts/visuals/stylized_person.gd` assembles people from primitive meshes and project-authored colors. It has seeded skin/hair variants, outfit state, a few role accessories and independently pivoted procedural limbs; it is not a skinned, detailed human model or a garment simulation.
- The campaign combines procedural Hong Kong/Tung Chung/Ngong Ping environments and a concealed fictional facility. Environments are blockouts/fictional scenes, not replicas or licensed scans of real places.
- Existing Instinct is based on eligibility and object overlays. The campaign has primary-target discovery logic, sight/range checks for several objects, and intentionally different highlight rules between missions. There is no full-screen environmental desaturation pass.
- Nine Kenney Furniture Kit 2.0 GLBs (CC0) and seven original, generated 256×256 Tung Chung albedo maps are the identified imported/generated art assets. Other inspected world and character art is project-authored procedural geometry/materials. Exact existing provenance is in `ASSETS.md`, `THIRD_PARTY_ASSETS.md` and the asset-local provenance files.
- Existing `PERFORMANCE.md` contains noisy Linux Xvfb/Mesa llvmpipe measurements; none is a Windows/Iris Xe measurement. No target-laptop measurement, target-machine renderer comparison, or visual sign-off has been made.

## Research questions and findings

### Renderer choice and the requested target

Godot 4.4 documents Compatibility as its broad-compatibility, OpenGL renderer and Forward+ as the feature-rich desktop renderer; changing renderer requires checking feature coverage and retuning scenes. [Godot 4.4 renderer comparison](https://docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html). The project is currently Compatibility, which is a verified fact, not proof it is the best choice for Intel Iris Xe. Godot's [4.4 system requirements](https://docs.godotengine.org/en/4.4/about/system_requirements.html) list integrated graphics as minimum hardware for the RenderingDevice renderers, subject to supported APIs/drivers. They do not establish the performance of this particular i5-1335U/Iris Xe configuration.

**Decision:** do not switch renderers by assumption. First implement portable changes and compare Compatibility and, where Windows driver support allows, Mobile and Forward+ on the exact target laptop. Establish image equivalence, supported effects, frame-time distribution, memory, stability, power mode and a repeatable gameplay route before selecting a default. Keep a Compatibility fallback if a renderer change is adopted. Treat GL Compatibility gaps as hard constraints: notably, Godot's [StandardMaterial3D documentation](https://docs.godotengine.org/en/4.4/tutorials/3d/standard_material_3d.html) says SSS is Forward+ only; a skin material that silently assumes SSS is not an acceptable compatibility-wide fix.

### PBR surfaces and lighting

Godot's [Standard/ORM material guide](https://docs.godotengine.org/en/4.4/tutorials/3d/standard_material_3d.html) documents standard physically based material controls and packed occlusion/roughness/metallic channels. Use physically plausible, restrained base-color values, roughness-driven surface identity, authored normals only where useful, and metallic values only for genuinely conductive surfaces. Test all materials under neutral, warm, cool, exterior, and instinct lighting; do not compensate for geometry with random sliders or baked lighting in albedo.

Godot's [GI overview](https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/introduction_to_global_illumination.html) describes ReflectionProbe `Once` as suitable for integrated graphics, LightmapGI as a low-runtime-cost option for static geometry, and real-time GI as a performance/authoring tradeoff. [LightmapGI workflow](https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_lightmap_gi.html) requires lightmap UV/bake preparation and supports hybrid static/dynamic lighting. [Lights and shadows](https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html) documents per-renderer local-light limits and recommends baked lights when a scene exceeds limits.

**Decision:** use a controlled hybrid: coherent ambient/environment fill, a small number of intentional real-time key/practical lights, selective shadows, baked indirect contribution only for stable interiors after UV/bake correctness is confirmed, and ReflectionProbe `Once` only where it adds visible value. Avoid per-window dynamic shadow lights, ubiquitous shadow casters, unmeasured reflection probes, expensive real-time GI and volumetric fog as defaults. Preserve lighting presets and test their actual cost. Cinematic means readable contrast and motivated light, not crushed blacks, glare, or hidden interactables.

### Full-screen focus treatment

Godot's [custom post-processing guide](https://docs.godotengine.org/en/4.4/tutorials/shaders/custom_postprocessing.html) supports a full-viewport `CanvasLayer`/`ColorRect` screen-texture shader. It also notes that arbitrary depth/normal buffers are not exposed to this simple method. The screen shader therefore cannot safely infer object identity or world-space discovery by itself.

**Decision:** retain mission scripts as the authority over what is eligible/highlightable. A single full-screen shader may smoothly desaturate/darken the environment while Instinct is held, but must not identify or reveal anything; existing eligibility rules supply only explicitly allowed overlays. Blend intensity over time, preserve HUD readability, avoid applying the grade to the HUD, and provide a graceful no-effect/default state if the renderer or shader fails. No unknown NPC outlines, hidden routes, undiscovered facility objects, secrets, collectibles, or generic system objects. Primary-target no-depth-test behavior is mission/briefing-authorized and is not a general rule.

### Characters, clothing, animation and import

Godot supports glTF scene/material/animation/skinning import and humanoid SkeletonProfile/BoneMap retargeting. Its [retargeting guide](https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/retargeting_3d_skeletons.html) cautions that bone rest transforms and mappings matter, not just bone names. OBJ does not meet the needs of rigged animated characters; glTF 2.0 is the candidate interchange format. Blender Studio's [published rigging workflow](https://studio.blender.org/tools/pipeline-overview/asset-creation/rigging) describes control-rig generation, manual weight painting and corrective shape keys; this is evidence that high-quality deformation is an authored pipeline, not a material swap.

**Decision:** separate silhouette, body proportions, face/hair, garment shape, color/material, and role markers. Improve visual variety without random role/clothing mismatch. Do not add a character asset until topology, rig, animation permissions, origin/scale, material, texture budget, license, attribution and source are recorded; test it across all disguise states and preserve the current outfit IDs/role API. Existing fully covering civilian underwear, disguise permissions and mission persistence are protected gameplay invariants. PBR detail alone cannot make a primitive person read as a realistic human; a substantiated character result needs body/face/garment geometry, rigged deformation and motion evidence.

### Performance and asset reuse

Godot's [3D optimization guide](https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html) recommends profiling culling, LOD, occlusion and MultiMesh rather than treating them as universal wins; automatic mesh instancing is Forward+-only, while manual MultiMesh is broadly useful for repeated static detail. Occlusion can help interiors but costs CPU and offers less in open areas ([occlusion guide](https://docs.godotengine.org/en/4.4/tutorials/3d/occlusion_culling.html)).

**Decision:** reuse shared meshes/materials, batch genuinely repeated static detail, apply distance/detail policies selectively, and profile. Preserve gameplay-critical character visibility/collision/AI and do not conflate visual LOD with NPC simulation. Benchmark the release build at 1280×720, with warmed shaders and a fixed route, on the named Windows laptop. Report p50/p95/p99 frame times, FPS, memory, scene, NPC count, renderer, preset and power mode. Software-rendered Linux CI is only a regression/smoke environment.

## Evidence and consulted sources

All sources below were actually opened or returned in the research session; URLs are recorded so decisions can be reviewed. Godot documentation is versioned at 4.4 wherever possible.

1. [Godot 4.4 renderers](https://docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html) — renderer capability and platform choice.
2. [Godot 4.4 system requirements](https://docs.godotengine.org/en/4.4/about/system_requirements.html) — hardware/API requirements, not laptop benchmarks.
3. [Godot 4.4 StandardMaterial3D and ORMMaterial3D](https://docs.godotengine.org/en/4.4/tutorials/3d/standard_material_3d.html) — PBR/ORM and renderer limitations such as SSS.
4. [Godot 4.4 global illumination introduction](https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/introduction_to_global_illumination.html) and [LightmapGI](https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_lightmap_gi.html) — GI tradeoffs and hybrid lighting.
5. [Godot 4.4 lights and shadows](https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html) — local light limits, shadow/bake considerations.
6. [Godot 4.4 custom post-processing](https://docs.godotengine.org/en/4.4/tutorials/shaders/custom_postprocessing.html) — screen-texture implementation and data limitations.
7. [Godot 4.4 glTF available formats](https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) and [skeleton retargeting](https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/retargeting_3d_skeletons.html) — import and rig compatibility.
8. [Blender Studio rigging pipeline](https://studio.blender.org/tools/pipeline-overview/asset-creation/rigging) — production rig/weight/corrective-shape workflow.
9. [Godot 4.4 3D performance](https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html), [mesh LOD](https://docs.godotengine.org/en/4.4/tutorials/3d/mesh_lod.html) and [occlusion culling](https://docs.godotengine.org/en/4.4/tutorials/3d/occlusion_culling.html) — profile-led optimization.
10. [Poly Haven license](https://polyhaven.com/license) — its downloadable HDRIs, textures and models are stated to be CC0; recheck the item/license at acquisition and distinguish assets from website logos/text/renders.
11. [ambientCG license](https://docs.ambientcg.com/license/) — downloaded asset files are stated to be CC0; verify each item and preserve its item identity.
12. [Adobe Substance 3D Sampler](https://www.adobe.com/products/substance3d/apps/sampler.html) — describes photo-to-material generation of albedo/roughness/normal/displacement; generated maps still require review and are not ground truth.
13. [Blender glTF 2.0 material documentation](https://docs.blender.org/manual/en/2.80/addons/io_scene_gltf2.html) — glTF metal/roughness channels and skinning/animation support (older Blender manual version; verify exporter behavior for the chosen installed tool version).

Some search results described commercial workflows but were not adopted as evidence for specific implementation values. No proprietary-game art or technology was inspected or used. No asset has been downloaded or selected for this overhaul, and no license is being inferred for an asset merely because a site commonly hosts CC0 files.

## Open decisions and cost envelope

- Renderer default remains Compatibility until a controlled Windows comparison and effect-support audit are completed.
- No exact 30–60 FPS promise is made. The design target is stable, playable 720p on the specified laptop; the measurable threshold must be agreed/reported after hardware is available.
- No source photo scans or external character/environment packs are presently approved. If added, asset-specific license and provenance review is a prerequisite.
- Resource estimate is planning only, not a commitment: **1–2 person-days** for reproducible capture/test tooling and materials baseline; **3–6 person-days** for a reusable character/garment prototype and retarget/disguise validation; **4–8 person-days per major environment family** for coherent geometry, materials, dressing, and lighting; **2–4 person-days** for Instinct integration, performance pass and acceptance evidence. Campaign-wide art-direction/production of detailed people and every room is substantially larger and needs an agreed scope, creator capacity, and review time. Costs for paid software/assets or external art services are unknown and excluded. No purchases are authorized by this research.
