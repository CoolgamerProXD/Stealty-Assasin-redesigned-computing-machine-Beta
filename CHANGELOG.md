# Changelog

## Absolute Cinema iteration
- Added batched original hotel and annex dressing, practical lights and high-only fine detail.
- Added stance-derived sight rays, local disturbance discovery and simple scheduled activity gestures.
- Smoothed shoulder/FOV and weapon draw/aim/holster blending; added synthesized steps, ambience, UI and objective cues.
- Added shared Blackline UI styling, hit confirmation, smoother Ruby camera transitions, expanded rendered capture automation, and a Windows export/smoke job.
- HIGH uses FXAA and a single static lobby reflection probe; LOW omits the probe, practical lights and fine dressing.
- Remains a low-poly prototype; no claim of AAA art, a human playtest or target-laptop performance.


## Gameplay repair (2026-11)
- Briefing-known primary targets use a red no-depth-test mesh overlay; visible nearby relevant items remain yellow.
- A pulse on Adrian completes the primary objective; added simple hand-mounted sidearm poses and flash and more assessment-unit parts.
- Added persisted viewport quality presets and FPS toggle, compacted HUD, and automated rendered wall comparisons in CI.
- Production art, comprehensive preset scaling and physical-device playtesting remain outstanding.


## Target, aiming and Instinct update (unreleased)
- Add scheduled Meridian primary target Adrian Locke while retaining Ivo as witness, and migrate completed legacy checkpoints.
- Add RMB aim, center-ray LMB firing, collision impacts, audio/trace feedback and five-charge enforcement.
- Add Left Ctrl Instinct with discovered-target and nearby visible-item highlights, and a procedural Ruby exterior and character refinement. See testing notes for verification and limitations.

## Critical gameplay update (unreleased)
- Add live mission/equipment HUD, actual selected loadout, five-charge unsuppressed assessment pulses and non-graphic Quiet Line interaction; persist equipment in compatible checkpoints.
- Add Ivo Chen as the Meridian's physical witness objective; assessment unit now reacts to proximity. Preserve previously completed Meridian checkpoints.
- Add skippable 3D Ruby meeting with doors, moving actors, cameras, subtitles and synthesized tones; replace character capsules with original articulated low-poly figures and add basic environmental trim.
- These are still prototypes, not a production character/environment overhaul. See README for limitations and test scope.

## Campaign foundation (unreleased)
- Add original BLACKLINE/Ruby/Covenant campaign data, progression/unlock/replay and persistent settings, main menu, pause and results/debrief screen.
- Add Initiation greybox with two scheduled guards, moving assessment unit and three required records; reuse existing player, NPC, interaction and save systems, preserving the Meridian save path.
- Smooth crouch dimensions and camera pivot with a standing clearance check. Add campaign and mission runtime checks. Equipment is not usable; large requested systems and final production work remain incomplete (see README).

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

## Runtime regression — 2026-11-15

- Added official Godot 4.4.1 import, headless gameplay, virtual-display camera and timing checks to CI.
- Fixed expected malformed-save recovery emitting engine error logs; kept backup recovery behavior.
- Added schedule-recovery, interaction-input, camera and timing regression checks. Player, NPC and hotel presentation remain unchanged.
