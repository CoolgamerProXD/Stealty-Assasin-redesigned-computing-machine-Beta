extends SceneTree
## Automated virtual-display test. This does not simulate an interactive playtest.
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, description: String) -> void:
 checks += 1
 if condition:
  print("CAMERA PASS: ", description)
 else:
  failures += 1
  printerr("CAMERA FAIL: ", description)

func run() -> void:
 var screenshot_dir := OS.get_environment("TEST_SCREENSHOT_DIR")
 if screenshot_dir.is_empty(): screenshot_dir = ProjectSettings.globalize_path("res://visual-test-output")
 DirAccess.make_dir_recursive_absolute(screenshot_dir)
 var scene: PackedScene = load("res://scenes/hotel.tscn")
 var world: Node = scene.instantiate()
 root.add_child(world)
 await process_frame
 print("DISPLAY_STARTUP: engine clock to first process frame = %.3f ms" % (float(Time.get_ticks_usec()) / 1000.0))
 await physics_frame
 var player: HotelPlayer = world.get("player")
 check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse captured at startup")
 var yaw := player.rotation.y
 var pitch := player.pivot.rotation.x
 var motion := InputEventMouseMotion.new()
 motion.relative = Vector2(100, -50)
 player._unhandled_input(motion)
 check(player.rotation.y < yaw and player.pivot.rotation.x > pitch, "mouse motion rotates yaw and pitch")
 motion.relative = Vector2(0, -10000)
 player._unhandled_input(motion)
 check(is_equal_approx(player.pivot.rotation.x, 0.55), "camera pitch is clamped")
 var release := InputEventAction.new()
 release.action = "release_mouse"
 release.pressed = true
 player._unhandled_input(release)
 check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "release action frees mouse")
 # The wall behind the player must shorten the existing spring arm.
 player.rotation.y = 0.0
 player.pivot.rotation.x = -0.22
 player.global_position = Vector3(-10, 0.05, 7.0)
 player.velocity = Vector3.ZERO
 for i: int in range(12): await physics_frame
 var arm: SpringArm3D = player.pivot.get_child(0)
 check(arm.get_hit_length() < arm.spring_length - 0.2, "camera spring arm detects wall behind player")
 # Sample actual process-frame intervals on this virtual software display.
 for i: int in range(30): await process_frame
 var samples: Array[float] = []
 var previous: int = Time.get_ticks_usec()
 for i: int in range(120):
  await process_frame
  var now: int = Time.get_ticks_usec()
  samples.append(float(now - previous) / 1000.0)
  previous = now
 var total: float = 0.0
 for value: float in samples: total += value
 samples.sort()
 var mean: float = total / samples.size()
 print("DISPLAY_METRIC: frames=%d mean_ms=%.3f p95_ms=%.3f p99_ms=%.3f mean_fps=%.2f" % [samples.size(), mean, samples[113], samples[118], 1000.0 / maxf(mean, 0.001)])
 var hotel_hud: Label = world.get("hud")
 check(hotel_hud.is_visible_in_tree() and hotel_hud.text.contains("ADRIAN LOCKE"), "Meridian target HUD is visible in rendered scene")
 check(player.body_mesh.is_visible_in_tree() and player.body_mesh.get_child_count() > 8, "articulated player visuals are present in rendered scene")
 var target: HotelNpc = world.get("primary_npc")
 var crowd: Array[HotelNpc] = world.get("npcs")
 for person: HotelNpc in crowd:
  person.set_physics_process(false)
  if person != target: person.collision_layer = 0
 target.global_position = Vector3(-9, 0.05, -3)
 player.global_position = Vector3(-9, 0.05, 1.5)
 player.rotation.y = 0.0
 player.pivot.rotation.x = -0.22
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 await physics_frame
 var right := InputEventMouseButton.new()
 right.button_index = MOUSE_BUTTON_RIGHT
 right.pressed = true
 Input.parse_input_event(right)
 for i: int in range(30): await physics_frame
 player.set_physics_process(false)
 player.camera.look_at(target.global_position + Vector3.UP, Vector3.UP)
 await physics_frame
 check(player.aiming and world.get("crosshair").is_visible_in_tree(), "right mouse input shows aiming crosshair on virtual display")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(screenshot_dir.path_join("hotel_aim_gameplay.png"))
 var reticle: Control = world.get("crosshair")
 var view_center := player.camera.get_viewport().get_visible_rect().size * 0.5
 print("CAMERA_DIAG: rect=", reticle.get_global_rect(), " parent_size=", reticle.get_parent().size, " viewport=", view_center, " anchors=", reticle.anchor_left, ",", reticle.anchor_top)
 check(reticle.get_global_rect().get_center().distance_to(view_center) < 1.0, "displayed crosshair is at the viewport center")
 var fire := InputEventMouseButton.new()
 fire.button_index = MOUSE_BUTTON_LEFT
 fire.pressed = true
 Input.parse_input_event(fire)
 await process_frame
 await physics_frame
 await process_frame
 check(target.stunned_time > 0.0 and player.equipment.charges == 4, "center shot hits physical target and consumes charge")
 check(float(reticle.get("hit_timer")) > 0.0, "valid hit displays reticle confirmation")
 check(world.get("mission").target_complete, "shot at Locke completes primary objective")
 check(player.body_mesh.weapon_equipped and player.body_mesh.weapon.visible, "equipped sidearm is attached to player hand")
 var hit_screen := player.camera.unproject_position(world.get("last_shot_end"))
 var center := player.camera.get_viewport().get_visible_rect().size * 0.5
 check(hit_screen.distance_to(center) < 1.0, "shot impact projects to screen-center crosshair")
 fire.pressed = false
 Input.parse_input_event(fire.duplicate())
 target.stunned_time = 0.0
 player.global_position = Vector3(0.5, 0.05, 0)
 target.global_position = Vector3(3.2, 0.05, 0)
 await physics_frame
 player.camera.look_at(target.global_position + Vector3.UP, Vector3.UP)
 await physics_frame
 fire.pressed = true
 Input.parse_input_event(fire.duplicate())
 await process_frame
 await physics_frame
 await process_frame
 check(target.stunned_time == 0.0 and player.equipment.charges == 3, "solid partition blocks center shot before target")
 fire.pressed = false
 Input.parse_input_event(fire.duplicate())
 await process_frame
 # Simulate a shoulder camera clipped to the far side of the partition.
 player.global_position = Vector3(1.65, 0.05, 0)
 target.global_position = Vector3(4.2, 0.05, 0)
 await physics_frame
 player.camera.look_at(target.global_position + Vector3.UP, Vector3.UP)
 fire.pressed = true
 Input.parse_input_event(fire.duplicate())
 await process_frame
 await physics_frame
 await process_frame
 print("CAMERA_DIAG: obstruction player=", player.global_position, " camera=", player.camera.global_position, " charges=", player.equipment.charges, " message=", world.get("message"))
 check(target.stunned_time == 0.0 and player.equipment.charges == 3 and str(world.get("message")).contains("obstructed"), "camera across wall cannot shoot through player obstruction")
 right.pressed = false
 Input.parse_input_event(right.duplicate())
 await process_frame
 await physics_frame
 await process_frame
 check(not player.aiming and not world.get("crosshair").visible, "right mouse release exits aim on virtual display")
 fire.pressed = false
 Input.parse_input_event(fire.duplicate())
 await process_frame
 fire.pressed = true
 Input.parse_input_event(fire.duplicate())
 await process_frame
 await physics_frame
 await process_frame
 check(player.equipment.charges == 3, "left mouse without aiming does not fire")
 world.queue_free()
 await process_frame
 var initiation: Node = load("res://scenes/initiation.tscn").instantiate()
 root.add_child(initiation)
 for i: int in range(10): await process_frame
 check(initiation.get("hud").is_visible_in_tree() and initiation.get("hud").text.contains("ASSESSMENT UNIT"), "Initiation target HUD is visible in rendered scene")
 check(initiation.get("npcs")[0].person.is_visible_in_tree(), "guard visual is present in rendered scene")
 initiation.queue_free()
 await process_frame
 var cinematic: Node = load("res://scenes/ruby_meeting.tscn").instantiate()
 root.add_child(cinematic)
 for i: int in range(10): await process_frame
 check(cinematic.get("camera").is_current() and cinematic.get("ruby").is_visible_in_tree(), "Ruby scene has active camera and visible character")
 check(cinematic.has_node("ExteriorGround") and cinematic.has_node("BackgroundBuilding0") and cinematic.has_node("BackgroundBuilding4"), "cinematic renders exterior ground and surrounding architecture")
 var grounded := true
 for moment: float in [0.0, 3.0, 6.0, 10.0]:
  cinematic.call("_apply_timeline", moment, 0.0)
  if absf(cinematic.get("actor").position.y) > 0.001 or absf(cinematic.get("ruby").position.y) > 0.001: grounded = false
  for figure: StylizedPerson in [cinematic.get("actor"), cinematic.get("ruby")]:
   var shoe := figure.left_leg.get_child(1) as MeshInstance3D
   if shoe.global_position.y - 0.06 < -0.01: grounded = false
 check(grounded, "cinematic actor roots remain on ground plane through timeline")
 cinematic.call("_apply_timeline", 10.0, 0.0)
 check(cinematic.get("subtitles").text.contains("RUBY"), "Ruby subtitles appear on cinematic timeline")
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(screenshot_dir.path_join("ruby_meeting.png"))
 cinematic.queue_free()
 await process_frame
 print("CAMERA RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
