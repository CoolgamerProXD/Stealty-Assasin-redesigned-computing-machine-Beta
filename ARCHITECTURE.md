# Two-floor hotel and selectable previews

The hotel builds a connected western extension plus upper slabs and a physical ramp, leaving the original mission coordinates intact. Upper areas contain a suite and guest rooms; the target's long-duration schedule stays in the suite. Existing NPC navmesh remains on the original level; the independent upper region is not a connected cross-floor route. Save validation permits the added volume but does not fully model all new interior walls. The ground-level footprint is about 3.5x the former layout; summing the two gross floor plates gives about 7x, before subtracting walls and stairwell. The map remains procedural and partially visual-only. The three previews have their own scenes and return to the map selector; no mission or save state is faked.

# Current Hong Kong checkpoint

`TungChungPreview` is a separate exploratory scene, not an assignment: it uses the existing player and scheduled NPC classes, a fictional rectangular navmesh and original modular geometry. Its lack of mission state, shooting, checkpoints, Instinct and train mechanics is intentional and visible in the menu. Meridian keeps its existing mission identity and checkpoint; planned Hong Kong chapters have no scene and cannot be unlocked as playable. Completed physical Meridian targets have a terminal NPC state separate from temporary incapacitation; the checkpoint stores whether the objective was completed with a downed pose.

# Architecture

## Environment and local reactions
`EnvironmentDressing` builds two color-instanced box batches and non-shadowing practical lights on top of unchanged collision/navigation layouts. LOW disables practicals and fine detail; MEDIUM enables practicals; HIGH includes fine detail and FXAA. The experimental probe was removed after a rendered luminance regression. `DisturbanceSystem` periodically tests each conscious observer's range, facing and physics line of sight to incapacitated NPCs. Only the seeing NPC stores and investigates the observation. `HotelPlayer` retains the spring arm, with interpolated FOV/shoulder and hand-attached procedural weapon blending; objective and movement cues use original synthesized sound.


## Target/aim/Instinct integration
Mission configuration has a separate primary-target definition and completion/discovery flags; the Meridian manager is an independently scheduled HotelNpc while Ivo remains a witness. SessionSnapshot stores target state and migrates previously completed saves. The existing player pivot/spring arm interpolates to aim and sends a fire signal; the world casts from the camera's screen-centre ray, applies obstruction/impact results, feedback and ammo. Instinct uses a no-depth-test red material overlay on the briefing-identified primary's actual visual meshes, and separate configurable proximity/view/LOS-limited yellow item overlays. Other NPCs are not highlighted. The cinematic remains an independent scripted timeline with procedural exterior geometry.

## Critical gameplay update
`MissionEquipment` owns deployment slots, selection and five-charge state; the world handles use and NPC reactions. `SessionSnapshot` stores it and validates optional items against campaign unlocks on restore. The HUD is composed by the mission world and reads live mission, NPC and equipment state. The Meridian witness is the existing Ivo Chen NPC with a moving child interactable; both missions use `Mission.required_action` and the same snapshot. Old completed Meridian saves receive the witness flag during migration. `StylizedPerson` supplies original articulated procedural visuals without changing CharacterBody3D or the spring arm. `ruby_meeting.gd` is a separate timeline-driven 3D sequence with procedural tones; campaign completion is persisted before entry. Historical sections below may describe earlier versions.

Godot 4.4.1, GDScript, Compatibility renderer initially. `scenes/main_menu.tscn` is the entry point. The hotel builder is intentionally a greybox composition root; it creates geometry, a hand-authored tiled NavigationRegion3D with two doorway routes per partition, player, actors, interaction markers and minimal HUD. It is not the intended final content pipeline.

- `player/player.gd`: CharacterBody3D movement, spring-arm camera and input; owns a separate inventory instance and emits interaction requests.
- `npc/npc_profile.gd`, `schedule_entry.gd`: configurable Resources. `resources/hotel_population.json` defines names, roles, start points and schedules; the builder translates them into Resources. `npc.gd` owns state, NavigationAgent3D and throttled vision; `npc_memory.gd` holds only its own observations.
- `stealth/access.gd`: role/zone permission separate from awareness. Current zone assignment is positional, not scene-authored.
- `disguise/disguise.gd`: resource foundation; current prototype switches a role and procedural clothing material directly on the player.
- `interactions/interactable.gd`: shared availability and activation signal. Composition root dispatches clue, uniform and extraction events.
- `resources/meridian_mission.json` supplies record identities, positions, text and the required count; `missions/mission.gd` validates it and owns available records, unique progress, objective text and extraction. The hotel spawns markers from the same data; the save snapshot filters against it. `inventory/inventory.gd` tracks carried records separately and prevents counting an uncollected item if capacity is exhausted.
- `save/save_store.gd`: versioned JSON file with temporary writes and previous-save backup. `save/session_snapshot.gd` validates and restores mission clues, disguise, player position and marker state; the hotel binds F5/F9. NPC state is not saved; settings use a separate versioned file.
- `tests/run_tests.gd`: headless behavioral checks, including world interactions and movement.

NPCs do not access one another's memories. No external AI service is used. Future work should replace the composition-root content logic with reusable authored scenes/resources and separate UI, mission content, dialogue and persistence. No simulation LOD, centralized scheduler, sound propagation or cross-NPC reporting is implemented yet.

## Campaign foundation

`resources/campaign.json` supplies ordered missions, Ruby's text and equipment metadata. `CampaignProgress` validates and restores ordered unlocks and selection. The `Campaign` autoload persists progression and settings independently of per-mission saves, starts scenes and passes results to `ending.tscn`. It retains the legacy Meridian path. `initiation.gd` subclasses the hotel composition root to reuse the same player, NPC, interaction, HUD, and save code; it overrides geometry, population, records and mission-specific position validation. Mission optionally requires an action in addition to records, captured in the snapshot. The menu, pause panel and debrief are separate scripts. Campaign scenes are not a substitute for a complete content architecture; direct scene tests leave campaign integration inactive.

`item_allowed` gates the optional equipment before deployment and on checkpoint restore. The per-mission equipment state is separate from evidence inventory; charges and selection are persisted. The effects are deliberately abstract and do not implement projectiles, detailed stealth combat or persistent NPC incapacitation.
