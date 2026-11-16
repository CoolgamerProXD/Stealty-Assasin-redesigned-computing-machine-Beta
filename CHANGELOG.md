# Current iteration — prototype refinement

- Added nine CC0 Kenney furniture models, glazed hotel bays and restaurant screen, procedural floor finishes, new guest-room beds, and aligned dining chair collisions. Legacy checkpoints overlapping new furniture are relocated where possible.
- Added suite-local target and upper-gallery movement; separated station routes and added accelerated physical round-trip tests for all 16 station actors and four Meridian wing actors. Cross-floor pathfinding remains unimplemented.
- Added contextual synthetic ambient beds and surface-dependent steps, compacted selection and settings to fit 720p, populated the city with fictional parked traffic and skyline, and enlarged the purely scenic mountain landmark.
- Character primitives now share immutable meshes while retaining per-character materials and joint transforms; procedural running and crouching keep shoes near the floor. Quiet Line has a hand-held visual and brief use pose. No performance improvement on the target laptop is claimed without a measurement.
- Fixed the mountain terrain's collision winding after a physical traversal test exposed a blocked seam; added traversal checks on both terrain patches and preview routes, and prevented explicitly mismatched mission action IDs from completing objectives in checkpoint restores.
- Windows CI now launches the exported main menu, both missions and all three previews headlessly. This is not an interactive Windows playtest.

# Second pass — incremental prototype improvements

- Expanded original batched Meridian wing dressing, guest-room and suite details, and floor-local hotel routines. The public wing routes are on a dedicated ground-floor navigation region; there is no cross-floor NPC routing. Locke remains in the upstairs suite. Much of the decorative furniture remains non-colliding and the hotel is still a procedural prototype, not a finished luxury environment.
- Reworked the procedural figures into an upper-body group and hinged knees; crouching now lowers the torso and bends the legs instead of scaling the figure vertically. Steps use a synthesized transient synchronized to gait phase. This is not motion-captured or a production animation set.
- Added static facade/market and mountain-path detail, a few local visitors on open routes, and added collision to selected station columns and the information counter. The three locations remain independent exploration previews, not completed missions.
- Added automated local-route, crouch posture and staged capture coverage. Actual human playtesting and target-device measurement remain outstanding.

# Quality overhaul

- Added separately playable, labelled station, city and Ngong Ping exploration scenes to Mission Selection; Escape returns to the selector without changing campaign progression.
- Preserved the original Meridian and added a connected two-storey west wing, upper guest rooms and a stationary private-suite target. This is a procedural partial expansion, not a fully dressed production hotel; ground footprint ~3.5x, gross two-level surface ~7x.
- Added contextual HUD layout and original equipment icon, procedural document and terminal props, smoothed visual turning and gait-linked footsteps. Retained target terminal state, mission and save migrations. No health or radar was fabricated.

# Hong Kong direction checkpoint

- Preserved Initiation and legacy Meridian, including save paths; added locked planned chapter entries and an explicitly incomplete Tung Chung exploration preview.
- Added a fictional station blockout with a small scheduled crowd and two physical character concepts. No train encounter or campaign completion is claimed. Added station, city and respectful Ngong Ping map/target plans.
- Completed Meridian target state is now terminal, separate from temporary incapacitation, idempotent, and checkpointed with its visual outcome. Removed the experimental lobby reflection probe after a rendered lighting regression.

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
