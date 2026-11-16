extends SceneTree
## Integrated scene/objective/checkpoint exercise with isolated campaign files.
var checks := 0
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(condition: bool, text: String) -> void:
 checks += 1
 if condition: print("HK PASS: ", text)
 else:
  failures += 1
  printerr("HK FAIL: ", text)
func move_near(world: Node3D, point: Vector3) -> void:
 var player: HotelPlayer = world.get("player")
 player.global_position = point + Vector3(0,0,1.2)
 player.velocity = Vector3.ZERO
 await physics_frame
func walk_steps(steps: Array) -> void:
 for step: Array in steps:
  Input.action_press(str(step[0]))
  await create_timer(float(step[1])).timeout
  Input.action_release(str(step[0]))
  await physics_frame

func run() -> void:
 var service := root.get_node("Campaign")
 var old_path: String = service.campaign_path
 var old_active: String = service.active_mission
 var old_progress: Dictionary = service.progress.snapshot()
 var temp := "user://assassin_hk_test_%d" % Time.get_ticks_usec()
 service.campaign_path = temp + "_campaign.json"
 service.progress.restore({"completed": ["initiation"], "recovered_keys": ["key_05"]})
 check(not service.progress.recovered_keys.has("key_05") and not service.progress.usb_ready(), "restore rejects a future mission's key before that mission unlocks")
 service.progress.restore({})
 check(not service.acknowledge_usb_decryption(), "USB story event remains locked before the five keys and final operation")
 var test_guard := HotelNpc.new()
 test_guard.profile = NpcProfile.new()
 test_guard.profile.occupation = "security"
 root.add_child(test_guard)
 test_guard.set_physics_process(false)
 test_guard.warn_trespass(Vector3.ZERO, Vector3.LEFT, "staff")
 check(test_guard.state == "warning" and is_equal_approx(test_guard.warning_remaining, 3.0), "security issues a three-second warning")
 test_guard.tick_trespass(2.0, true)
 test_guard.warn_trespass(Vector3.ZERO, Vector3.LEFT, "staff")
 check(test_guard.state == "warning" and test_guard.warning_remaining <= 1.01, "repeated sightings do not restart the grace period")
 test_guard.tick_trespass(1.1, true)
 check(test_guard.state == "alerted", "security escalates after the grace period")
 test_guard.tick_trespass(0.1, false)
 check(test_guard.state == "returning", "leaving the restricted area de-escalates security")
 var old_phase := test_guard.person.phase
 for frame: int in range(30): test_guard.person.animate_motion(1.0 / 60.0, 3.0, 1.0)
 check(test_guard.person.phase > old_phase and test_guard.person.gait_speed > 2.5 and absf(test_guard.person.upper_body.rotation.z) > 0.005, "security animation responds to motion and turning")
 for frame: int in range(90): test_guard.person.animate_motion(1.0 / 60.0, 0.0, 0.0)
 check(test_guard.person.gait_speed < 0.05 and absf(test_guard.person.upper_body.rotation.x) < 0.01, "animation blends back to idle after stopping")
 var test_player := HotelPlayer.new()
 test_player.position = Vector3(0,0,-3)
 root.add_child(test_player)
 test_player.set_physics_process(false)
 test_player.set_process_unhandled_input(false)
 test_guard.player = test_player
 test_guard.warning_cooldown = 0.0
 test_guard.warn_trespass(test_player.global_position, Vector3.LEFT, "staff")
 await physics_frame
 check(not test_guard._fire_alert_pulse() and test_player.stagger_remaining == 0.0, "security cannot fire during the warning grace period")
 test_guard.tick_trespass(3.1, true)
 check(test_guard._fire_alert_pulse() and test_player.stagger_remaining > 0.0, "alerted security can briefly stagger an exposed player")
 var wall := StaticBody3D.new()
 wall.position = Vector3(0,1,-1.5)
 var wall_collision := CollisionShape3D.new()
 var wall_shape := BoxShape3D.new()
 wall_shape.size = Vector3(2,2,0.2)
 wall_collision.shape = wall_shape
 wall.add_child(wall_collision)
 root.add_child(wall)
 await physics_frame
 test_player.stagger_remaining = 0.0
 check(not test_guard._fire_alert_pulse() and test_player.stagger_remaining == 0.0, "solid cover blocks the fictional security pulse")
 wall.queue_free()
 test_player.queue_free()
 test_guard.queue_free()
 var visitor := HotelNpc.new()
 visitor.profile = NpcProfile.new()
 visitor.profile.occupation = "civilian"
 root.add_child(visitor)
 visitor.set_physics_process(false)
 visitor.warn_trespass(Vector3.ZERO, Vector3.LEFT, "staff")
 check(visitor.state == "seeking_help", "visitor seeks help instead of becoming hostile")
 visitor.queue_free()
 var staff := HotelNpc.new()
 staff.profile = NpcProfile.new()
 staff.profile.occupation = "employee"
 root.add_child(staff)
 staff.set_physics_process(false)
 staff.warn_trespass(Vector3.ZERO, Vector3.LEFT, "secure")
 check(staff.state == "seeking_help", "staff without secure-area permission seek help")
 staff.queue_free()
 var officer := HotelNpc.new()
 officer.profile = NpcProfile.new()
 officer.profile.occupation = "security"
 officer.position = Vector3(40,0,40)
 root.add_child(officer)
 officer.set_physics_process(false)
 var witness := HotelNpc.new()
 witness.profile = NpcProfile.new()
 witness.profile.occupation = "civilian"
 witness.position = Vector3(41.5,0,40)
 root.add_child(witness)
 witness.set_physics_process(false)
 witness.warn_trespass(Vector3(43,0,40), Vector3(35,0,40), "staff")
 await physics_frame
 check(witness.help_target == officer and witness._try_deliver_report(), "visitor gives a local in-person report to nearby security")
 check(officer.state == "suspicious" and officer.memory.observations.size() == 1 and not witness._try_deliver_report(), "guard investigates one report without immediate hostility or duplicate reports")
 officer.set_state("idle")
 officer.memory.observations.clear()
 witness.warning_cooldown = 0.0
 witness.set_state("idle")
 witness.observe_incapacitated(Vector3(42,0,40))
 check(witness.state == "seeking_help" and witness.incident_help, "a civilian discovering an incapacitated person seeks help rather than attacking")
 check(witness._try_deliver_report() and officer.state == "suspicious", "a civilian can report an observed incapacitated person to local security")
 officer.queue_free()
 witness.queue_free()
 var guard_one := HotelNpc.new()
 guard_one.profile = NpcProfile.new()
 guard_one.profile.occupation = "security"
 guard_one.position = Vector3(35,0,35)
 root.add_child(guard_one)
 guard_one.set_physics_process(false)
 var guard_two := HotelNpc.new()
 guard_two.profile = NpcProfile.new()
 guard_two.profile.occupation = "security"
 guard_two.position = Vector3(37,0,35)
 root.add_child(guard_two)
 guard_two.set_physics_process(false)
 await physics_frame
 guard_one.warn_trespass(Vector3(36,0,32), Vector3(30,0,35), "staff")
 guard_one.tick_trespass(3.1, true)
 check(guard_one.state == "alerted" and guard_two.state == "suspicious", "security shares a local warning escalation without making other guards immediately hostile")
 guard_one.queue_free()
 guard_two.queue_free()
 check(service.progress.mark_complete("initiation"), "Initiation unlocks Hong Kong without mandatory Meridian")
 var ids := ["tung_chung", "the_streets", "the_district", "the_harbour", "ngong_ping"]
 var intro_paths: Dictionary = {}
 for i: int in range(ids.size()):
  var id: String = ids[i]
  var key_id := "key_%02d" % (i+1)
  check(service.progress.is_unlocked(id), id + " unlocked in chronological order")
  check(not service.progress.mark_complete(id), id + " cannot complete without its own key")
  check(not service.progress.secure_key(id, "key_99"), id + " rejects a different key")
  service.active_mission = id
  var world: Node3D = load("res://scenes/mission_" + id + ".tscn").instantiate()
  root.add_child(world)
  await process_frame
  var player: HotelPlayer = world.get("player")
  var target: HotelNpc = world.get("target")
  var guard: HotelNpc = world.get("guard")
  var people: Array[HotelNpc] = world.get("npc_list")
  for npc: HotelNpc in people:
   npc.set_physics_process(false)
   if npc != target and npc != guard: npc.collision_layer = 0
  world.set("save_path", temp + "_" + id + ".json")
  check(world.get("intro_active") and not player.is_physics_processing(), id + " intro starts before gameplay")
  var intro_start: Vector3 = world.get("intro_start")
  var intro_end: Vector3 = world.get("intro_end")
  intro_paths[str(intro_start - target.global_position) + "/" + str(intro_end - target.global_position)] = true
  var skip_event := InputEventAction.new()
  skip_event.action = "release_mouse"
  skip_event.pressed = true
  world.call("_input", skip_event)
  check(not world.get("intro_active") and player.is_physics_processing(), id + " Escape skips the introduction and initializes gameplay")
  if id == "tung_chung":
   var old_fps: bool = service.settings["show_fps"]
   service.settings["show_fps"] = true
   world.call("_process", 0.0)
   check((world.get("fps_label") as Label).visible, "FPS setting appears in Hong Kong HUD")
   service.settings["show_fps"] = old_fps
  # Walk from the actual deployment point to each target with fixed inputs.
  # Background agents are frozen/temporarily non-colliding to isolate world
  # geometry; this does not claim crowd navigation or a human playthrough.
  target.collision_layer = 0
  guard.collision_layer = 0
  player.rotation.y = 0.0
  player.velocity = Vector3.ZERO
  Engine.time_scale = 3.0
  match id:
   "tung_chung": await walk_steps([["move_right",2.55],["move_forward",2.85]])
   "the_streets": await walk_steps([["move_forward",1.5],["move_left",5.9]])
   "the_district": await walk_steps([["move_forward",1.5],["move_right",5.9]])
   "the_harbour": await walk_steps([["move_forward",20.6],["move_right",5.9],["move_back",2.0]])
   "ngong_ping": await walk_steps([["move_forward",5.8],["move_left",1.1]])
  Engine.time_scale = 1.0
  print("HK DEPLOYMENT DIAG: ", id, " player=", player.global_position, " target=", target.global_position)
  check(player.global_position.distance_to(target.global_position) < 2.5, id + " has a physical route from deployment to its target")
  target.collision_layer = 1
  guard.collision_layer = 1
  if id == "tung_chung":
   player.global_position = Vector3(14.5,0.05,4.0)
   player.rotation.y = 0.0
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_forward")
   await create_timer(4.6).timeout
   Input.action_release("move_forward")
   Engine.time_scale = 1.0
   print("HK STAIR DIAG: ", player.global_position)
   check(player.global_position.y > 3.0 and player.global_position.z < -3.8, "station stairs connect the concourse to the upper landing")
  if id == "ngong_ping":
   target.collision_layer = 0
   guard.collision_layer = 0
   player.global_position = Vector3(0,0.05,-14)
   player.rotation.y = 0.0
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_forward")
   await create_timer(4.0).timeout
   Input.action_release("move_forward")
   Engine.time_scale = 1.0
   print("HK BUDDHA DIAG: ", player.global_position)
   check(player.global_position.y > 2.2 and player.global_position.z < -20.0, "public Buddha viewing approach reaches the terrace")
   target.collision_layer = 1
   guard.collision_layer = 1
   check((world.get("scene") as Node).find_child("MountainFieldOffice", true, false) != null, "final mission has a field office separate from the monument")
   target.collision_layer = 0
   guard.collision_layer = 0
   player.global_position = Vector3(5,0.05,5)
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_right")
   await create_timer(2.0).timeout
   Input.action_release("move_right")
   Engine.time_scale = 1.0
   print("HK FIELD DIAG: ", player.global_position)
   check(player.global_position.x > 7.5 and player.global_position.x < 11.5, "mountain field office has a traversable entrance")
   target.collision_layer = 1
   guard.collision_layer = 1
  if id in ["the_streets", "the_district", "the_harbour"]:
   var city: Node = world.get("scene")
   check(city.find_child("InteriorLocalNavigation", true, false) != null, id + " has a walk-in mission interior")
   var furnishings := city.find_child("CityInteriorFurniture", true, false)
   check(furnishings != null and furnishings.get_child_count() >= 4, id + " interior includes attributed furniture and work surfaces")
   target.collision_layer = 0
   guard.collision_layer = 0
   player.rotation.y = 0.0
   player.velocity = Vector3.ZERO
   player.global_position = Vector3(-10,0.05,16) if id == "the_streets" else (Vector3(10,0.05,16) if id == "the_district" else Vector3(16,0.05,-37))
   await physics_frame
   Engine.time_scale = 3.0
   var action := "move_left" if id == "the_streets" else ("move_right" if id == "the_district" else "move_back")
   Input.action_press(action)
   await create_timer(2.8).timeout
   Input.action_release(action)
   Engine.time_scale = 1.0
   print("HK INTERIOR DIAG: ", id, " ", player.global_position)
   var entered: bool = player.global_position.x < -14.0 if id == "the_streets" else (player.global_position.x > 14.0 if id == "the_district" else player.global_position.z > -33.0)
   check(entered, id + " entrance is physically traversable")
   Engine.time_scale = 3.0
   Input.action_press(action)
   await create_timer(2.8).timeout
   Input.action_release(action)
   Engine.time_scale = 1.0
   print("HK BACK ROUTE DIAG: ", id, " ", player.global_position)
   var exited: bool = player.global_position.x < -22.5 if id == "the_streets" else (player.global_position.x > 22.5 if id == "the_district" else player.global_position.z > -25.0)
   check(exited, id + " interior connects to a second physical exit")
   var annex: Node3D = city.find_child("MissionNeighbourhood", true, false)
   check(annex != null and annex.find_child("NeighbourhoodStreetNavigation", true, false) != null, id + " has a connected mission-specific neighbourhood")
   player.global_position = annex.to_global(Vector3(0,0.05,-3))
   player.rotation.y = annex.global_rotation.y
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_back")
   await create_timer(5.0).timeout
   Input.action_release("move_back")
   Engine.time_scale = 1.0
   print("HK ANNEX GATE DIAG: ", id, " ", annex.to_local(player.global_position))
   check(annex.to_local(player.global_position).z > 7.0, id + " gateway is physically traversable from the original city")
   player.global_position = annex.to_global(Vector3(0,0.05,37))
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_back")
   await create_timer(5.0).timeout
   Input.action_release("move_back")
   Engine.time_scale = 1.0
   print("HK ANNEX RAMP DIAG: ", id, " ", annex.to_local(player.global_position))
   check(annex.to_local(player.global_position).y > 2.7 and annex.to_local(player.global_position).z > 48.0, id + " elevated lookout is reachable via the physical ramp")
   player.global_position = annex.to_global(Vector3(-17,0.05,2.5))
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_back")
   await create_timer(5.5).timeout
   Input.action_release("move_back")
   Engine.time_scale = 1.0
   print("HK UPPER OFFICE DIAG: ", id, " ", annex.to_local(player.global_position))
   check(annex.to_local(player.global_position).y > 3.7 and annex.to_local(player.global_position).z > 13.0, id + " upper service room is reached by a physical ramp")
   var uniform: Node3D = world.get("uniform_marker")
   await move_near(world, uniform.global_position)
   world.call("_interact")
   check(world.get("uniform_found") and player.role == "staff", id + " optional upper-floor disguise grants staff access")
   world.call("save_game")
   player.set_disguise("visitor")
   world.set("uniform_found", false)
   world.call("load_game")
   check(world.get("uniform_found") and player.role == "staff", id + " disguise and access survive checkpoint restore")
   target.collision_layer = 1
   guard.collision_layer = 1
  var witness_npc: HotelNpc = world.get("witness")
  await move_near(world, witness_npc.global_position)
  world.call("_interact")
  check(world.get("witness_found") and not world.get("key_secured"), id + " witness gives a physical optional clue without granting the key")
  var intel: Node3D = world.get("intel_marker")
  await move_near(world, intel.global_position)
  world.call("_interact")
  check(world.get("intel_found") and not world.get("key_secured"), id + " optional intel is physically collected without granting a key")
  world.call("save_game")
  world.set("intel_found", false)
  world.set("witness_found", false)
  world.call("load_game")
  check(world.get("intel_found") and world.get("witness_found"), id + " optional intel and witness survive checkpoint restore")
  await move_near(world, (world.get("exit_marker") as Node3D).global_position)
  world.call("_interact")
  check(not service.progress.completed.has(id) and not world.get("key_secured"), id + " extraction rejects missing target and key")
  await move_near(world, target.global_position)
  world.call("_interact")
  check(world.get("target_complete") and not world.get("key_secured") and not service.progress.recovered_keys.has(key_id), id + " target completion does not grant key")
  var config: Dictionary = world.get("config")
  if config["placement"] == "target": await move_near(world, target.global_position)
  elif config["placement"] == "guard": await move_near(world, guard.global_position)
  else: await move_near(world, (world.get("key_marker") as Node3D).global_position)
  world.call("_interact")
  check(world.get("key_secured") and service.progress.recovered_keys.has(key_id), id + " requires a separate physical key interaction")
  if id == "tung_chung":
   await move_near(world, (world.get("exit_marker") as Node3D).global_position)
   world.call("_interact")
   check(world.get("train_stage") == "aboard" and not world.get("train_contact_complete"), "station objectives transition to a distinct train carriage")
   await move_near(world, (world.get("train_contact") as HotelNpc).global_position)
   world.call("_interact")
   check(world.get("train_contact_complete"), "train contact must be physically questioned")
  world.call("save_game")
  world.set("target_complete", false)
  world.set("key_secured", false)
  world.call("load_game")
  check(world.get("target_complete") and world.get("key_secured"), id + " isolated checkpoint restores target and key")
  if id == "tung_chung": check(world.get("train_stage") == "aboard" and world.get("train_contact_complete"), "train stage survives checkpoint load")
  var test_path: String = world.get("save_path")
  var valid_save := SaveStore.read(test_path)
  var wrong_key := valid_save.duplicate(true)
  wrong_key["key_id"] = "key_99"
  SaveStore.write(test_path, wrong_key)
  world.call("load_game")
  check(not world.get("key_secured"), id + " rejects another key in its checkpoint")
  SaveStore.write(test_path, valid_save)
  world.call("load_game")
  var wrong_mission := valid_save.duplicate(true)
  wrong_mission["mission_id"] = "meridian"
  wrong_mission["target_complete"] = false
  SaveStore.write(test_path, wrong_mission)
  world.call("load_game")
  check(world.get("target_complete") and world.get("key_secured"), id + " ignores a different mission's checkpoint")
  if id == "tung_chung":
   # Reproduce the reported flow, including the actual final interaction;
   # never bypass the world by calling Campaign.complete as the only proof.
   check(world.get("witness_found") and world.get("target_complete") and world.get("key_secured") and world.get("train_contact_complete"), "station witness, confrontation, physical key and train contact survive reload")
   check((world.get("train_contact") as HotelNpc).collision_layer == 0, "completed contact no longer blocks the carriage aisle")
   await move_near(world, (world.get("exit_marker") as Node3D).global_position)
   world.call("_interact")
   check(world.get("extraction_active") and service.progress.completed.has(id), "Tung Chung actually completes through its extraction interaction")
   world.call("_finish_extraction")
   await process_frame
   await process_frame
   check(current_scene != null and current_scene.scene_file_path == "res://scenes/ending.tscn", "Tung Chung extraction opens its debrief")
   if current_scene:
    current_scene.queue_free()
    current_scene = null
   await process_frame
  if id == "ngong_ping":
   await move_near(world, (world.get("exit_marker") as Node3D).global_position)
   world.call("_interact")
   check(world.get("extraction_active") and service.progress.completed.has(id) and not player.is_physics_processing(), "final physical extraction saves progression and starts a controlled cinematic")
   var extraction_skip := InputEventAction.new()
   extraction_skip.action = "release_mouse"
   extraction_skip.pressed = true
   await process_frame
   root.push_input(extraction_skip)
   await process_frame
   await process_frame
   print("HK EXTRACTION DIAG: active=", world.get("extraction_active"), " paused=", paused, " scene=", current_scene.scene_file_path if current_scene else "none")
   check(service.progress.completed.has(id), "skipping extraction preserves final operation completion")
   check(current_scene != null and current_scene.scene_file_path == "res://scenes/usb_decryption.tscn" and not service.progress.usb_decryption_seen, "five keys trigger the secure-channel story event")
   if current_scene and current_scene.scene_file_path == "res://scenes/usb_decryption.tscn":
    current_scene.call("_finish")
    await process_frame
    await process_frame
    check(service.progress.usb_decryption_seen and current_scene.scene_file_path == "res://scenes/ending.tscn", "skipping the story event persists it and opens the debrief")
   else: check(false, "skipping the story event persists it and opens the debrief")
  check(service.complete(id, 0), id + " completes after target/key and saves progression")
  if i < 4: check(service.progress.is_unlocked(ids[i+1]), id + " unlocks next operation")
  world.queue_free()
  await process_frame
 check(intro_paths.size() == 5, "five operations use distinct entry camera paths")
 check(service.progress.usb_ready() and service.progress.recovered_keys.size() == 5, "all five distinct keys unlock USB decryption")
 var snapshot: Dictionary = service.progress.snapshot()
 var restored := CampaignProgress.new()
 restored.configure(JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign.json")))
 restored.restore(snapshot)
 check(restored.usb_ready() and restored.completed.has("ngong_ping") and restored.usb_decryption_seen, "all keys, final completion and decryption event survive campaign restore")
 var paths: Array[String] = []
 for id: String in ids: paths.append(service.checkpoint_path(id))
 var unique_paths: Dictionary = {}
 for path: String in paths: unique_paths[path] = true
 check(unique_paths.size() == 5 and not paths.has(service.checkpoint_path("meridian")) and not paths.has(service.checkpoint_path("initiation")), "Hong Kong checkpoints do not overwrite legacy missions")
 service.campaign_path = old_path
 service.active_mission = old_active
 service.progress.restore(old_progress)
 for id: String in ids:
  for suffix: String in ["", ".bak", ".tmp"]:
   var path := temp + "_" + id + ".json" + suffix
   if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 for suffix: String in ["", ".bak", ".tmp"]:
  var path := temp + "_campaign.json" + suffix
  if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 print("HK RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
