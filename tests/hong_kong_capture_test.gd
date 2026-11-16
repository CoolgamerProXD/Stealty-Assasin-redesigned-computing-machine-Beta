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
func run() -> void:
 output = OS.get_environment("TEST_SCREENSHOT_DIR")
 if output.is_empty(): output = "user://captures"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 root.size = Vector2i(1280,720)
 var ids := ["tung_chung", "the_streets", "the_district", "the_harbour", "ngong_ping"]
 for id: String in ids:
  var world: Node3D = load("res://scenes/mission_" + id + ".tscn").instantiate()
  root.add_child(world)
  await process_frame
  await physics_frame
  var intro: Camera3D = world.get("intro_camera")
  check(intro.current and world.get("intro_active"), id + " entry camera is active")
  await capture("hk_intro_" + id)
  world.call("_end_intro")
  var player: HotelPlayer = world.get("player")
  check(player.camera.current and player.is_physics_processing(), id + " gameplay camera resumes")
  # A staged interior/landmark view, not an end-to-end human route.
  var shot := Camera3D.new()
  world.add_child(shot)
  var focus: Vector3 = (world.get("target") as HotelNpc).global_position + Vector3.UP
  if id == "ngong_ping":
   shot.global_position = Vector3(0,8,8)
   shot.look_at(Vector3(0,11,-29),Vector3.UP)
  elif id == "tung_chung":
   world.call("_board_train")
   shot.global_position = Vector3(0,2.1,86)
   shot.look_at(Vector3(0,1.2,78),Vector3.UP)
  else:
   shot.global_position = focus + Vector3(2.0,1.2,2.5)
   shot.look_at(focus,Vector3.UP)
  shot.make_current()
  await capture("hk_play_" + id)
  world.queue_free()
  await process_frame
 print("HKVIS RESULT: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
