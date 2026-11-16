extends Node3D
## Early playable operations built on the existing exploration maps. Each
## deployment owns its objective state and checkpoint; the USB belongs to Campaign.
@export var operation_id: String = "tung_chung"
var save_path: String = ""
var config: Dictionary
var scene: Node3D
var player: HotelPlayer
var target: HotelNpc
var guard: HotelNpc
var key_marker: Node3D
var exit_marker: Node3D
var hud: Label
var briefing: Label
var skip_button: Button
var intro_start: Vector3
var intro_end: Vector3
var intro_look_start: Vector3
var intro_look_end: Vector3
var reticle: Control
var intro_camera: Camera3D
var intro_time: float = 0.0
var intro_active: bool = true
var target_complete: bool = false
var key_secured: bool = false
var train_stage: String = "station"
var train_contact: HotelNpc
var train_contact_complete: bool = false
var train_car: Node3D
var train_streaks: Array[Node3D] = []
var message: String = ""
var npc_list: Array[HotelNpc] = []
var red_overlay: StandardMaterial3D
var yellow_overlay: StandardMaterial3D
var shot_audio: AudioStreamPlayer
var gadget_audio: AudioStreamPlayer

func _vec(value: Array) -> Vector3:
 return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _ready() -> void:
 var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/hong_kong_operations.json"))
 if not definitions is Dictionary or not definitions.has(operation_id):
  push_error("Missing Hong Kong operation data: " + operation_id)
  return
 config = definitions[operation_id]
 save_path = Campaign.checkpoint_path(operation_id)
 var map: String = config["map"]
 var path := "res://scenes/tung_chung_preview.tscn" if map == "station" else ("res://scenes/ngong_ping_preview.tscn" if map == "mountain" else "res://scenes/hong_kong_preview.tscn")
 scene = load(path).instantiate()
 scene.set_meta("operation_id", operation_id)
 add_child(scene)
 scene.set_process(false)
 scene.set_process_unhandled_input(false)
 (scene.get("hud") as Label).visible = false
 player = scene.get("player") as HotelPlayer
 player.position = _vec(config["spawn"])
 player.mouse_sensitivity = float(Campaign.settings["sensitivity"])
 if map == "station":
  player.interaction_requested.disconnect(Callable(scene, "_interact"))
  target = scene.get("robber") as HotelNpc
  guard = scene.get("operative") as HotelNpc
  target.profile.identity = str(config["target"])
  guard.profile.identity = "Courier's bodyguard"
 else:
  var t := _vec(config["target_pos"])
  var g := _vec(config["guard_pos"])
  target = scene.call("_target", str(config["target"]), "manager", t, t + Vector3(0,0,1.8)) as HotelNpc
  guard = scene.call("_target", "Bodyguard", "security", g, g + Vector3(0,0,1.8)) as HotelNpc
 npc_list = scene.get("npcs")
 var restricted_center := _vec(config["target_pos"])
 scene.set_meta("restricted_rect", Rect2(restricted_center.x-3.0, restricted_center.z-3.0, 6.0, 6.0))
 for npc: HotelNpc in npc_list:
  npc.player = player
  npc.trespass_notice.connect(_on_trespass_notice)
 player.equipment.configure(Campaign.progress, operation_id)
 player.interaction_requested.connect(_interact)
 player.equipment_selected.connect(_select_equipment)
 player.equipment_use_requested.connect(_use_equipment)
 player.fire_requested.connect(_fire)
 _build_markers()
 _build_ui()
 if Campaign.load_checkpoint and Campaign.active_mission == operation_id:
  load_game()
  Campaign.load_checkpoint = false
 _begin_intro()

func _build_markers() -> void:
 var placement := str(config["placement"])
 key_marker = Node3D.new()
 key_marker.name = "MissionKeyLocation"
 if placement == "target":
  target.add_child(key_marker)
  key_marker.position = Vector3(0,1.1,0)
 elif placement == "guard":
  guard.add_child(key_marker)
  key_marker.position = Vector3(0,1.1,0)
 else:
  key_marker.position = _vec(config["safe_pos"])
  add_child(key_marker)
  _part(key_marker, Vector3(0,0.55,0), Vector3(0.8,1.1,0.7), Color(0.25,0.29,0.30))
  _part(key_marker, Vector3(0,0.7,-0.36), Vector3(0.35,0.3,0.05), Color(0.72,0.58,0.30))
 # Gold light-shaped marker is a fictional USB, not an automatic pickup.
 _part(key_marker, Vector3(0,0.9 if placement == "safe" else 0.15,0), Vector3(0.12,0.08,0.28), Color(0.90,0.68,0.23))
 exit_marker = Node3D.new()
 exit_marker.name = "Extraction"
 exit_marker.position = _vec(config["exit"])
 add_child(exit_marker)
 _part(exit_marker, Vector3(0,0.04,0), Vector3(1.7,0.06,1.7), Color(0.28,0.65,0.62))
 var exit_label := Label3D.new()
 exit_label.text = "EXTRACTION"
 exit_label.position = Vector3(0,1.5,0)
 exit_label.font_size = 30
 exit_label.pixel_size = 0.004
 exit_marker.add_child(exit_label)

func _part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
 var part := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 part.mesh = mesh
 part.position = pos
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.7
 part.material_override = mat
 parent.add_child(part)

func _build_ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 hud = Label.new()
 hud.position = Vector2(24,20)
 hud.add_theme_font_size_override("font_size", 18)
 hud.add_theme_color_override("font_shadow_color", Color.BLACK)
 hud.add_theme_constant_override("shadow_offset_x", 2)
 hud.add_theme_constant_override("shadow_offset_y", 2)
 canvas.add_child(hud)
 briefing = Label.new()
 briefing.position = Vector2(110,545)
 briefing.size = Vector2(1060,150)
 briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 briefing.add_theme_font_size_override("font_size", 22)
 briefing.add_theme_color_override("font_shadow_color", Color.BLACK)
 briefing.add_theme_constant_override("shadow_offset_x", 2)
 briefing.add_theme_constant_override("shadow_offset_y", 2)
 canvas.add_child(briefing)
 skip_button = Button.new()
 skip_button.text = "SKIP  /  ESC"
 skip_button.position = Vector2(1050,660)
 skip_button.size = Vector2(180,42)
 skip_button.pressed.connect(_end_intro)
 canvas.add_child(skip_button)
 reticle = preload("res://scripts/ui/aim_reticle.gd").new()
 reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(reticle)
 red_overlay = StandardMaterial3D.new()
 red_overlay.albedo_color = Color(1,0.08,0.05,0.85)
 red_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 red_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 red_overlay.no_depth_test = true
 yellow_overlay = StandardMaterial3D.new()
 yellow_overlay.albedo_color = Color(1.0,0.82,0.05,0.8)
 yellow_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 yellow_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 shot_audio = AudioStreamPlayer.new()
 shot_audio.stream = ProceduralSound.tone(180.0,0.12,0.14)
 add_child(shot_audio)
 gadget_audio = AudioStreamPlayer.new()
 gadget_audio.stream = ProceduralSound.tone(260.0,0.12,0.035)
 add_child(gadget_audio)

func _begin_intro() -> void:
 player.set_physics_process(false)
 player.set_process_unhandled_input(false)
 intro_camera = Camera3D.new()
 add_child(intro_camera)
 var at := target.global_position
 intro_look_start = at + Vector3.UP
 intro_look_end = intro_look_start
 match operation_id:
  "tung_chung":
   intro_start = at + Vector3(-6,3.3,5)
   intro_end = at + Vector3(-2,2.0,3)
  "the_streets":
   intro_start = at + Vector3(1.5,2.6,3.2)
   intro_end = at + Vector3(-1.4,1.8,2.0)
  "the_district":
   intro_start = at + Vector3(-1.5,2.8,-3.1)
   intro_end = at + Vector3(1.3,2.0,2.2)
  "the_harbour":
   intro_start = at + Vector3(1.6,2.6,-3)
   intro_end = at + Vector3(-1.4,1.8,2)
  "ngong_ping":
   intro_start = Vector3(0,10,9)
   intro_end = at + Vector3(3,3,5)
   intro_look_start = Vector3(0,12,-29)
  _:
   intro_start = at + Vector3(-5,4,7)
   intro_end = at + Vector3(4,2.5,4)
 intro_camera.global_position = intro_start
 intro_camera.look_at(intro_look_start, Vector3.UP)
 intro_camera.make_current()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 briefing.text = str(Campaign.progress.mission(operation_id).get("briefing", "")) + "\n\nESC  /  SKIP BRIEFING"

func _end_intro() -> void:
 if not intro_active: return
 intro_active = false
 briefing.visible = false
 skip_button.visible = false
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 player.set_physics_process(true)
 player.set_process_unhandled_input(true)
 player.camera.make_current()
 intro_camera.queue_free()
 var pause := preload("res://scripts/ui/pause_menu.gd").new()
 pause.world = self
 add_child(pause)
 message = str(config["clue"])

func _input(event: InputEvent) -> void:
 if intro_active and event.is_action_pressed("release_mouse"):
  _end_intro()
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if intro_active: return
 if event.is_action_pressed("save_game"): save_game()
 elif event.is_action_pressed("load_game"): load_game()

func _process(delta: float) -> void:
 if player == null: return
 if intro_active:
  intro_time += delta
  var t := minf(intro_time / 6.0, 1.0)
  intro_camera.global_position = intro_start.lerp(intro_end, t)
  intro_camera.look_at(intro_look_start.lerp(intro_look_end, t), Vector3.UP)
  if intro_time >= 6.0: _end_intro()
 if train_stage == "aboard":
  for streak: Node3D in train_streaks: streak.position.z = fposmod(streak.position.z + delta * 7.0 + 8.0, 16.0) - 8.0
  if train_contact and not train_contact_complete: train_contact.person.animate_motion(delta, 0.0)
 var entry := Campaign.progress.mission(operation_id)
 var key_id := str(entry.get("key_id", ""))
 var keys: Array[String] = []
 for i: int in range(1,6):
  var id := "key_%02d" % i
  keys.append("%02d" % i if Campaign.progress.recovered_keys.has(id) else "--")
 hud.text = "%s   /   USB [%s]\nTARGET: %s   %s\n%s: %s\n%s\nE INTERACT   ·   F5 SAVE   ·   F9 LOAD   ·   ESC PAUSE" % [entry.get("name", operation_id), " ".join(keys), config["target"], "COMPLETE" if target_complete else "ACTIVE", key_id.to_upper().replace("_", " "), "SECURED" if key_secured else "NOT SECURED", message]
 reticle.visible = player.aiming and not intro_active
 _overlay(target.person, red_overlay if player.instinct_active and not target_complete else null)
 var key_pos := key_marker.global_position
 var key_visible := false
 if player.instinct_active and not key_secured and player.global_position.distance_to(key_pos) < 4.0 and not player.camera.is_position_behind(key_pos):
  var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, key_pos)
  var excluded: Array[RID] = [player.get_rid()]
  if key_marker.get_parent() is HotelNpc: excluded.append((key_marker.get_parent() as HotelNpc).get_rid())
  ray.exclude = excluded
  key_visible = get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
 _overlay(key_marker, yellow_overlay if key_visible else null)

func _overlay(node: Node, material: Material) -> void:
 if node is MeshInstance3D: (node as MeshInstance3D).material_overlay = material
 for child: Node in node.get_children(): _overlay(child, material)

func _reachable(pos: Vector3, excluded: RID = RID()) -> bool:
 if player.global_position.distance_to(pos) > 2.0: return false
 var q := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, pos + Vector3.UP * 0.8)
 var exclude: Array[RID] = [player.get_rid()]
 if excluded.is_valid(): exclude.append(excluded)
 q.exclude = exclude
 return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _interact() -> void:
 if intro_active: return
 var placement := str(config["placement"])
 if _reachable(target.global_position, target.get_rid()):
  if not target_complete:
   if target.stunned_time > 0.0:
    message = "The target cannot respond while incapacitated."
    return
   target_complete = true
   target.complete_objective(false)
   message = str(config["target"]) + ": " + str(config["target_line"]) + "  /  Ruby: " + str(config["clue"])
   return
  if placement == "target" and not key_secured:
   _secure_key()
   return
 if placement == "guard" and not key_secured and _reachable(guard.global_position, guard.get_rid()):
  _secure_key()
  return
 if placement == "safe" and not key_secured and _reachable(key_marker.global_position):
  _secure_key()
  return
 if train_contact and not train_contact_complete and _reachable(train_contact.global_position, train_contact.get_rid()):
  train_contact_complete = true
  train_contact.complete_objective(false)
  message = "Train contact: The manifest was routed through a market intermediary. Ruby: Take the carriage exit."
  return
 if _reachable(exit_marker.global_position):
  if not target_complete or not key_secured:
   message = "Extraction locked: confront the target and physically secure this operation's key."
  elif operation_id == "tung_chung" and train_stage == "station":
   _board_train()
  elif operation_id == "tung_chung" and not train_contact_complete:
   message = "Ruby: Speak to the train contact before leaving the carriage."
  elif Campaign.complete(operation_id, 0):
   var next := "res://scenes/usb_decryption.tscn" if operation_id == "ngong_ping" and Campaign.progress.usb_ready() and not Campaign.progress.usb_decryption_seen else "res://scenes/ending.tscn"
   get_tree().change_scene_to_file(next)
  else: message = "Campaign progress could not be saved."
  return
 message = str(config["clue"])

# A separate fictional train carriage is staged beyond the station boundary;
# it is entered by a controlled scene transition, never by rail access gameplay.
func _board_train() -> void:
 if train_car == null: _build_train()
 train_stage = "aboard"
 player.global_position = Vector3(0,0.05,85)
 player.velocity = Vector3.ZERO
 player.rotation.y = 0.0
 exit_marker.global_position = Vector3(0,0.05,74)
 message = "Ruby: You are aboard. Find the train contact, then leave through the carriage door."

func _build_train() -> void:
 train_car = Node3D.new()
 train_car.name = "FictionalTrainCarriage"
 train_car.position = Vector3(0,0,80)
 add_child(train_car)
 _train_solid(Vector3(0,-0.15,0), Vector3(4.5,0.3,16), Color(0.36,0.39,0.39))
 _train_solid(Vector3(-2.25,1.5,0), Vector3(0.2,3,16), Color(0.66,0.69,0.67))
 _train_solid(Vector3(2.25,1.5,0), Vector3(0.2,3,16), Color(0.66,0.69,0.67))
 _train_solid(Vector3(0,1.5,8), Vector3(4.5,3,0.2), Color(0.55,0.59,0.57))
 _train_solid(Vector3(0,1.5,-8), Vector3(4.5,3,0.2), Color(0.55,0.59,0.57))
 _part(train_car, Vector3(0,3.05,0), Vector3(4.5,0.12,16), Color(0.46,0.52,0.51))
 for side: float in [-1.0,1.0]:
  for z: float in [-5.0,-2.0,1.0,4.0]:
   _part(train_car, Vector3(side*2.12,1.9,z), Vector3(0.04,0.9,1.9), Color(0.25,0.43,0.46))
   _train_solid(Vector3(side*1.65,0.42,z), Vector3(0.9,0.75,1.2), Color(0.24,0.31,0.34))
   _part(train_car, Vector3(side*1.93,1.05,z), Vector3(0.35,1.1,1.2), Color(0.24,0.31,0.34))
 # Moving light bands give a restrained impression of travel through the
 # carriage windows; no real railway layout is simulated.
 for side: float in [-1.0,1.0]:
  for i: int in range(6):
   var streak := Node3D.new()
   streak.position = Vector3(side*2.07,1.85,-7.5+float(i)*2.5)
   train_car.add_child(streak)
   _part(streak,Vector3.ZERO,Vector3(0.025,0.05,1.1),Color(0.52,0.69,0.65))
   train_streaks.append(streak)
 var title := Label3D.new()
 title.text = "BLACKLINE  /  TRAIN CONTACT"
 title.position = Vector3(0,2.4,-7.8)
 title.font_size = 32
 title.pixel_size = 0.004
 train_car.add_child(title)
 var profile := NpcProfile.new()
 profile.identity = "Train contact"
 profile.occupation = "special"
 train_contact = HotelNpc.new()
 train_contact.profile = profile
 train_contact.position = Vector3(0,0.05,79)
 add_child(train_contact)
 train_contact.set_physics_process(false)

func _train_solid(pos: Vector3, size: Vector3, color: Color) -> void:
 var body := StaticBody3D.new()
 body.position = pos
 train_car.add_child(body)
 _part(body, Vector3.ZERO, size, color)
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collider.shape = shape
 body.add_child(collider)

func _secure_key() -> void:
 var id := str(Campaign.progress.mission(operation_id).get("key_id", ""))
 if Campaign.secure_mission_key(operation_id, id):
  key_secured = true
  key_marker.visible = false
  message = "Ruby: " + id.to_upper().replace("_", " ") + " secured. Reach extraction after completing the target."
 else: message = "Could not secure the key. Check campaign save permissions."

func _on_trespass_notice(_npc: HotelNpc, text: String, exit_point: Vector3) -> void:
 var direction := exit_point - player.global_position
 var axis := "east" if direction.x > 0.0 else "west"
 if absf(direction.z) > absf(direction.x): axis = "south" if direction.z > 0.0 else "north"
 message = text + "  /  EXIT: " + axis.to_upper()

func _select_equipment(slot: int) -> void:
 message = "Equipped: " + Campaign.item_label(player.equipment.selected) if player.equipment.select_slot(slot) else "No equipment in that slot."

func _use_equipment() -> void:
 if player.equipment.selected != "quiet_line":
  message = "Aim with right mouse, then fire with left mouse."
  return
 for npc: HotelNpc in npc_list:
  if npc.stunned_time <= 0 and not npc.objective_completed and _reachable(npc.global_position, npc.get_rid()):
   npc.incapacitate(12.0)
   player.body_mesh.use_quiet_tool()
   gadget_audio.play()
   message = "Quiet Line temporarily incapacitated " + npc.profile.identity + "."
   return
 message = "Quiet Line requires a nearby unobstructed person."

func _fire() -> void:
 if not player.aiming or player.equipment.selected != "training_sidearm" or player.equipment.charges <= 0: return
 var center := get_viewport().get_visible_rect().size * 0.5
 var origin := player.camera.project_ray_origin(center)
 var eye := player.global_position + Vector3.UP * (player.stance_height * 0.8)
 var clearance := PhysicsRayQueryParameters3D.create(eye, origin)
 clearance.exclude = [player.get_rid()]
 if not get_world_3d().direct_space_state.intersect_ray(clearance).is_empty():
  message = "Camera obstructed. Move for a clear shot."
  return
 var query := PhysicsRayQueryParameters3D.create(origin, origin + player.camera.project_ray_normal(center) * 50.0)
 query.exclude = [player.get_rid()]
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 player.equipment.charges -= 1
 player.shot_feedback()
 shot_audio.play()
 if not hit.is_empty() and hit["collider"] is HotelNpc:
  var npc := hit["collider"] as HotelNpc
  if npc == train_contact and not train_contact_complete:
   message = "Ruby: We need the contact's account. Speak to them instead."
  elif npc == target and not target_complete:
   target_complete = true
   target.complete_objective(true)
   message = "Ruby: Target tagged. " + str(config["clue"])
  elif npc.incapacitate(12.0): message = "Assessment pulse temporarily incapacitated " + npc.profile.identity + "."
  reticle.call("confirm_hit")
 else: message = "Assessment pulse discharged."
 for npc: HotelNpc in npc_list:
  if npc.global_position.distance_to(player.global_position) < 9.0: npc.observe_disturbance(player.global_position)

func save_game() -> void:
 var p := player.global_position
 var data := {"mission_id": operation_id, "target_complete": target_complete, "target_incapacitated": target.completed_incapacitated, "key_id": str(Campaign.progress.mission(operation_id).get("key_id", "")), "key_secured": key_secured, "train_stage": train_stage, "train_contact_complete": train_contact_complete, "position": [p.x,p.y,p.z], "equipment": player.equipment.snapshot()}
 message = "Checkpoint saved." if SaveStore.write(save_path, data) else "Checkpoint save failed."

func load_game() -> void:
 var data := SaveStore.read(save_path)
 if data.get("mission_id", "") != operation_id:
  message = "No valid checkpoint for this operation."
  return
 if operation_id == "tung_chung" and data.get("train_stage", "") == "aboard" and data.get("target_complete", false) == true and data.get("key_secured", false) == true:
  _board_train()
  train_contact_complete = data.get("train_contact_complete", false) == true
  if train_contact_complete: train_contact.complete_objective(false)
 else:
  train_stage = "station"
  exit_marker.global_position = _vec(config["exit"])
  train_contact_complete = false
  if train_contact: train_contact.queue_free()
  if train_car: train_car.queue_free()
  train_streaks.clear()
  train_contact = null
  train_car = null
 target_complete = data.get("target_complete", false) == true
 target.restore_objective(target_complete, data.get("target_incapacitated", false) == true)
 var expected := str(Campaign.progress.mission(operation_id).get("key_id", ""))
 key_secured = data.get("key_id", "") == expected and data.get("key_secured", false) == true and Campaign.progress.recovered_keys.has(expected)
 key_marker.visible = not key_secured
 player.equipment.restore(data.get("equipment"), Campaign.progress, operation_id)
 var pos: Variant = data.get("position", [])
 if pos is Array and pos.size() == 3 and (pos[0] is float or pos[0] is int) and (pos[1] is float or pos[1] is int) and (pos[2] is float or pos[2] is int):
  var p := _vec(pos)
  var bound := 21.0 if config["map"] == "station" else 44.0
  var in_bounds := absf(p.x) < bound and absf(p.z) < bound
  if train_stage == "aboard": in_bounds = absf(p.x) < 2.0 and p.z > 72.5 and p.z < 87.5
  if is_finite(p.x) and is_finite(p.y) and is_finite(p.z) and in_bounds and p.y > -1.0 and p.y < 5.0:
   player.global_position = p
   player.velocity = Vector3.ZERO
 message = "Checkpoint loaded. NPC routines are transient."
