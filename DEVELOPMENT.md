# Development status

## First session — 2026-11-15

The workspace was an empty repository except for a README. This session adds a Godot project and an initial hotel prototype. Checkpoints A–D are **partial**; E is a primitive greybox; F has not been completed. See TESTING.md for verification status.

Implemented in code, pending Godot runtime verification: third-person capsule movement and spring-arm camera; simple partitioned hotel floor with public/staff/secure positional zones; three data-driven scheduled NPCs using navigation agents; throttled visual trespass detection, local memory, suspicion, investigation and routine recovery; a uniform that grants staff access; record interactions, inventory and extraction; HUD; versioned mission snapshot and backup save helper; behavioral test runner.

Limitations: the hotel is a simple partitioned greybox rather than furnished rooms; furniture lacks collision and the navigation mesh is manually tiled, not baked. No operable doors, animations, sound, genuine conversations, simulation LOD, settings persistence, difficulty or graphics presets. Saves currently omit NPC state and are not crash-durability tested. Only alertness and curiosity influence the current NPC logic; other personality properties are reserved. The disguise resource is not yet consumed. There is no separate area alert, information sharing, configurable mission graph, failure condition or persistence of NPC state. The awareness HUD shows the maximum NPC value as debug feedback. Crouch changes speed, not capsule height or visibility. NPC category currently affects appearance, not decision policy. The staff uniform is an unrestricted marker, not a full disguise interaction. These are explicit prototype compromises, not completed systems.

Next: run and fix headless tests on a real Godot build; playtest in editor on Windows; replace the primitive layout with authored interconnected rooms and baked navigation; add real interactions; improve schedule interruption, roles and per-NPC feedback; expand persistence; then measure and optimize on target hardware.

## Continuation — 2026-11-15

Added two physical partitions with alternate openings, a corresponding hand-authored navigation grid and line-of-sight checks for interaction selection. Added F5/F9 mission snapshots with validation and a previous-save backup. Expanded planned Godot tests for real navigation, physics occlusion, interaction reachability and save recovery. These changes remain pending Godot runtime verification. The source build was restarted outside the repository.
