extends SceneTree
## Scripted virtual-display captures, not a human playthrough or art signoff.
var failures := 0
var checks := 0
var output := ""
func _initialize() -> void:
 call_deferred("run")
func check(condition: bool, text: String) -> void:
 checks += 1
 if condition: print("HKVIS PASS: ", text)
 else:
  failures += 1
  printerr("HKVIS FAIL: ", text)
func capture(name: String) -> void:
 for frame: int in range(4): await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 image.save_png(output.path_join(name + ".png"))
 var thumb := image.duplicate() as Image
 thumb.resize(320,180)
 thumb.save_jpg(output.path_join(name + "_thumb.jpg"), 0.48)
# Short fixed-view software-renderer samples, not target-device benchmarks.
func sample_quality(service: Node, location: String, quality: String) -> void:
 service.settings["graphics"] = quality
 service.apply_settings()
 for frame: int in range(10): await process_frame
 var samples: Array[float] = []
 var previous := Time.get_ticks_usec()
 for frame: int in range(30):
  await process_frame
  var now := Time.get_ticks_usec()
  samples.append(float(now-previous)/1000.0)
  previous = now
 samples.sort()
 var total := 0.0
 for value: float in samples: total += value
 var mean := total/float(samples.size())
 print("HKPERF: %s %s frames=30 mean_ms=%.3f p95_ms=%.3f fps=%.2f" % [location,quality,mean,samples[28],1000.0/maxf(mean,0.001)])

func run() -> void:
 output = OS.get_environment("TEST_SCREENSHOT_DIR")
 if output.is_empty(): output = "user://captures"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 root.size = Vector2i(1280,720)
 var service := root.get_node("Campaign")
 var old_settings: Dictionary = service.settings.duplicate(true)
 var ids := ["tung_chung", "the_streets", "the_district", "the_harbour", "ngong_ping"]
 for id: String in ids:
  var world: Node3D = load("res://scenes/mission_" + id + ".tscn").instantiate()
  root.add_child(world)
  await process_frame
  await physics_frame
  var intro: Camera3D = world.get("intro_camera")
  check(intro.current and world.get("intro_active"), id + " entry camera is active")
  if id != "ngong_ping": check(world.get("has_establishing"), id + " opens on the location before cutting to the target")
  check(root.get_visible_rect().encloses((world.get("skip_button") as Button).get_global_rect()), id + " skip button fits at 720p")
  await capture("hk_intro_" + id)
  world.call("_end_intro")
  var player: HotelPlayer = world.get("player")
  check(player.camera.current and player.is_physics_processing(), id + " gameplay camera resumes")
  check(root.get_visible_rect().encloses((world.get("hud") as Control).get_global_rect()), id + " objective HUD fits at 720p")
  if id == "tung_chung":
   var target: HotelNpc = world.get("target")
   var people: Array[HotelNpc] = world.get("npc_list")
   for npc: HotelNpc in people:
    npc.set_physics_process(false)
    if npc != target: npc.collision_layer = 0
   player.global_position = target.global_position + Vector3(0,0,4)
   player.rotation.y = 0.0
   player.velocity = Vector3.ZERO
   player.aiming = true
   player.equipment.selected = "training_sidearm"
   player.equipment.charges = 5
   for frame: int in range(3): await physics_frame
   player.camera.look_at(target.global_position + Vector3.UP,Vector3.UP)
   world.call("_fire")
   check(world.get("target_complete") and not world.get("key_secured") and player.equipment.charges == 4, "Hong Kong center-ray shot completes the target but does not collect its key")
   check(float((world.get("reticle") as Control).get("hit_timer")) > 0.0, "Hong Kong shot displays hit confirmation")
   player.aiming = false
   world.call("_finish_story")
  # A staged interior/landmark view, not an end-to-end human route.
  var shot := Camera3D.new()
  world.add_child(shot)
  var focus: Vector3 = (world.get("target") as HotelNpc).global_position + Vector3.UP
  if id == "ngong_ping":
   shot.global_position = Vector3(0,8,8)
   shot.look_at(Vector3(0,11,-29),Vector3.UP)
  elif id == "tung_chung":
   world.call("_board_train")
   shot.global_position = Vector3(19,2.1,18)
   shot.look_at(Vector3(19,1.2,34),Vector3.UP)
  else:
   shot.global_position = focus + Vector3(2.0,1.2,2.5)
   shot.look_at(focus,Vector3.UP)
  shot.make_current()
  await capture("hk_play_" + id)
  if id in ["the_streets", "the_district", "the_harbour"]:
   var neighbourhood: Node3D = (world.get("scene") as Node).find_child("MissionNeighbourhood", true, false)
   shot.global_position = neighbourhood.to_global(Vector3(0,6.0,9))
   shot.look_at(neighbourhood.to_global(Vector3(0,2.0,42)),Vector3.UP)
   await capture("hk_neighbourhood_" + id)
  if id in ["tung_chung", "the_district", "ngong_ping"]:
   await sample_quality(service,id,"LOW")
   await sample_quality(service,id,"MEDIUM")
   await sample_quality(service,id,"HIGH")
  world.queue_free()
  await process_frame
 service.settings = old_settings
 service.apply_settings()
 print("HKVIS RESULT: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
