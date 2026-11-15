# Architecture

Godot 4.4.1, GDScript, Compatibility renderer initially. `scenes/hotel.tscn` is the entry point. The hotel builder is intentionally a greybox composition root; it creates geometry, a hand-authored tiled NavigationRegion3D with two doorway routes per partition, player, actors, interaction markers and minimal HUD. It is not the intended final content pipeline.

- `player/player.gd`: CharacterBody3D movement, spring-arm camera and input; owns a separate inventory instance and emits interaction requests.
- `npc/npc_profile.gd`, `schedule_entry.gd`: configurable Resources. `resources/hotel_population.json` defines names, roles, start points and schedules; the builder translates them into Resources. `npc.gd` owns state, NavigationAgent3D and throttled vision; `npc_memory.gd` holds only its own observations.
- `stealth/access.gd`: role/zone permission separate from awareness. Current zone assignment is positional, not scene-authored.
- `disguise/disguise.gd`: resource foundation; current prototype switches a role and capsule material directly on player.
- `interactions/interactable.gd`: shared availability and activation signal. Composition root dispatches clue, uniform and extraction events.
- `inventory/inventory.gd`, `missions/mission.gd`: independent RefCounted logic; mission tracks unique records and extraction.
- `save/save_store.gd`: versioned JSON file with temporary writes and previous-save backup. `save/session_snapshot.gd` validates and restores mission clues, disguise, player position and marker state; the hotel binds F5/F9. NPC state and settings are not saved.
- `tests/run_tests.gd`: headless behavioral checks, including world interactions and movement.

NPCs do not access one another's memories. No external AI service is used. Future work should replace the composition-root content logic with reusable authored scenes/resources and separate UI, mission content, dialogue and persistence. No simulation LOD, centralized scheduler, sound propagation or cross-NPC reporting is implemented yet.
