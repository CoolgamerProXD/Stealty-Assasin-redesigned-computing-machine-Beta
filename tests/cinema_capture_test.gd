extends SceneTree
## Scripted 1280x720 captures, not a human playthrough. Cameras are positioned
## explicitly for repeatable composition; actual gameplay camera also captured.
var output: String
var checks := 0
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, text: String) -> void:
 checks += 1
 if value: print("CINEMA PASS: ", text)
 else:
  failures += 1
  printerr("CINEMA FAIL: ", text)

func capture(name: String) -> void:
 for i: int in range(4): await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 image.save_png(output.path_join(name + ".png"))
 if name in ["cinema_hotel_lobby", "cinema_hotel_corridor", "cinema_initiation", "cinema_weapon_idle", "cinema_weapon_aim", "cinema_tung_chung", "cinema_hotel_wing", "cinema_hotel_upper", "cinema_hotel_intel", "cinema_city", "cinema_ngong_ping", "cinema_hotel_footprint"]:
  var thumb := image.duplicate() as Image
  thumb.resize(320, 180)
  thumb.save_jpg(output.path_join(name + "_thumb.jpg"), 0.50)

func sample_preset(service: Node, quality: String) -> void:
 service.settings["graphics"] = quality
 service.apply_settings()
 for i: int in range(15): await process_frame
 var intervals: Array[float] = []
 var previous := Time.get_ticks_usec()
 for i: int in range(60):
  await process_frame
  var now := Time.get_ticks_usec()
  intervals.append(float(now - previous) / 1000.0)
  previous = now
 var total := 0.0
 for value: float in intervals: total += value
 intervals.sort()
 var mean := total / intervals.size()
 print("PRESET_METRIC: %s frames=%d mean_ms=%.3f p95_ms=%.3f fps=%.2f" % [quality, intervals.size(), mean, intervals[56], 1000.0 / maxf(mean, 0.001)])

func shot_camera(world: Node3D, pos: Vector3, target: Vector3) -> Camera3D:
 var camera := Camera3D.new()
 world.add_child(camera)
 camera.global_position = pos
 camera.look_at(target, Vector3.UP)
 camera.fov = 65
 camera.make_current()
 return camera

func run() -> void:
 output = ProjectSettings.globalize_path("res://visual-test-output")
 DirAccess.make_dir_recursive_absolute(output)
 var service: Node = root.get_node("Campaign")
 var saved: Dictionary = service.settings.duplicate(true)
 service.settings["graphics"] = "HIGH"
 service.apply_settings()
 var hotel: Node3D = load("res://scenes/hotel.tscn").instantiate()
 root.add_child(hotel)
 for i: int in range(10): await physics_frame
 var camera := shot_camera(hotel, Vector3(-9.8, 2.1, 5.5), Vector3(-5.1, 1.1, -4.6))
 await capture("cinema_hotel_lobby")
 camera.global_position = Vector3(4.5, 1.8, 4.4)
 camera.look_at(Vector3(4.5, 1.2, -6.0), Vector3.UP)
 await capture("cinema_hotel_corridor")
 for quality: String in ["LOW", "MEDIUM", "HIGH"]:
  await sample_preset(service, quality)
 camera.global_position = Vector3(-16, 2.0, -3)
 camera.look_at(Vector3(-31,1.1,-10),Vector3.UP)
 await capture("cinema_hotel_wing")
 camera.global_position = Vector3(-39.5,5.2,-6.8)
 camera.look_at(Vector3(-38,4.6,-9),Vector3.UP)
 await capture("cinema_hotel_upper")
 # Remove only the decorative ceiling for an overhead upper-floor plan view.
 var hidden_roofs: Array[Node3D] = []
 for child: Node in hotel.get_children():
  if child is Node3D and is_equal_approx(child.position.y, 7.1):
   child.visible = false
   hidden_roofs.append(child)
 camera.global_position = Vector3(-15, 55, 0)
 camera.look_at(Vector3(-15,3.6,0),Vector3.FORWARD)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 72
 await capture("cinema_hotel_footprint")
 camera.projection = Camera3D.PROJECTION_PERSPECTIVE
 for roof: Node3D in hidden_roofs: roof.visible = true
 camera.global_position = Vector3(-5,1.4,-2.2)
 camera.look_at(Vector3(-5,0.8,-3.6),Vector3.UP)
 await capture("cinema_hotel_intel")
 var target: HotelNpc = hotel.get("primary_npc")
 camera.global_position = target.global_position + Vector3(2.4, 1.7, 2.4)
 camera.look_at(target.global_position + Vector3.UP * 1.0, Vector3.UP)
 await capture("cinema_adrian_locke")
 check(target.profile.identity == "Adrian Locke" and target.person.is_visible_in_tree(), "physical scheduled primary visible in hotel")
 var npc: HotelNpc = hotel.get("npcs")[0]
 var before := npc.global_position
 camera.global_position = npc.global_position + Vector3(2.8, 1.8, 2.8)
 camera.look_at(npc.global_position + Vector3.UP, Vector3.UP)
 await capture("cinema_npc_motion_before")
 await create_timer(1.5).timeout
 await capture("cinema_npc_motion_after")
 # Existing headless suite asserts actual schedule motion; these two images
 # document the scripted scene and are not a motion-quality judgment.
 print("CINEMA_METRIC: NPC displacement=", npc.global_position.distance_to(before))
 var player: HotelPlayer = hotel.get("player")
 player.global_position = Vector3(-9, 0.05, 1.5)
 player.rotation.y = 0
 player.pivot.rotation.x = -0.22
 player.camera.make_current()
 for i: int in range(20): await physics_frame
 await capture("cinema_weapon_idle")
 var aim := InputEventMouseButton.new()
 aim.button_index = MOUSE_BUTTON_RIGHT
 aim.pressed = true
 Input.parse_input_event(aim)
 for i: int in range(30): await physics_frame
 await capture("cinema_weapon_aim")
 check(player.aiming and player.body_mesh.weapon_aim_blend > 0.8 and player.camera.fov < 62, "aim transitions weapon and FOV in gameplay camera")
 aim.pressed = false
 Input.parse_input_event(aim.duplicate())
 for i: int in range(30): await physics_frame
 check(not player.aiming and player.body_mesh.weapon_aim_blend < 0.2 and player.camera.fov > 65, "aim release restores exploration pose and FOV")
 hotel.queue_free()
 await process_frame
 var initiation: Node3D = load("res://scenes/initiation.tscn").instantiate()
 root.add_child(initiation)
 for i: int in range(10): await physics_frame
 var init_cam := shot_camera(initiation, Vector3(-12.5, 2.1, 6.0), Vector3(-6.0, 1.0, -4.5))
 await capture("cinema_initiation")
 check(init_cam.current and initiation.get("npcs").size() == 2, "Initiation camera renders scene with exactly two guards")
 initiation.queue_free()
 await process_frame
 var station: Node3D = load("res://scenes/tung_chung_preview.tscn").instantiate()
 root.add_child(station)
 for i: int in range(10): await physics_frame
 var station_cam := shot_camera(station, Vector3(-18, 3.0, 7.0), Vector3(0, 1.6, -4.0))
 await capture("cinema_tung_chung")
 check(station_cam.current and station.get("npcs").size() == 16, "station preview renders with scheduled physical population")
 for quality: String in ["LOW", "MEDIUM", "HIGH"]:
  print("STATION_SAMPLE: ", quality)
  await sample_preset(service, quality)
 station.queue_free()
 await process_frame
 for preview_name: String in ["hong_kong", "ngong_ping"]:
  var scenery: Node3D = load("res://scenes/" + preview_name + "_preview.tscn").instantiate()
  root.add_child(scenery)
  for i: int in range(5): await physics_frame
  var scenery_cam := shot_camera(scenery, Vector3(0,4.0,24) if preview_name == "hong_kong" else Vector3(0,5.0,-11), Vector3(0,2.5,-20) if preview_name == "hong_kong" else Vector3(0,3.0,-29))
  await capture("cinema_city" if preview_name == "hong_kong" else "cinema_ngong_ping")
  check(scenery_cam.current and scenery.get("player") != null, preview_name + " preview renders with player")
  scenery.queue_free()
  await process_frame
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 await process_frame
 menu.call("_settings")
 await capture("cinema_graphics_settings")
 check(menu.get("panel").get_child_count() > 0, "settings panel opens from main menu")
 menu.queue_free()
 await process_frame
 var old_ending: Dictionary = service.ending.duplicate(true)
 service.ending = {"name": "02  /  THE MERIDIAN", "records": 2, "debrief": "Ruby: The archive trail continues."}
 var ending: Control = load("res://scenes/ending.tscn").instantiate()
 root.add_child(ending)
 await create_timer(1.6).timeout
 await capture("cinema_staged_debrief")
 check(ending.get("debrief").modulate.a > 0.9, "debrief appears after its transition")
 ending.queue_free()
 service.ending = old_ending
 service.settings = saved
 service.apply_settings()
 await process_frame
 print("CINEMA RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
