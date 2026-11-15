# PROJECT ASSASSIN — audit and stabilisation

Date: 2026-11-15. Starting commit `1ae17eafc89e7af26bb972b9ab6f485181c5ca13` on `arena/1ba0f585-stealty-assasin-redesigned-com`. The tree was clean at the start. This audit is based on source inspection, the user's reported playtest and the explicitly listed static/data checks; it is not a substitute for executing Godot.

## Architecture and evidence

`project.godot` starts `scenes/hotel.tscn`; `scripts/world/hotel.gd` composes primitive geometry, the player, three NPCs, interactables, UI and the mission. Player input emits an interaction signal; the world chooses the nearest visible object; interaction signals update mission/inventory or disguise. NPCs consult the player's role and position through `AccessRules`, then apply field-of-view and ray tests to local trespass observations. NPC state, navigation and memory are local to each actor. Saves call `SaveStore` and `SessionSnapshot` through F5/F9.

| System | Implemented and audited | Verification and limitations |
| --- | --- | --- |
| Player/camera | CharacterBody3D walk/run/crouch speeds, mouse yaw/pitch, SpringArm3D camera, wall collision, interaction ray. | User reports a playtest, but this environment has not run movement, collision, camera or mouse tests. Crouch does not change height or detection. |
| NPCs | Three data-driven profiles with cyclical destinations, local memory, vision, suspicion, timed investigation and return. | No headless runtime result. An unreachable destination can be treated as reached by the current navigation logic; physical blocking can also leave a walking NPC stuck. No timeout, hearing, information sharing or daily clock. Only alertness/curiosity are used. |
| Navigation/environment | Manually tiled floor mesh and two partitions, each with two openings. Primitive furniture is non-solid. | Coordinate checks pass; actual paths, ray occlusion, wall collision and player reachability remain unverified here. |
| Social stealth | Visitor/staff/security/manager role checks; uniform changes role and appearance; NPC detection uses access independently of suspicion. | This is more than a cosmetic change in code, but role-recognition nuance, enforcers and reactions beyond trespass are missing. `DisguiseDefinition` exists but is unused. Runtime behavior not verified here. |
| Mission/HUD | Three authored records, any two needed; extraction and objective messages derived from mission state. | Current configuration and positions pass Python data checks. Spawn, gameplay and HUD regression tests are written but not yet run in Godot. |
| Save/load | Versioned JSON, temporary file and previous backup; mission, role, position and marker state restored. | F5/F9, malformed data, version/backup and consistency scenarios are scripted but not run in Godot. NPCs/settings/other inventory content are not persisted. Atomicity/durability after power failure is untested. |

## Record investigation

At the starting commit the scene code had **three** distinct hard-coded clue spawns: `ledger` at (-5, 0, -3.6), `memo` at (4.5, 0, -4), and `archive` at (9.5, 0, -4). The mission required **two** unique clues; the initial collected count was **zero**. The user's playtest observed **three collected**; their save and exact interaction history are not accessible here. Source search found no five-file mission requirement; the origin of that impression cannot be determined from this checkout.

The three authored positions are within floor/zone bounds, outside the physical partitions and outside the visible counter/table footprints according to the static checks. Doors and full reachability are not runtime-verified. The three markers were created once each by the starting source, but actual spawning has not been independently observed in Godot here. IDs were unique in that code; mission collection rejected duplicates but also accepted any unknown nonempty ID. Collection marked progress even when adding the item to a full inventory failed. The save snapshot separately hard-coded the same three IDs, creating a drift risk.

Two independent presentation defects are identifiable in source:

1. The HUD printed total collected over the minimum required, so collecting all three displayed `Records: 3 / 2`. This did not by itself mean that five items existed or that the minimum was five.
2. `Mission.extract()` returned false after a completed extraction; the interaction handler treated every false as insufficient records, so activating the exit again could show “Gather at least two…” even with enough evidence. Whether this exact sequence caused the user's specific observation is unconfirmed.

The fix retains the intended two-of-three rule. `resources/meridian_mission.json` now defines records, positions and threshold; `Mission` validates it, tracks available and collected unique IDs, generates the HUD/objective text and enforces extraction. Spawns and save restoration use the same definitions. Invalid/duplicate/missing definitions and impossible requirements fail closed; the world also checks inventory capacity and static layout bounds. Collection no longer consumes a marker or advances progress if inventory is full. Repeat extraction now reports completion. The HUD labels collected/available and required separately. Version 1 save fields remain compatible, subject to filtering invalid/duplicate IDs and capacity.

## Testing and performance status

- **Automated-data verified:** six Python checks passed, including configured count, IDs, floor bounds and counter footprints. These do not execute the game.
- **Static analysis only:** `gdparse` accepted the GDScript syntax; external `gdcorrect` reported zero project/scene/lint findings. Neither tool provides Godot runtime/type-check verification.
- **Godot runtime verified:** none in this sandbox. Godot 4.4.1 is not installed; the prebuilt download redirected to a blocked host. A headless source build is still compiling and was configured to run import/tests afterward. New tests exist but do not have results yet. The user's independent playtest is not a complete regression run.
- **Performance:** no startup, memory, frame-time, FPS, NPC or GPU measurements are available. The sandbox is Debian on a virtual 2-core Xeon with about 3.85 GiB RAM, not the target Iris Xe laptop. Compatibility is provisional. NPC memory no longer creates a filtered array every physics tick; the improvement has not been benchmarked.

## Remaining risks and next checkpoint

The code changes require Godot 4.4.1 import, the full headless test suite, and an interactive Windows playtest before this can be called stable or playable. Confirm all three markers spawn and can be reached, inspect two and all three in separate runs, repeat extraction, test F5/F9 and corrupt/legacy saves, then exercise blocked and unblocked sightlines and NPC routine recovery. Follow with a focused NPC navigation/stuck-recovery pass based on observed failures, and measure renderers and performance on the actual laptop. There are no animations, audio, operable doors, NPC simulation tiers, baked lighting, populated luxury rooms or target-hardware results yet.
