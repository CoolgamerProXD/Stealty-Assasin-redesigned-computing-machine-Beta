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
var reticle: Control
var intro_camera: Camera3D
var intro_time: float = 0.0
var intro_active: bool = true
var target_complete: bool = false
var key_secured: bool = false
var message: String = ""
var npc_list: Array[HotelNpc] = []
var red_overlay: StandardMaterial3D

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
 reticle = preload("res://scripts/ui/aim_reticle.gd").new()
 reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(reticle)
 red_overlay = StandardMaterial3D.new()
 red_overlay.albedo_color = Color(1,0.08,0.05,0.85)
 red_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 red_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 red_overlay.no_depth_test = true

func _begin_intro() -> void:
 player.set_physics_process(false)
 player.set_process_unhandled_input(false)
 intro_camera = Camera3D.new()
 add_child(intro_camera)
 var at := target.global_position
 intro_camera.global_position = at + Vector3(-5,4,7)
 intro_camera.look_at(at + Vector3.UP, Vector3.UP)
 intro_camera.make_current()
 briefing.text = str(Campaign.progress.mission(operation_id).get("briefing", "")) + "\n\nESC  /  SKIP BRIEFING"

func _end_intro() -> void:
 if not intro_active: return
 intro_active = false
 briefing.visible = false
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
  var at := target.global_position
  intro_camera.global_position = at + Vector3(-5,4,7).lerp(Vector3(4,2.5,4), t)
  intro_camera.look_at(at + Vector3.UP, Vector3.UP)
  if intro_time >= 6.0: _end_intro()
 var entry := Campaign.progress.mission(operation_id)
 var key_id := str(entry.get("key_id", ""))
 var keys: Array[String] = []
 for i: int in range(1,6):
  var id := "key_%02d" % i
  keys.append("%02d" % i if Campaign.progress.recovered_keys.has(id) else "--")
 hud.text = "%s   /   USB [%s]\nTARGET: %s   %s\n%s: %s\n%s\nE INTERACT   ·   F5 SAVE   ·   F9 LOAD   ·   ESC PAUSE" % [entry.get("name", operation_id), " ".join(keys), config["target"], "COMPLETE" if target_complete else "ACTIVE", key_id.to_upper().replace("_", " "), "SECURED" if key_secured else "NOT SECURED", message]
 reticle.visible = player.aiming and not intro_active
 _overlay(target.person, red_overlay if player.instinct_active and not target_complete else null)

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
   message = "Ruby: Target confronted. " + str(config["clue"])
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
 if _reachable(exit_marker.global_position):
  if not target_complete or not key_secured:
   message = "Extraction locked: confront the target and physically secure this operation's key."
  elif Campaign.complete(operation_id, 0):
   get_tree().change_scene_to_file("res://scenes/ending.tscn")
  else: message = "Campaign progress could not be saved."
  return
 message = str(config["clue"])

func _secure_key() -> void:
 var id := str(Campaign.progress.mission(operation_id).get("key_id", ""))
 if Campaign.secure_mission_key(operation_id, id):
  key_secured = true
  key_marker.visible = false
  message = "Ruby: " + id.to_upper().replace("_", " ") + " secured. Reach extraction after completing the target."
 else: message = "Could not secure the key. Check campaign save permissions."

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
 if not hit.is_empty() and hit["collider"] is HotelNpc:
  var npc := hit["collider"] as HotelNpc
  if npc == target and not target_complete:
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
 var data := {"mission_id": operation_id, "target_complete": target_complete, "target_incapacitated": target.completed_incapacitated, "key_id": str(Campaign.progress.mission(operation_id).get("key_id", "")), "key_secured": key_secured, "position": [p.x,p.y,p.z], "equipment": player.equipment.snapshot()}
 message = "Checkpoint saved." if SaveStore.write(save_path, data) else "Checkpoint save failed."

func load_game() -> void:
 var data := SaveStore.read(save_path)
 if data.get("mission_id", "") != operation_id:
  message = "No valid checkpoint for this operation."
  return
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
  if is_finite(p.x) and is_finite(p.y) and is_finite(p.z) and absf(p.x) < bound and absf(p.z) < bound and p.y > -1.0 and p.y < 5.0:
   player.global_position = p
   player.velocity = Vector3.ZERO
 message = "Checkpoint loaded. NPC routines are transient."
