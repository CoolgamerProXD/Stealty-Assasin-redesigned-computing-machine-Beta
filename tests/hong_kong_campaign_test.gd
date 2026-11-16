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
func run() -> void:
 var service := root.get_node("Campaign")
 var old_path: String = service.campaign_path
 var old_active: String = service.active_mission
 var old_progress: Dictionary = service.progress.snapshot()
 var temp := "user://assassin_hk_test_%d" % Time.get_ticks_usec()
 service.campaign_path = temp + "_campaign.json"
 service.progress.restore({})
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
 check(service.progress.mark_complete("initiation"), "Initiation unlocks Hong Kong without mandatory Meridian")
 var ids := ["tung_chung", "the_streets", "the_district", "the_harbour", "ngong_ping"]
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
  world.call("_end_intro")
  check(not world.get("intro_active") and player.is_physics_processing(), id + " skip initializes gameplay")
  if id == "tung_chung":
   player.global_position = Vector3(14.5,0.05,2.0)
   player.rotation.y = 0.0
   player.velocity = Vector3.ZERO
   await physics_frame
   Engine.time_scale = 3.0
   Input.action_press("move_forward")
   await create_timer(2.8).timeout
   Input.action_release("move_forward")
   Engine.time_scale = 1.0
   print("HK STAIR DIAG: ", player.global_position)
   check(player.global_position.y > 3.0 and player.global_position.z < -3.8, "station stairs connect the concourse to the upper landing")
  if id in ["the_streets", "the_district", "the_harbour"]:
   var city: Node = world.get("scene")
   check(city.find_child("InteriorLocalNavigation", true, false) != null, id + " has a walk-in mission interior")
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
   target.collision_layer = 1
   guard.collision_layer = 1
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
  if id == "ngong_ping":
   await move_near(world, (world.get("exit_marker") as Node3D).global_position)
   world.call("_interact")
   await process_frame
   check(service.progress.completed.has(id), "final physical extraction completes the operation")
  check(service.complete(id, 0), id + " completes after target/key and saves progression")
  if i < 4: check(service.progress.is_unlocked(ids[i+1]), id + " unlocks next operation")
  world.queue_free()
  await process_frame
 check(service.progress.usb_ready() and service.progress.recovered_keys.size() == 5, "all five distinct keys unlock USB decryption")
 var snapshot: Dictionary = service.progress.snapshot()
 var restored := CampaignProgress.new()
 restored.configure(JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign.json")))
 restored.restore(snapshot)
 check(restored.usb_ready() and restored.completed.has("ngong_ping"), "all keys and mission completion survive campaign restore")
 var paths: Array[String] = []
 for id: String in ids: paths.append(service.checkpoint_path(id))
 check(paths.size() == 5 and not paths.has(service.checkpoint_path("meridian")) and not paths.has(service.checkpoint_path("initiation")), "Hong Kong checkpoints do not overwrite legacy missions")
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
