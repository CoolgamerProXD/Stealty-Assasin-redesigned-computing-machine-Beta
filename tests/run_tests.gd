extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, description: String) -> void:
 checks += 1
 if condition:
  print("PASS: ", description)
 else:
  failures.append(description)
  printerr("FAIL: ", description)

func run() -> void:
 check(AccessRules.can_enter("visitor", "public"), "visitor may enter public")
 check(not AccessRules.can_enter("visitor", "staff"), "visitor denied staff")
 check(AccessRules.can_enter("staff", "staff"), "staff granted staff")
 check(not AccessRules.can_enter("staff", "secure"), "staff denied secure")
 check(not AccessRules.can_enter("manager", "unknown"), "unknown areas fail closed")
 var bag := Inventory.new()
 bag.capacity = 1
 check(bag.add("ledger") and bag.has_item("ledger"), "inventory stores item")
 check(not bag.add("ledger") and not bag.add("memo"), "inventory rejects duplicate and overflow")
 var mission := Mission.new()
 mission.record_clue("ledger")
 mission.record_clue("ledger")
 check(not mission.extract(), "duplicate clue cannot unlock extraction")
 mission.record_clue("memo")
 check(mission.extract() and mission.extracted and not mission.extract(), "two clues unlock one extraction")
 var memory := NpcMemory.new()
 memory.retention_seconds = 2.0
 memory.observe("trespass", Vector3.ONE)
 memory.tick(1.0)
 check(memory.observations.size() == 1 and memory.observations[0]["source"] == "direct", "memory retains direct observation")
 memory.tick(1.1)
 check(memory.observations.is_empty(), "memory expires")
 var save_path := "user://test_save.json"
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
 check(SaveStore.write(save_path, {"clues": ["ledger"]}), "write versioned save")
 check(SaveStore.read(save_path).get("clues", []) == ["ledger"], "read versioned save")
 check(SaveStore.write(save_path, {"clues": ["memo"]}), "replace save and keep backup")
 var corrupt := FileAccess.open(save_path, FileAccess.WRITE)
 corrupt.store_string("not json")
 corrupt.close()
 check(SaveStore.read(save_path).get("clues", []) == ["ledger"], "corrupt save falls back to backup")
 check(SaveStore.write(save_path, {"clues": ["archive"]}), "write after primary corruption")
 corrupt = FileAccess.open(save_path, FileAccess.WRITE)
 corrupt.store_string("not json")
 corrupt.close()
 check(SaveStore.read(save_path).get("clues", []) == ["ledger"], "writing after corruption preserves good backup")
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
 check(SaveStore.read(save_path).is_empty(), "missing save handled")
 var scene: PackedScene = load("res://scenes/hotel.tscn")
 var world: Node = scene.instantiate()
 root.add_child(world)
 await process_frame
 await physics_frame
 var player: HotelPlayer = world.get("player")
 var npcs: Array[HotelNpc] = world.get("npcs")
 check(player != null and npcs.size() == 3, "hotel creates player and three scheduled NPCs")
 var npc: HotelNpc = npcs[0]
 var npc_start := npc.global_position
 await create_timer(2.5).timeout
 check(npc.global_position.distance_to(npc_start) > 0.2, "scheduled NPC navigates toward its destination")
 npc.facing = Vector3.FORWARD
 check(npc.can_see(npc.global_position + Vector3.FORWARD * 3.0), "NPC sees in field of view")
 check(not npc.can_see(npc.global_position + Vector3.BACK * 3.0), "NPC cannot see behind")
 check(not npc.can_see(npc.global_position + Vector3.FORWARD * 3.0, false), "occlusion prevents sight")
 npc.observe_trespass(Vector3(6, 0, 1))
 check(npc.state == "suspicious" and npc.memory.observations.size() == 1, "observation creates local memory and suspicion")
 npc.advance_simulation(0.1)
 check(npc.state == "investigating", "suspicion triggers investigation")
 npc.advance_simulation(11.0)
 check(npc.state == "returning", "investigation returns to routine")
 player.set_disguise("staff")
 check(player.role == "staff" and AccessRules.can_enter(player.role, "staff"), "disguise changes access")
 # Exercise real player physics and input, away from walls and interactables.
 player.global_position = Vector3(-8, 0.1, 0)
 await physics_frame
 var start := player.global_position
 Input.action_press("move_forward")
 await create_timer(0.6).timeout
 Input.action_release("move_forward")
 check(player.global_position.distance_to(start) > 0.3, "input moves player through physics")
 var map: RID = player.get_world_3d().get_navigation_map()
 var route: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(0, 0, 0), Vector3(4, 0, 0), true)
 var detours: bool = false
 for point: Vector3 in route:
  if absf(point.z) > 2.0: detours = true
 check(route.size() >= 3 and detours, "navigation route detours through a partition opening")
 # Test actual throttled perception and physics occlusion, not only the FOV helper.
 for existing: HotelNpc in npcs:
  existing.set_physics_process(false)
  existing.collision_layer = 0
 var observer := HotelNpc.new()
 observer.profile = NpcProfile.new()
 observer.player = player
 observer.position = Vector3(1, 0.05, 0)
 world.add_child(observer)
 observer.facing = Vector3.RIGHT
 player.set_disguise("visitor")
 player.global_position = Vector3(3, 0.05, 0)
 await create_timer(0.9).timeout
 check(observer.memory.observations.is_empty(), "solid partition blocks NPC sight")
 observer.global_position = Vector3(1, 0.05, 3)
 player.global_position = Vector3(3, 0.05, 3)
 await create_timer(0.9).timeout
 check(not observer.memory.observations.is_empty() and observer.suspicion > 0.0, "NPC observes trespass through an opening")
 observer.set_physics_process(false)
 observer.collision_layer = 0
 player.set_disguise("staff")
 # Interaction selection must not reach through a wall, even within range.
 var objects: Array[Interactable] = world.get("interactables")
 var blocked_object := Interactable.new()
 blocked_object.position = Vector3(2.8, 0, 0)
 world.add_child(blocked_object)
 objects.append(blocked_object)
 player.global_position = Vector3(1.2, 0.05, 0)
 await physics_frame
 check(world.call("_nearest") != blocked_object, "interaction cannot reach through a wall")
 blocked_object.position = Vector3(2.8, 0, 3)
 player.global_position = Vector3(1.2, 0.05, 3)
 await physics_frame
 check(world.call("_nearest") == blocked_object, "interaction can reach through an opening")
 objects.erase(blocked_object)
 blocked_object.queue_free()
 # Exercise the actual interaction signal path and objective progression.
 player.global_position = objects[0].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 var active_mission: Mission = world.get("mission")
 check(active_mission.clues.has("ledger") and player.inventory.has_item("ledger"), "world interaction records clue and item")
 player.global_position = objects[1].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 player.global_position = objects[4].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 check(active_mission.extracted, "world interactions complete mission")
 var snapshot := SessionSnapshot.capture(player, active_mission)
 active_mission.clues.clear()
 active_mission.extracted = false
 player.set_disguise("visitor")
 SessionSnapshot.restore(snapshot, player, active_mission, objects)
 check(active_mission.extracted and active_mission.clues.size() == 2 and player.role == "staff", "snapshot restores mission and disguise")
 check(objects[0].used and not objects[0].visible and player.inventory.has_item("ledger"), "snapshot restores world markers and inventory")
 SessionSnapshot.restore({"clues": ["ledger", "ledger", "invalid"], "role": 42, "extracted": true, "position": ["invalid", 0, 0]}, player, active_mission, objects)
 check(active_mission.clues.size() == 1 and not active_mission.extracted and player.role == "visitor", "snapshot safely handles malformed data")
 world.queue_free()
 await process_frame
 print("RESULT: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
