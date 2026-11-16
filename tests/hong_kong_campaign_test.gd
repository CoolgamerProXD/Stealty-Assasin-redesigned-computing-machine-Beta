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
  await move_near(world, target.global_position)
  world.call("_interact")
  check(world.get("target_complete") and not world.get("key_secured") and not service.progress.recovered_keys.has(key_id), id + " target completion does not grant key")
  var config: Dictionary = world.get("config")
  if config["placement"] == "target": await move_near(world, target.global_position)
  elif config["placement"] == "guard": await move_near(world, guard.global_position)
  else: await move_near(world, (world.get("key_marker") as Node3D).global_position)
  world.call("_interact")
  check(world.get("key_secured") and service.progress.recovered_keys.has(key_id), id + " requires a separate physical key interaction")
  world.call("save_game")
  world.set("target_complete", false)
  world.set("key_secured", false)
  world.call("load_game")
  check(world.get("target_complete") and world.get("key_secured"), id + " isolated checkpoint restores target and key")
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
