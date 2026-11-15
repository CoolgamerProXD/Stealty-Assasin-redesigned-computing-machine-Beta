# Architecture

Godot 4.4.1, GDScript, Compatibility renderer initially. `scenes/main_menu.tscn` is the entry point. The hotel builder is intentionally a greybox composition root; it creates geometry, a hand-authored tiled NavigationRegion3D with two doorway routes per partition, player, actors, interaction markers and minimal HUD. It is not the intended final content pipeline.

- `player/player.gd`: CharacterBody3D movement, spring-arm camera and input; owns a separate inventory instance and emits interaction requests.
- `npc/npc_profile.gd`, `schedule_entry.gd`: configurable Resources. `resources/hotel_population.json` defines names, roles, start points and schedules; the builder translates them into Resources. `npc.gd` owns state, NavigationAgent3D and throttled vision; `npc_memory.gd` holds only its own observations.
- `stealth/access.gd`: role/zone permission separate from awareness. Current zone assignment is positional, not scene-authored.
- `disguise/disguise.gd`: resource foundation; current prototype switches a role and capsule material directly on player.
- `interactions/interactable.gd`: shared availability and activation signal. Composition root dispatches clue, uniform and extraction events.
- `resources/meridian_mission.json` supplies record identities, positions, text and the required count; `missions/mission.gd` validates it and owns available records, unique progress, objective text and extraction. The hotel spawns markers from the same data; the save snapshot filters against it. `inventory/inventory.gd` tracks carried records separately and prevents counting an uncollected item if capacity is exhausted.
- `save/save_store.gd`: versioned JSON file with temporary writes and previous-save backup. `save/session_snapshot.gd` validates and restores mission clues, disguise, player position and marker state; the hotel binds F5/F9. NPC state is not saved; settings use a separate versioned file.
- `tests/run_tests.gd`: headless behavioral checks, including world interactions and movement.

NPCs do not access one another's memories. No external AI service is used. Future work should replace the composition-root content logic with reusable authored scenes/resources and separate UI, mission content, dialogue and persistence. No simulation LOD, centralized scheduler, sound propagation or cross-NPC reporting is implemented yet.

## Campaign foundation

`resources/campaign.json` supplies ordered missions, Ruby's text and equipment metadata. `CampaignProgress` validates and restores ordered unlocks and selection. The `Campaign` autoload persists progression and settings independently of per-mission saves, starts scenes and passes results to `ending.tscn`. It retains the legacy Meridian path. `initiation.gd` subclasses the hotel composition root to reuse the same player, NPC, interaction, HUD, and save code; it overrides geometry, population, records and mission-specific position validation. Mission optionally requires an action in addition to records, captured in the snapshot. The menu, pause panel and debrief are separate scripts. Campaign scenes are not a substitute for a complete content architecture; direct scene tests leave campaign integration inactive.

Loadout data currently has no in-world equipment implementation or deployment enforcement; `item_allowed` only checks metadata. There is no equipment inventory or charge persistence. Avoid treating the menu as proof of a usable weapon or gadget.
