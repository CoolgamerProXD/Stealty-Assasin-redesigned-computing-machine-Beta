# Development status

## Campaign expansion status
The entry scene is now the main menu. To develop the two greyboxes directly, run `scenes/initiation.tscn` or `scenes/hotel.tscn`; campaign completion transitions and pause integration are enabled when the campaign launches them. The existing player and NPC capsule models and spring-arm controller are retained. Crouch modifies their dimensions/eye pivot, not the basic controller. The additional content is an incremental foundation; see README for missing deliverables.

## First session — 2026-11-15

The workspace was an empty repository except for a README. This session adds a Godot project and an initial hotel prototype. Checkpoints A–D are **partial**; E is a primitive greybox; F has not been completed. See TESTING.md for verification status.

Implemented in code, pending Godot runtime verification: third-person capsule movement and spring-arm camera; simple partitioned hotel floor with public/staff/secure positional zones; three data-driven scheduled NPCs using navigation agents; throttled visual trespass detection, local memory, suspicion, investigation and routine recovery; a uniform that grants staff access; record interactions, inventory and extraction; HUD; versioned mission snapshot and backup save helper; behavioral test runner.

Historical early-prototype note (superseded where it conflicts with README and the current audit): the hotel is a simple partitioned greybox rather than furnished rooms; furniture lacks collision and the navigation mesh is manually tiled, not baked. No operable doors, animations, sound, genuine conversations, simulation LOD, settings persistence, difficulty or graphics presets. Saves currently omit NPC state and are not crash-durability tested. Only alertness and curiosity influence the current NPC logic; other personality properties are reserved. The disguise resource is not yet consumed. There is no separate area alert, information sharing, configurable mission graph, failure condition or persistence of NPC state. The awareness HUD shows the maximum NPC value as debug feedback. Crouch changes speed, not capsule height or visibility. NPC category currently affects appearance, not decision policy. The staff uniform is an unrestricted marker, not a full disguise interaction. These are explicit prototype compromises, not completed systems.

Next: run and fix headless tests on a real Godot build; playtest in editor on Windows; replace the primitive layout with authored interconnected rooms and baked navigation; add real interactions; improve schedule interruption, roles and per-NPC feedback; expand persistence; then measure and optimize on target hardware.

## Continuation — 2026-11-15

Added two physical partitions with alternate openings, a corresponding hand-authored navigation grid and line-of-sight checks for interaction selection. Added F5/F9 mission snapshots with validation and a previous-save backup. Expanded planned Godot tests for real navigation, physics occlusion, interaction reachability and save recovery. These changes remain pending Godot runtime verification. The source build was restarted outside the repository.

## Audit and stabilisation — 2026-11-15

Moved the three record definitions and unchanged two-record requirement into one validated mission configuration. The HUD now separates collected, available and required counts; extraction gives an accurate already-completed message. Collection and restoration check the same IDs and inventory capacity. Invalid configurations fail closed, and saved player positions inside partitions are rejected. NPC memory expiry no longer allocates a filtered array every physics tick. Expanded headless tests are present but not runtime-verified; see AUDIT.md and TESTING.md.

## Runtime regression — 2026-11-15

Official Godot 4.4.1 CI run 43699069502 passed 63 headless behavioral checks and five automated camera checks on Xvfb. A corrupt-save log-spam defect was fixed without changing player, NPC, camera, scene or hotel files. A human Windows playtest and target performance measurements remain outstanding; see TESTING.md and PERFORMANCE.md. Earlier session entries are historical.
