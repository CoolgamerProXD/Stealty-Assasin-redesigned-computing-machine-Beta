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
 var definition: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/meridian_mission.json"))
 check(not mission.configure(null) and not mission.can_extract(), "missing mission configuration fails closed")
 check(not mission.configure({"records": [], "required_records": 2}), "empty mission configuration rejected")
 var invalid: Dictionary = definition.duplicate(true)
 invalid["records"][1]["id"] = invalid["records"][0]["id"]
 check(not mission.configure(invalid), "duplicate configured IDs rejected")
 invalid = definition.duplicate(true)
 invalid["required_records"] = 4
 check(not mission.configure(invalid), "impossible requirement rejected")
 invalid = definition.duplicate(true)
 invalid["records"][0]["position"] = [0, "invalid", 0]
 check(not mission.configure(invalid), "invalid record position rejected")
 check(mission.configure(definition) and mission.available_records.size() == 3 and mission.required_records == 2, "mission config defines three records and requires two")
 check(not mission.record_clue("unknown"), "unconfigured record rejected")
 check(mission.record_clue("ledger") and not mission.record_clue("ledger"), "duplicate clue cannot be recorded")
 check(not mission.extract(), "one unique clue cannot unlock extraction")
 check(mission.record_clue("memo") and not mission.extract(), "two clues alone cannot replace the target objective")
 check(mission.mark_action("interview_ivo") and mission.extract() and mission.extracted and not mission.extract(), "two clues and the witness unlock one extraction")
 check(mission.record_clue("archive") and mission.progress_text().contains("3 / 3") and mission.progress_text().contains("Required: 2"), "progress distinguishes available and required after third clue")
 var memory := NpcMemory.new()
 memory.retention_seconds = 2.0
 memory.observe("trespass", Vector3.ONE)
 memory.tick(1.0)
 check(memory.observations.size() == 1 and memory.observations[0]["source"] == "direct", "memory retains direct observation")
 memory.tick(1.1)
 check(memory.observations.is_empty(), "memory expires")
 var save_path := "user://assassin_test_store_%d.json" % Time.get_ticks_usec()
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
 var incompatible := FileAccess.open(save_path + ".bak", FileAccess.WRITE)
 incompatible.store_string(JSON.stringify({"version": 999, "data": {"clues": ["memo"]}}))
 incompatible.close()
 check(SaveStore.read(save_path).is_empty(), "unsupported save version is rejected")
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
 var spawned: Array[Interactable] = world.get("interactables")
 var spawned_ids: Array[String] = []
 for obj: Interactable in spawned:
  if obj.kind == "clue": spawned_ids.append(obj.identifier)
 var world_mission: Mission = world.get("mission")
 check(spawned_ids.size() == world_mission.available_records.size() and spawned_ids.size() == 3, "every configured record spawns exactly once")
 check(spawned_ids.has("ledger") and spawned_ids.has("memo") and spawned_ids.has("archive"), "all unique configured records spawn")
 var npc: HotelNpc = npcs[0]
 var npc_start := npc.global_position
 await create_timer(2.5).timeout
 check(npc.global_position.distance_to(npc_start) > 0.2, "scheduled NPC navigates toward its destination")
 var navmap: RID = player.get_world_3d().get_navigation_map()
 var records_on_navmesh := true
 for obj: Interactable in spawned:
  if obj.kind == "clue" and NavigationServer3D.map_get_closest_point(navmap, obj.global_position).distance_to(obj.global_position) > 0.5:
   records_on_navmesh = false
 check(records_on_navmesh, "all record markers are on the navigation mesh")
 await create_timer(2.0).timeout
 check(npc.schedule_index == 1, "NPC advances to the next scheduled destination")
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
 await create_timer(8.0).timeout
 check(npc.state not in ["investigating", "suspicious", "returning"], "NPC resumes its interrupted schedule")
 player.set_disguise("staff")
 check(player.role == "staff" and AccessRules.can_enter(player.role, "staff"), "disguise changes access")
 for existing: HotelNpc in npcs:
  existing.set_physics_process(false)
  existing.collision_layer = 0
 # Exercise real player physics and input, away from walls and interactables.
 player.global_position = Vector3(-10, 0.1, 0)
 await physics_frame
 var start := player.global_position
 Input.action_press("move_forward")
 await create_timer(0.6).timeout
 Input.action_release("move_forward")
 var walk_distance: float = player.global_position.distance_to(start)
 check(walk_distance > 0.3, "input moves player through physics")
 player.global_position = Vector3(-10, 0.1, 0)
 player.velocity = Vector3.ZERO
 await physics_frame
 start = player.global_position
 Input.action_press("sprint")
 Input.action_press("move_forward")
 await create_timer(0.6).timeout
 Input.action_release("move_forward")
 Input.action_release("sprint")
 var run_distance: float = player.global_position.distance_to(start)
 player.global_position = Vector3(-10, 0.1, 0)
 player.velocity = Vector3.ZERO
 await physics_frame
 start = player.global_position
 Input.action_press("crouch")
 Input.action_press("move_forward")
 await create_timer(0.6).timeout
 Input.action_release("move_forward")
 Input.action_release("crouch")
 var crouch_distance: float = player.global_position.distance_to(start)
 check(run_distance > walk_distance and walk_distance > crouch_distance, "run and crouch change movement speed")
 player.global_position = Vector3(1, 0.1, 0)
 player.velocity = Vector3.ZERO
 await physics_frame
 Input.action_press("move_right")
 await create_timer(0.8).timeout
 Input.action_release("move_right")
 check(player.global_position.x < 1.75, "player collides with partition")
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
 player.inventory.capacity = 0
 world.call("_interact_nearest")
 check(not objects[0].used and world_mission.clues.is_empty(), "full inventory does not consume or count record")
 player.inventory.capacity = 6
 var interaction_event := InputEventAction.new()
 interaction_event.action = "interact"
 interaction_event.pressed = true
 player._unhandled_input(interaction_event)
 var active_mission: Mission = world.get("mission")
 check(active_mission.clues.has("ledger") and player.inventory.has_item("ledger"), "world interaction records clue and item")
 player.global_position = objects[1].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 player.global_position = objects[4].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 check(not active_mission.extracted, "Meridian exit requires target as well as records")
 var witness: Interactable = objects[5]
 var witness_npc := witness.get_parent() as HotelNpc
 witness_npc.stunned_time = 1.0
 world.call("_on_interaction", witness)
 check(not active_mission.action_complete, "incapacitated witness cannot be questioned")
 witness_npc.stunned_time = 0.0
 player.global_position = witness.global_position + Vector3(0, 0.1, 0.7)
 await physics_frame
 var question := InputEventAction.new()
 question.action = "interact"
 question.pressed = true
 Input.parse_input_event(question)
 await process_frame
 await physics_frame
 await process_frame
 check(active_mission.action_complete, "physical Ivo target can be questioned through input")
 question.pressed = false
 Input.parse_input_event(question)
 player.global_position = objects[4].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 check(active_mission.extracted, "world interactions complete mission")
 world.call("_interact_nearest")
 check(str(world.get("message")).contains("already complete"), "repeat extraction does not show a false requirement")
 # Exercise the actual world F5/F9 handlers with an isolated, unique save file.
 var world_save := "user://assassin_test_%d.json" % Time.get_ticks_usec()
 world.set("save_path", world_save)
 var save_event := InputEventAction.new()
 save_event.action = "save_game"
 save_event.pressed = true
 world.call("_unhandled_input", save_event)
 check(FileAccess.file_exists(world_save), "save action writes a mission save")
 var snapshot := SessionSnapshot.capture(player, active_mission)
 active_mission.clues.clear()
 active_mission.extracted = false
 player.set_disguise("visitor")
 var load_event := InputEventAction.new()
 load_event.action = "load_game"
 load_event.pressed = true
 world.call("_unhandled_input", load_event)
 check(active_mission.extracted and player.role == "staff", "load action restores saved gameplay state")
 SessionSnapshot.restore(snapshot, player, active_mission, objects)
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(world_save + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(world_save + suffix))
 check(active_mission.extracted and active_mission.clues.size() == 2 and player.role == "staff", "snapshot restores mission and disguise")
 check(objects[0].used and not objects[0].visible and player.inventory.has_item("ledger"), "snapshot restores world markers and inventory")
 SessionSnapshot.restore({"clues": ["ledger", "ledger", "invalid"], "role": 42, "extracted": true, "position": ["invalid", 0, 0]}, player, active_mission, objects)
 check(active_mission.clues.size() == 1 and not active_mission.extracted and player.role == "visitor", "snapshot safely handles malformed data")
 var safe_position := player.global_position
 SessionSnapshot.restore({"position": [2, 0, 0]}, player, active_mission, objects)
 check(player.global_position == safe_position, "snapshot refuses position inside a wall")
 player.inventory.capacity = 1
 SessionSnapshot.restore({"clues": ["ledger", "memo"], "extracted": true}, player, active_mission, objects)
 check(active_mission.clues.size() == 1 and player.inventory.items.size() == 1 and not active_mission.extracted, "snapshot cannot exceed inventory capacity")
 player.inventory.capacity = 6
 player.global_position = objects[1].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 player.global_position = objects[2].global_position + Vector3(0, 0.1, 0.5)
 world.call("_interact_nearest")
 world.call("_process", 0.0)
 var hud: Label = world.get("hud")
 check(active_mission.clues.size() == 3 and hud.text.contains("3 / 3") and hud.text.contains("Required: 2"), "HUD reflects collected, available and required records")
 var before_duplicate: int = active_mission.clues.size()
 world.call("_on_interaction", objects[2])
 check(active_mission.clues.size() == before_duplicate, "repeated collection does not duplicate progress")
 world.queue_free()
 await process_frame
 var campaign := CampaignProgress.new()
 var campaign_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign.json"))
 check(campaign.configure(campaign_data), "campaign data loads")
 check(campaign.is_unlocked("initiation") and not campaign.is_unlocked("meridian") and not campaign.is_unlocked("future"), "campaign starts in chronological order")
 check(not campaign.item_unlocked("quiet_line") and not campaign.select_item("quiet_line"), "locked equipment cannot be selected")
 check(campaign.mark_complete("initiation") and campaign.is_unlocked("meridian") and campaign.item_unlocked("quiet_line"), "completion unlocks Meridian and quiet line")
 check(campaign.select_item("quiet_line") and campaign.item_allowed("quiet_line", "meridian") and not campaign.item_allowed("quiet_line", "initiation"), "equipment restrictions enforced by campaign data")
 var campaign_copy := CampaignProgress.new()
 campaign_copy.configure(campaign_data)
 campaign_copy.restore(campaign.snapshot())
 check(campaign_copy.completed.has("initiation") and campaign_copy.selected == "quiet_line" and campaign_copy.is_unlocked("initiation"), "campaign progress and replay survive restore")
 campaign_copy.restore({"completed": ["meridian"], "selected": "quiet_line"})
 check(campaign_copy.completed.is_empty() and campaign_copy.selected == "training_sidearm", "out-of-order save cannot bypass unlocks")
 var gadget_world: Node = scene.instantiate()
 root.add_child(gadget_world)
 await process_frame
 await physics_frame
 var gadget_player: HotelPlayer = gadget_world.get("player")
 var gadget_npcs: Array[HotelNpc] = gadget_world.get("npcs")
 gadget_player.equipment.configure(campaign, "meridian")
 check(gadget_player.equipment.available.has("quiet_line") and gadget_player.equipment.selected == "quiet_line", "unlocked selected gadget is provisioned in Meridian")
 var guard: HotelNpc = gadget_npcs[0]
 for person: HotelNpc in gadget_npcs:
  person.set_physics_process(false)
  person.collision_layer = 0
 guard.global_position = Vector3(-9, 0.05, 1)
 gadget_player.global_position = Vector3(-9, 0.05, 2)
 await physics_frame
 var select_event := InputEventAction.new()
 select_event.action = "equip_secondary"
 select_event.pressed = true
 Input.parse_input_event(select_event)
 var gadget_event := InputEventAction.new()
 gadget_event.action = "use_equipment"
 gadget_event.pressed = true
 Input.parse_input_event(gadget_event)
 await process_frame
 await physics_frame
 await process_frame
 print("EQUIP_DIAG: gadget selected=", gadget_player.equipment.selected, " stun=", guard.stunned_time, " message=", gadget_world.get("message"))
 check(guard.stunned_time > 0 and gadget_player.equipment.selected == "quiet_line", "gadget input temporarily disables a nearby NPC")
 gadget_world.call("_process", 0.0)
 check(gadget_world.get("hud").text.contains("IVO CHEN") and gadget_world.get("equipment_hud").text.contains("QUIET LINE"), "Meridian HUD displays target and equipped gadget")
 var gadget_snapshot := SessionSnapshot.capture(gadget_player, gadget_world.get("mission"))
 var equipment_save := "user://assassin_equipment_test_%d.json" % Time.get_ticks_usec()
 check(SaveStore.write(equipment_save, gadget_snapshot), "equipment checkpoint writes to disk")
 gadget_player.equipment.configure(campaign_copy, "meridian")
 SessionSnapshot.restore(SaveStore.read(equipment_save), gadget_player, gadget_world.get("mission"), gadget_world.get("interactables"), Callable(gadget_world, "safe_position"), campaign)
 check(gadget_player.equipment.available.has("quiet_line") and gadget_player.equipment.selected == "quiet_line", "checkpoint restores unlocked gadget selection")
 gadget_player.equipment.configure(campaign_copy, "meridian")
 SessionSnapshot.restore(gadget_snapshot, gadget_player, gadget_world.get("mission"), gadget_world.get("interactables"), Callable(gadget_world, "safe_position"), campaign_copy)
 check(not gadget_player.equipment.available.has("quiet_line"), "checkpoint cannot grant a locked gadget")
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(equipment_save + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(equipment_save + suffix))
 gadget_world.queue_free()
 await process_frame
 var initiation_scene: PackedScene = load("res://scenes/initiation.tscn")
 var initiation: Node = initiation_scene.instantiate()
 root.add_child(initiation)
 await process_frame
 await physics_frame
 var init_mission: Mission = initiation.get("mission")
 var init_player: HotelPlayer = initiation.get("player")
 var init_objects: Array[Interactable] = initiation.get("interactables")
 var init_npcs: Array[HotelNpc] = initiation.get("npcs")
 check(init_mission.configured and init_npcs.size() == 2, "Initiation spawns configured mission and exactly two guards")
 initiation.call("_process", 0.0)
 check(initiation.get("hud").text.contains("ASSESSMENT UNIT") and initiation.get("equipment_hud").text.contains("5 / 5"), "Initiation HUD shows target and real starting charges")
 check(init_player.body_mesh is StylizedPerson and init_npcs[0].person is StylizedPerson, "player and guard spawn articulated visual characters")
 var start_guard := init_npcs[0].global_position
 init_player.global_position = Vector3(-12, 0.05, 0)
 Input.action_press("crouch")
 await create_timer(0.4).timeout
 check(init_player.crouching and init_player.stance_height < 1.3 and init_player.pivot.position.y < 1.2, "crouch smoothly lowers collision and camera")
 var ceiling := StaticBody3D.new()
 var ceiling_collision := CollisionShape3D.new()
 var ceiling_box := BoxShape3D.new()
 ceiling_box.size = Vector3(2, 0.2, 2)
 ceiling_collision.shape = ceiling_box
 ceiling.add_child(ceiling_collision)
 initiation.add_child(ceiling)
 ceiling.global_position = init_player.global_position + Vector3.UP * 1.4
 await physics_frame
 Input.action_release("crouch")
 await create_timer(0.4).timeout
 check(init_player.crouching and init_player.stance_height < 1.3, "ceiling prevents standing into solid geometry")
 ceiling.queue_free()
 await create_timer(0.4).timeout
 check(not init_player.crouching and init_player.stance_height > 1.75, "player stands after crouch when space is clear")
 check(init_npcs[0].global_position.distance_to(start_guard) > 0.2, "Initiation guard follows its route")
 for obj: Interactable in init_objects:
  if obj.kind == "clue": initiation.call("_on_interaction", obj)
 check(init_mission.clues.size() == 3 and not init_mission.can_extract(), "three records alone cannot complete assessment")
 var before_robot := SessionSnapshot.capture(init_player, init_mission)
 var assessment: Interactable = null
 for obj: Interactable in init_objects:
  if obj.kind == "robot": assessment = obj
 for init_guard: HotelNpc in init_npcs:
  init_guard.set_physics_process(false)
  init_guard.collision_layer = 0
 init_player.global_position = assessment.global_position + Vector3(0, 0.05, 1)
 await physics_frame
 await physics_frame
 check(initiation.get("robot_alert") == true, "assessment unit reacts to nearby visible player")
 initiation.set_physics_process(false)
 var use_event := InputEventAction.new()
 use_event.action = "use_equipment"
 use_event.pressed = true
 Input.parse_input_event(use_event)
 await process_frame
 await physics_frame
 await process_frame
 print("EQUIP_DIAG: robot=", init_mission.action_complete, " charges=", init_player.equipment.charges, " message=", initiation.get("message"))
 check(init_mission.action_complete and init_player.equipment.charges == 4, "equipment input disables unit and spends one charge")
 for i: int in range(5):
  use_event.pressed = false
  Input.parse_input_event(use_event)
  use_event.pressed = true
  Input.parse_input_event(use_event)
  await process_frame
  await physics_frame
 initiation.call("_process", 0.0)
 check(init_player.equipment.charges == 0 and initiation.get("equipment_hud").text.contains("0 / 5"), "five-charge limit and HUD update follow input")
 check(init_mission.action_complete and init_mission.can_extract(), "assessment unit and three unique records unlock exit")
 var after_robot := SessionSnapshot.capture(init_player, init_mission)
 SessionSnapshot.restore(before_robot, init_player, init_mission, init_objects, Callable(initiation, "safe_position"), campaign)
 check(init_player.equipment.charges == 5, "checkpoint restores training charges")
 check(not init_mission.action_complete and not init_mission.can_extract(), "snapshot restores active unit")
 SessionSnapshot.restore(after_robot, init_player, init_mission, init_objects, Callable(initiation, "safe_position"), campaign)
 check(init_player.equipment.charges == 0, "checkpoint preserves spent charges")
 check(init_mission.action_complete and init_mission.clues.size() == 3 and init_mission.can_extract(), "snapshot restores disabled unit and all records")
 for obj: Interactable in init_objects:
  if obj.kind == "extract": initiation.call("_on_interaction", obj)
 check(init_mission.extracted, "Initiation exit completes only after objectives")
 initiation.queue_free()
 await process_frame
 # Exercise actual campaign scene changes against an isolated campaign save.
 var service := root.get_node("Campaign")
 var saved_progress: Dictionary = service.progress.snapshot()
 var saved_path: String = service.campaign_path
 var isolated_path := "user://assassin_campaign_test_%d.json" % Time.get_ticks_usec()
 service.campaign_path = isolated_path
 service.progress.restore({})
 check(service.begin("initiation"), "campaign begins an unlocked mission")
 await process_frame
 await process_frame
 var deployed: Node = current_scene
 check(deployed != null and deployed.scene_file_path == "res://scenes/initiation.tscn", "campaign changes to Initiation scene")
 if deployed != null and deployed.scene_file_path == "res://scenes/initiation.tscn":
  var pause_menu: Node = null
  for child: Node in deployed.get_children():
   if child.get_script() and child.get_script().resource_path == "res://scripts/ui/pause_menu.gd": pause_menu = child
  check(pause_menu != null, "campaign mission creates pause menu")
  if pause_menu:
   var escape_event := InputEventAction.new()
   escape_event.action = "release_mouse"
   escape_event.pressed = true
   pause_menu.call("_input", escape_event)
   check(paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause stops simulation and releases mouse")
   pause_menu.call("_resume")
   check(not paused, "resume restarts simulation")
  else:
   check(false, "pause stops simulation and releases mouse")
   check(false, "resume restarts simulation")
  var deployed_objects: Array[Interactable] = deployed.get("interactables")
  for obj: Interactable in deployed_objects:
   if obj.kind == "clue" or obj.kind == "robot": deployed.call("_on_interaction", obj)
  for obj: Interactable in deployed_objects:
   if obj.kind == "extract": deployed.call("_on_interaction", obj)
  await process_frame
  await process_frame
  check(current_scene != null and current_scene.scene_file_path == "res://scenes/ruby_meeting.tscn" and service.progress.is_unlocked("meridian"), "objective completion saves unlock and opens Ruby scene")
  if current_scene != null and current_scene.scene_file_path == "res://scenes/ruby_meeting.tscn":
   current_scene.call("_apply_timeline", 6.0, 0.1)
   check(current_scene.get("actor").position.z < 0.0 and current_scene.get("left_door").position.x < -2.0, "cinematic timeline opens doors and walks outside")
   var skip_event := InputEventAction.new()
   skip_event.action = "release_mouse"
   skip_event.pressed = true
   Input.parse_input_event(skip_event)
   await process_frame
   await physics_frame
   await process_frame
   check(service.progress.is_unlocked("meridian"), "skipping Ruby scene preserves campaign unlock")
  else:
   check(false, "cinematic timeline opens doors and walks outside")
   check(false, "skipping Ruby scene preserves campaign unlock")
  if current_scene != null and current_scene.scene_file_path == "res://scenes/ending.tscn":
   current_scene.call("_continue")
   await process_frame
   await process_frame
   check(current_scene != null and current_scene.scene_file_path == "res://scenes/main_menu.tscn", "debrief can be skipped to main menu")
  else: check(false, "debrief can be skipped to main menu")
 else:
  check(false, "campaign mission creates pause menu")
  check(false, "pause stops simulation and releases mouse")
  check(false, "resume restarts simulation")
  check(false, "objective completion saves unlock and opens Ruby scene")
  check(false, "cinematic timeline opens doors and walks outside")
  check(false, "skipping Ruby scene preserves campaign unlock")
  check(false, "debrief can be skipped to main menu")
 if current_scene != null:
  current_scene.queue_free()
  current_scene = null
 service.active_mission = ""
 service.progress.restore(saved_progress)
 service.campaign_path = saved_path
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(isolated_path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated_path + suffix))
 await process_frame
 print("RESULT: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
