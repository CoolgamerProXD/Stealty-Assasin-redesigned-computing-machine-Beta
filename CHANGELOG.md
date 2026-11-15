# Changelog

## 2026-11-15 — initial prototype

- Established Godot project, third-person player and primitive hotel greybox.
- Added configurable NPC profiles, schedules, navigation, local perception, memory and basic investigation.
- Added access rules, staff-role disguise, reusable interaction component, inventory, clue objectives and extraction.
- Added versioned save utility, headless test runner and development documentation. Runtime verification status is documented in TESTING.md.

## Continuation — 2026-11-15

- Added physical zone partitions, alternate doorway routes, tiled navigation and interaction line-of-sight checks.
- Connected versioned mission snapshots with validated restoration and previous-save backup to F5/F9.
- Expanded behavioral and data checks; Godot runtime verification remains pending.

## Audit and stabilisation — 2026-11-15

- Centralized and validated three-record / two-required mission data; aligned spawning, collection, HUD, extraction and save restoration.
- Prevented false repeat-extraction instructions and rejected invalid saved positions inside partitions.
- Expanded regression scenarios and reduced NPC memory-array churn. Godot runtime testing remains pending.
