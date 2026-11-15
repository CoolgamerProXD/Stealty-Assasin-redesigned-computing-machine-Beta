extends SceneTree
## Real Compatibility viewport images, automated under Xvfb, not a human playtest.
var failures := 0
var checks := 0
var output := ""

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, text: String) -> void:
 checks += 1
 if value: print("VISUAL PASS: ", text)
 else:
  failures += 1
  printerr("VISUAL FAIL: ", text)

func capture(name: String) -> Image:
 for i: int in range(4): await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 image.save_png(output.path_join(name + ".png"))
 if name in ["hotel_wall_on", "initiation_wall_on", "hotel_preset_high"]:
  var thumb := image.duplicate() as Image
  thumb.resize(320, 180)
  thumb.save_jpg(output.path_join(name + "_thumb.jpg"), 0.55)
 return image

func red_stats(image: Image) -> Vector2:
 var count := 0
 var sum := 0.0
 for y: int in range(int(image.get_height() * 0.25), int(image.get_height() * 0.85), 2):
  for x: int in range(int(image.get_width() * 0.25), int(image.get_width() * 0.75), 2):
   var c := image.get_pixel(x, y)
   if c.r > 0.55 and c.g < 0.35 and c.b < 0.35 and c.r > c.g * 2.0:
    count += 1
    sum += x
 return Vector2(count, sum / maxf(count, 1))

func run() -> void:
 output = OS.get_environment("TEST_SCREENSHOT_DIR")
 if output.is_empty(): output = ProjectSettings.globalize_path("res://visual-test-output")
 DirAccess.make_dir_recursive_absolute(output)
 for id: String in ["initiation", "hotel"]:
  var world: Node3D = load("res://scenes/" + id + ".tscn").instantiate()
  root.add_child(world)
  for i: int in range(8): await physics_frame
  var player: HotelPlayer = world.get("player")
  var target: Node3D = world.get("robot") if id == "initiation" else world.get("primary_npc")
  for npc: HotelNpc in world.get("npcs"):
   npc.set_physics_process(false)
  world.set_physics_process(false)
  player.set_physics_process(false)
  player.global_position = Vector3(0.4, 0.05, 0)
  target.global_position = Vector3(4.2, 0.05, 0)
  # The SpringArm owns its camera transform even if the player is paused.
  # Use a fixed camera for reproducible wall-occlusion screenshots.
  var camera := Camera3D.new()
  world.add_child(camera)
  camera.global_position = Vector3(0.5, 1.35, 0)
  camera.look_at(target.global_position + Vector3.UP * 0.9, Vector3.UP)
  camera.make_current()
  player.camera = camera
  await physics_frame
  var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, target.global_position + Vector3.UP * 0.9)
  ray.exclude = [player.get_rid()]
  var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
  print("VISUAL_METRIC: ", id, " camera=", player.camera.global_position, " target=", target.global_position, " hit=", hit)
  check(not hit.is_empty() and hit["position"].x < 2.2, id + " has real solid wall between camera and target")
  var off := await capture(id + "_wall_off")
  var key := InputEventKey.new()
  key.physical_keycode = KEY_CTRL
  key.location = KEY_LOCATION_LEFT
  key.pressed = true
  Input.parse_input_event(key)
  var on := await capture(id + "_wall_on")
  var a := red_stats(off)
  var b := red_stats(on)
  print("VISUAL_METRIC: %s off=%d on=%d centroid=%.1f" % [id, a.x, b.x, b.y])
  check(b.x > a.x + 30, id + " actual target silhouette renders red through the wall")
  target.global_position.z = 0.8
  var moved := await capture(id + "_wall_moved")
  var c := red_stats(moved)
  print("VISUAL_METRIC: %s moved=%d centroid=%.1f" % [id, c.x, c.y])
  check(c.x > a.x + 20 and absf(c.y - b.y) > 10, id + " red silhouette follows target movement")
  target.global_position = Vector3(20, 0.05, 0)
  var distant := await capture(id + "_wall_distant")
  var far_stats := red_stats(distant)
  print("VISUAL_METRIC: %s distant=%d" % [id, far_stats.x])
  check(far_stats.x > a.x + 8, id + " silhouette remains visible beyond the former 16 metre limit")
  target.global_position = Vector3(4.2, 0.05, 0.8)
  key.pressed = false
  Input.parse_input_event(key.duplicate())
  var released := await capture(id + "_wall_released")
  var d := red_stats(released)
  check(d.x < c.x - 20, id + " release clears the through-wall silhouette")
  if id == "hotel":
   # Save actual rendered preset comparisons with the HUD and physical actor.
   camera.global_position = Vector3(-4, 2.2, 4)
   camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
   var service: Node = root.get_node("Campaign")
   var old_settings: Dictionary = service.settings.duplicate(true)
   service.settings["show_fps"] = true
   for quality: String in ["LOW", "MEDIUM", "HIGH"]:
    service.settings["graphics"] = quality
    service.apply_settings()
    var preset_image := await capture("hotel_preset_" + quality.to_lower())
    check(not preset_image.is_empty() and world.get("fps_label").visible and world.get("fps_label").text.contains("FPS"), quality + " renders with FPS counter")
   service.settings = old_settings
   service.apply_settings()
  world.queue_free()
  await process_frame
 print("VISUAL RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
