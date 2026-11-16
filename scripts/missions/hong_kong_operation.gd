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
var witness: HotelNpc
var witness_found: bool = false
var key_marker: Node3D
var intel_marker: Node3D
var uniform_marker: Node3D
var uniform_found: bool = false
var intel_found: bool = false
var exit_marker: Node3D
var hud: Control
var fps_label: Label
var briefing: Label
var skip_button: Button
var intro_start: Vector3
var intro_end: Vector3
var intro_look_start: Vector3
var intro_look_end: Vector3
var establishing_start: Vector3
var establishing_end: Vector3
var establishing_focus: Vector3
var has_establishing: bool = false
var reticle: Control
var intro_camera: Camera3D
var intro_time: float = 0.0
var intro_active: bool = true
var extraction_active: bool = false
var extraction_camera: Camera3D
var pause_menu: CanvasLayer
var extraction_time: float = 0.0
var extraction_next: String = ""
var target_complete: bool = false
var key_secured: bool = false
var train_stage: String = "station"
var train_contact: HotelNpc
var train_contact_complete: bool = false
var train_chase_active: bool = false
var train_chase_finished: bool = false
var train_car: Node3D
var train_streaks: Array[Node3D] = []
var departure_streaks: Array[Node3D] = []
var train_gate: StaticBody3D
var train_chase_trigger: Area3D
var train_passengers: Array[StylizedPerson] = []
var train_ambience: AudioStreamPlayer
var escape_seen: bool = false
var story_phase: String = ""
var story_time: float = 0.0
var story_camera: Camera3D
var story_start: Vector3
var story_set: Node3D
var story_runner: StylizedPerson
var story_player: StylizedPerson
var message: String = ""
var npc_list: Array[HotelNpc] = []
var red_overlay: StandardMaterial3D
var yellow_overlay: StandardMaterial3D
var shot_audio: AudioStreamPlayer
var gadget_audio: AudioStreamPlayer
var train_departure_seen: bool = false
var cinematic_title: Label
var cinema_bars: Array[ColorRect] = []

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
 var witness_at := _vec(config["witness_pos"])
 witness = scene.call("_target", str(config["witness"]), "civilian", witness_at, witness_at + Vector3(0,0,1.4)) as HotelNpc
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
 player.coin_requested.connect(_throw_coin)
 player.fire_requested.connect(_fire)
 _build_markers()
 if operation_id == "tung_chung": _build_train()
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
 intel_marker = Node3D.new()
 intel_marker.name = "OptionalMissionIntel"
 var annex: Node = scene.find_child("MissionNeighbourhood", true, false)
 if annex:
  uniform_marker = Node3D.new()
  uniform_marker.name = "ServiceDisguise"
  uniform_marker.position = annex.call("uniform_world_position")
  add_child(uniform_marker)
  _part(uniform_marker, Vector3(0,0.8,0), Vector3(0.6,1.2,0.3), Color(0.27,0.42,0.44))
  var uniform_label := Label3D.new()
  uniform_label.text = "STAFF DISGUISE"
  uniform_label.position = Vector3(0,1.65,0)
  uniform_label.font_size = 27
  uniform_label.pixel_size = 0.004
  uniform_marker.add_child(uniform_label)
 intel_marker.position = annex.call("intel_world_position") if annex else _vec(config["intel_pos"])
 add_child(intel_marker)
 _part(intel_marker, Vector3(0,0.22,0), Vector3(0.55,0.42,0.45), Color(0.22,0.48,0.55))
 var intel_label := Label3D.new()
 intel_label.text = "OPTIONAL INTEL"
 intel_label.position = Vector3(0,1.0,0)
 intel_label.font_size = 27
 intel_label.pixel_size = 0.004
 intel_marker.add_child(intel_label)
 exit_marker = Node3D.new()
 exit_marker.name = "Extraction"
 exit_marker.position = _vec(config["exit"])
 add_child(exit_marker)
 _part(exit_marker, Vector3(0,0.04,0), Vector3(1.7,0.06,1.7), Color(0.28,0.65,0.62))
 var exit_label := Label3D.new()
 exit_label.text = "BOARD TRAIN" if operation_id == "tung_chung" else "EXTRACTION"
 exit_label.position = Vector3(0,1.5,0)
 exit_label.font_size = 30
 exit_label.pixel_size = 0.004
 exit_marker.add_child(exit_label)

func _part(parent: Node3D, pos: Vector3, size: Vector3, color: Color, finish: String = "plain") -> MeshInstance3D:
 var part := MeshInstance3D.new()
 part.mesh = StationMaterials.box_mesh(size)
 part.position = pos
 part.material_override = StationMaterials.material(color, finish)
 parent.add_child(part)
 return part

func _build_ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 hud = preload("res://scripts/ui/mission_tracker.gd").new()
 hud.position = Vector2(24,20)
 canvas.add_child(hud)
 fps_label = Label.new()
 fps_label.position = Vector2(1120,20)
 fps_label.add_theme_font_size_override("font_size", 15)
 fps_label.add_theme_color_override("font_shadow_color", Color.BLACK)
 fps_label.add_theme_constant_override("shadow_offset_x", 2)
 fps_label.add_theme_constant_override("shadow_offset_y", 2)
 canvas.add_child(fps_label)
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
 skip_button.pressed.connect(_skip_cinematic)
 canvas.add_child(skip_button)
 reticle = preload("res://scripts/ui/aim_reticle.gd").new()
 reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(reticle)
 var top_bar := ColorRect.new()
 top_bar.anchor_right = 1.0
 top_bar.offset_bottom = 34.0
 top_bar.color = Color(0.008,0.015,0.018,0.96)
 top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(top_bar)
 var bottom_bar := ColorRect.new()
 bottom_bar.anchor_top = 1.0
 bottom_bar.anchor_right = 1.0
 bottom_bar.anchor_bottom = 1.0
 bottom_bar.offset_top = -34.0
 bottom_bar.color = Color(0.008,0.015,0.018,0.96)
 bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(bottom_bar)
 cinema_bars = [top_bar,bottom_bar]
 cinematic_title = Label.new()
 cinematic_title.position = Vector2(32,42)
 cinematic_title.add_theme_font_size_override("font_size",14)
 cinematic_title.add_theme_color_override("font_color",Color(0.78,0.83,0.78))
 cinematic_title.add_theme_color_override("font_shadow_color",Color.BLACK)
 cinematic_title.add_theme_constant_override("shadow_offset_x",1)
 cinematic_title.add_theme_constant_override("shadow_offset_y",1)
 cinematic_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(cinematic_title)
 _set_cinematic_overlay("",false)
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
 shot_audio.bus = "SFX"
 shot_audio.stream = ProceduralSound.tone(180.0,0.12,0.14)
 add_child(shot_audio)
 gadget_audio = AudioStreamPlayer.new()
 gadget_audio.bus = "SFX"
 gadget_audio.stream = ProceduralSound.tone(260.0,0.12,0.035)
 add_child(gadget_audio)

func _set_cinematic_overlay(title: String, visible: bool) -> void:
 cinematic_title.text = title
 cinematic_title.visible = visible
 for bar: ColorRect in cinema_bars: bar.visible = visible

func _begin_intro() -> void:
 player.set_physics_process(false)
 player.set_process_unhandled_input(false)
 intro_camera = Camera3D.new()
 Campaign.configure_camera(intro_camera)
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
 # A short location establishing shot precedes a cut to the physical target.
 # Ngong Ping's existing panorama already frames the public landmark.
 var neighbourhood: Node3D = scene.find_child("MissionNeighbourhood", true, false)
 if neighbourhood:
  has_establishing = true
  establishing_start = neighbourhood.to_global(Vector3(0,6,8))
  establishing_end = neighbourhood.to_global(Vector3(0,5,14))
  establishing_focus = neighbourhood.to_global(Vector3(0,2,42))
 elif operation_id == "tung_chung":
  has_establishing = true
  establishing_start = Vector3(0,4.2,7)
  establishing_end = Vector3(2,3.5,5)
  establishing_focus = Vector3(-3,1.5,-4)
 intro_camera.global_position = establishing_start if has_establishing else intro_start
 intro_camera.look_at(establishing_focus if has_establishing else intro_look_start, Vector3.UP)
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
 pause_menu = preload("res://scripts/ui/pause_menu.gd").new()
 pause_menu.set("world", self)
 add_child(pause_menu)
 message = "Ruby: " + _next_objective()

func _skip_cinematic() -> void:
 if intro_active: _end_intro()
 elif extraction_active: _finish_extraction()
 elif not story_phase.is_empty(): _finish_story()

func _input(event: InputEvent) -> void:
 if (intro_active or extraction_active or not story_phase.is_empty()) and event.is_action_pressed("release_mouse"):
  get_viewport().set_input_as_handled()
  _skip_cinematic()

func _unhandled_input(event: InputEvent) -> void:
 if intro_active or extraction_active or not story_phase.is_empty(): return
 if event.is_action_pressed("save_game"): save_game()
 elif event.is_action_pressed("load_game"): load_game()

# A single source of truth for the next mandatory step. Optional witnesses and
# intel never participate in this decision.
func _next_objective() -> String:
 if not target_complete: return "Confront or tag " + str(config["target"]) + "."
 if not key_secured:
  if operation_id == "tung_chung" and target_complete: return "Recover Key 01 from the concourse."
  return str(config["clue"])
 if operation_id == "tung_chung":
  if not escape_seen: return "Watch the courier's escape."
  if train_stage == "station": return "Walk through the open platform door to board the train."
  if not train_contact_complete: return "PURSUE KAI THROUGH BOTH CARS · WEAVE AROUND THE LUGGAGE CART · CATCH HIM IN FRONT."
 return "Reach the extraction marker and press E."

func _physics_process(delta: float) -> void:
 if train_stage == "aboard" and story_phase.is_empty() and not intro_active and not extraction_active:
  _update_train_chase(delta)

func _process(delta: float) -> void:
 if player == null: return
 if intro_active:
  intro_time += delta
  if has_establishing and intro_time < 2.0:
   intro_camera.global_position = establishing_start.lerp(establishing_end, intro_time / 2.0)
   intro_camera.look_at(establishing_focus, Vector3.UP)
  else:
   var t := minf((intro_time - 2.0) / 4.0, 1.0) if has_establishing else minf(intro_time / 6.0, 1.0)
   intro_camera.global_position = intro_start.lerp(intro_end, t)
   intro_camera.look_at(intro_look_start.lerp(intro_look_end, t), Vector3.UP)
  if intro_time >= 6.0: _end_intro()
 if not story_phase.is_empty(): _advance_story(delta)
 if operation_id == "tung_chung":
  _sync_train_gate()
  if train_stage == "station" and target_complete and key_secured and escape_seen and player.global_position.z > 14.5 and absf(player.global_position.x - 19.0) < 1.8:
   _enter_train()
 if extraction_active:
  extraction_time += delta
  var focus := player.global_position + Vector3.UP
  var offset := Vector3(4,2.5,5) if operation_id in ["tung_chung", "the_streets"] else (Vector3(-4,3,5) if operation_id in ["the_district", "the_harbour"] else Vector3(0,5,8))
  extraction_camera.global_position = focus + offset.lerp(offset * 1.35, minf(extraction_time / 3.0,1.0))
  extraction_camera.look_at(focus, Vector3.UP)
  if extraction_time >= 3.0:
   _finish_extraction()
   return
 if train_stage == "aboard":
  for streak: Node3D in train_streaks:
   var segment := 16.0 if streak.has_meta("second_car") else 0.0
   streak.position.z = fposmod(streak.position.z - segment + delta * 7.0 + 8.0, 16.0) - 8.0 + segment
  if train_contact and not train_contact_complete: train_contact.person.animate_motion(delta, 0.0)
  for passenger: StylizedPerson in train_passengers: passenger.animate_motion(delta, 0.0)
 var entry := Campaign.progress.mission(operation_id)
 var key_id := str(entry.get("key_id", ""))
 var total := 5 if operation_id == "tung_chung" else 3
 var remaining := int(not target_complete) + int(not key_secured) + 1
 if operation_id == "tung_chung": remaining += int(train_stage == "station") + int(not train_contact_complete)
 var current := total - remaining + 1
 var extraction := "AVAILABLE" if remaining == 1 else "LOCKED"
 var equipment_text := Campaign.item_label(player.equipment.selected)
 if player.equipment.selected == "training_sidearm": equipment_text += "  %d / 5" % player.equipment.charges
 else: equipment_text += "  /  Q USE"
 hud.call("set_state", str(entry.get("name", operation_id)), "STAGE %d / %d   ·   %d MANDATORY REMAIN" % [current,total,remaining], _next_objective(), "%s %s   ·   EXTRACTION %s\n%s   ·   G COIN %d" % [key_id.to_upper().replace("_", " "), "SECURED" if key_secured else "MISSING", extraction, equipment_text, player.equipment.coins_remaining], "OPTIONAL INTEL: %s   ·   WITNESS: %s" % ["SECURED" if intel_found else "OPEN", "SPOKEN" if witness_found else "OPEN"], message)
 reticle.visible = player.aiming and not intro_active and not extraction_active
 fps_label.visible = bool(Campaign.settings["show_fps"])
 if fps_label.visible: fps_label.text = "%d FPS" % Engine.get_frames_per_second()
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
 _highlight_optional(intel_marker, not intel_found)
 if uniform_marker: _highlight_optional(uniform_marker, not uniform_found)

# Optional clues and disguises follow the same nearby, visible-only Instinct
# rule as ordinary mission items; they do not reveal objects through walls.
func _highlight_optional(node: Node3D, available: bool) -> void:
 var item_visible := false
 var point := node.global_position + Vector3.UP * 0.7
 if available and player.instinct_active and player.global_position.distance_to(node.global_position) < 4.0 and not player.camera.is_position_behind(point):
  var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, point)
  query.exclude = [player.get_rid()]
  item_visible = get_world_3d().direct_space_state.intersect_ray(query).is_empty()
 _overlay(node, yellow_overlay if item_visible else null)

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
 if intro_active or extraction_active or not story_phase.is_empty(): return
 var placement := str(config["placement"])
 if _reachable(target.global_position, target.get_rid()):
  if not target_complete:
   if target.stunned_time > 0.0:
    message = "The target cannot respond while incapacitated."
    return
   target_complete = true
   target.complete_objective(false)
   if operation_id == "tung_chung": _begin_story("escape")
   message = str(config["target"]) + ": " + str(config["target_line"]) + "  /  Ruby: " + str(config["clue"])
   return
  if placement == "target" and operation_id != "tung_chung" and not key_secured:
   _secure_key()
   return
 if operation_id == "tung_chung" and target_complete and not key_secured and _reachable(key_marker.global_position):
  _secure_key()
  return
 if placement == "guard" and not key_secured and _reachable(guard.global_position, guard.get_rid()):
  _secure_key()
  return
 if placement == "safe" and not key_secured and _reachable(key_marker.global_position):
  _secure_key()
  return
 if uniform_marker and not uniform_found and _reachable(uniform_marker.global_position):
  uniform_found = true
  uniform_marker.visible = false
  player.set_disguise("staff")
  message = "Staff disguise acquired. Staff areas permit this role; secure areas still do not."
  return
 if not witness_found and _reachable(witness.global_position, witness.get_rid()):
  if witness.stunned_time > 0.0:
   message = "The witness cannot speak while incapacitated."
   return
  witness_found = true
  witness.person.interact()
  message = str(config["witness"]) + ": " + str(config["witness_line"])
  return
 if not intel_found and _reachable(intel_marker.global_position):
  intel_found = true
  intel_marker.visible = false
  message = "Ruby: " + str(config["intel_text"])
  return
 if train_contact and not train_contact_complete and _reachable(train_contact.global_position, train_contact.get_rid()):
  _begin_story("roof")
  return
 if _reachable(exit_marker.global_position):
  if not target_complete or not key_secured:
   message = "Ruby: " + _next_objective()
  elif operation_id == "tung_chung" and train_stage == "station":
   message = "Ruby: The train door is open. Walk forward through the marked platform doorway."
  elif operation_id == "tung_chung" and not train_contact_complete:
   message = "Ruby: Follow and confront the courier in the forward carriage before extracting."
  elif Campaign.complete(operation_id, int(intel_found) + int(witness_found)):
   Campaign.ending["intel_found"] = intel_found
   Campaign.ending["witness_found"] = witness_found
   var next := "res://scenes/usb_decryption.tscn" if operation_id == "ngong_ping" and Campaign.progress.usb_ready() and not Campaign.progress.usb_decryption_seen else "res://scenes/ending.tscn"
   _begin_extraction(next)
  else: message = "Campaign progress could not be saved."
  return
 message = str(config["clue"])

# Fictional, non-interactive story scenes. Skipping finalizes exactly the
# same flags and restores the gameplay camera, without granting the key.
func _begin_story(phase: String) -> void:
 if not story_phase.is_empty(): return
 story_phase = phase
 story_time = 0.0
 if pause_menu: pause_menu.set_process_input(false)
 player.set_physics_process(false)
 player.set_process_unhandled_input(false)
 player.velocity = Vector3.ZERO
 player.aiming = false
 player.body_mesh.interact()
 story_camera = Camera3D.new()
 Campaign.configure_camera(story_camera)
 add_child(story_camera)
 if phase == "escape":
  _drop_station_key()
  story_start = target.global_position
  target.collision_layer = 0
  target.set_physics_process(false)
  briefing.text = "KAI VENN: The manifest is already moving. You are too late.\nRUBY: The key is on the concourse. Secure it, then follow the courier."
  _set_cinematic_overlay("TUNG CHUNG  /  COURIER ESCAPE",true)
 elif phase == "departure":
  _build_departure_exterior()
  briefing.text = "TUNG CHUNG LINE  /  The train clears the platform. Follow the courier through the connected carriages."
  _set_cinematic_overlay("TUNG CHUNG  /  DEPARTURE",true)
 else:
  story_set = Node3D.new()
  story_set.position = Vector3(19,3.2,37)
  add_child(story_set)
  story_runner = StylizedPerson.new()
  story_runner.role = "manager"
  story_set.add_child(story_runner)
  story_runner.position = Vector3(0,0,2)
  story_player = StylizedPerson.new()
  story_set.add_child(story_player)
  story_player.position = Vector3(0,0,-1)
  briefing.text = "KAI VENN: The market intermediary arranged the transfer. I never saw the buyer.\nRUBY: That is our lead. Return to the carriage exit."
  train_contact.visible = false
  _set_cinematic_overlay("TUNG CHUNG  /  THE HANDOFF",true)
 briefing.visible = true
 skip_button.visible = true
 hud.visible = false
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 story_camera.make_current()
 _advance_story(0.0)

func _build_departure_exterior() -> void:
 # A separate non-interactive cinematic set is used for this short departure
 # insert. It represents a fictional city-side train view, not an explorable or
 # physically connected rail scene; the saved player remains at the train door.
 departure_streaks.clear()
 story_set = Node3D.new()
 story_set.name = "FictionalDepartureCutaway"
 story_set.position = Vector3(220,0,0)
 add_child(story_set)
 _part(story_set,Vector3(0,-0.4,0),Vector3(42,0.5,38),Color(0.10,0.14,0.17),"plain")
 # Exterior body: repeated windows are actual gaps between the lower/upper
 # panels and posts, with tinted glass planes and a restrained amber waist line.
 _part(story_set,Vector3(0,0.5,0),Vector3(4.4,0.75,27),Color(0.36,0.49,0.52),"painted_metal")
 _part(story_set,Vector3(0,2.75,0),Vector3(4.4,0.55,27),Color(0.30,0.43,0.46),"painted_metal")
 _part(story_set,Vector3(0,3.12,0),Vector3(4.55,0.16,27.2),Color(0.38,0.48,0.49),"brushed_metal")
 for side: float in [-1.0,1.0]:
  # This camera stays on the positive-X exterior side. Leave the opposite
  # facade open so the fictional skyline reads through the window bays instead
  # of a second opaque wall hiding the city.
  if side < 0.0: continue
  _part(story_set,Vector3(side*2.12,1.88,0),Vector3(0.14,0.30,27),Color(0.36,0.48,0.49),"painted_metal")
  for z: float in [-11.5,-8.1,-4.7,-1.3,2.1,5.5,8.9,11.5]:
   _part(story_set,Vector3(side*2.13,1.86,z),Vector3(0.12,1.66,0.16),Color(0.38,0.49,0.48),"brushed_metal")
  for z: float in [-9.8,-6.4,-3.0,0.4,3.8,7.2,10.6]:
   _part(story_set,Vector3(side*2.16,1.9,z),Vector3(0.035,1.34,2.7),Color(0.38,0.66,0.70,0.68),"glass")
  _part(story_set,Vector3(side*2.17,0.98,0),Vector3(0.05,0.12,26),Color(0.85,0.43,0.28),"emissive")
  _part(story_set,Vector3(side*2.18,0.34,0),Vector3(0.06,0.28,26),Color(0.055,0.09,0.10),"rubber")
 # Mid-carriage seam and flexible connector make the paired-car composition
 # readable in the exterior shot without interrupting the playable aisle.
 for side: float in [-1.0,1.0]:
  _part(story_set,Vector3(side*2.15,1.55,0),Vector3(0.15,2.5,0.24),Color(0.11,0.18,0.20),"brushed_metal")
 _part(story_set,Vector3(0,3.12,0),Vector3(4.48,0.16,0.24),Color(0.11,0.18,0.20),"brushed_metal")
 # End faces, a two-tone door and bogies establish direction and scale.
 _part(story_set,Vector3(0,1.65,-13.45),Vector3(4.35,2.45,0.18),Color(0.13,0.23,0.26),"painted_metal")
 _part(story_set,Vector3(0,1.45,-13.57),Vector3(1.28,1.95,0.06),Color(0.12,0.29,0.32),"glass")
 for z: float in [-8.0,8.0]:
  _part(story_set,Vector3(0,0.08,z),Vector3(3.7,0.32,2.3),Color(0.045,0.065,0.071),"brushed_metal")
  for side: float in [-1.0,1.0]:
   _part(story_set,Vector3(side*1.42,-0.06,z),Vector3(0.32,0.25,0.65),Color(0.09,0.13,0.14),"brushed_metal")
 # Distant fictional block silhouettes and window lights read through the
 # glass; the view uses no recognizable skyline, real station map or logo.
 for i: int in range(9):
  var z := -17.0 + float(i)*4.1
  var height := 5.5 + float((i*7)%5)*1.25
  var width := 2.4 + float(i%3)*0.7
  _part(story_set,Vector3(-7.6,height*0.5,z),Vector3(width,height,3.8),Color(0.065+float(i%2)*0.018,0.12,0.15),"emissive")
  for row: int in range(1,4):
   var wy := 0.9 + float(row)*1.05
   if wy > height-0.4: continue
   for col: int in range(2):
    _part(story_set,Vector3(-5.55,wy,z-0.52+float(col)*1.04),Vector3(0.035,0.32,0.42),Color(0.95,0.67,0.37,0.92) if (i+row+col)%3==0 else Color(0.35,0.78,0.86,0.88),"emissive")
 # Passing environmental light bars create lateral motion while the camera
 # tracks the carriage; all are non-colliding cinematic dressing.
 for i: int in range(14):
  var streak := Node3D.new()
  streak.position = Vector3(3.4,1.2+float(i%4)*0.55,-16.0+float(i)*2.4)
  story_set.add_child(streak)
  _part(streak,Vector3.ZERO,Vector3(0.045,0.035,1.8+float(i%3)*0.8),Color(0.22,0.72,0.78,0.82) if i%3==0 else Color(0.88,0.39,0.25,0.72),"emissive")
  departure_streaks.append(streak)

func _drop_station_key() -> void:
 if key_marker.get_parent() != self:
  key_marker.reparent(self, true)
  key_marker.global_position = target.global_position + Vector3(0,0,0.8)

func _advance_story(delta: float) -> void:
 story_time += delta
 if story_phase == "escape":
  var t := clampf(story_time / 5.0,0.0,1.0)
  var waypoint := Vector3(4,0.05,-2)
  var destination := Vector3(19,0.05,11)
  var old := target.global_position
  target.global_position = story_start.lerp(waypoint, minf(t*1.7,1.0)) if t < 0.59 else waypoint.lerp(destination,(t-0.59)/0.41)
  var motion := target.global_position-old
  if motion.length_squared() > 0.0001: target.person.rotation.y = atan2(-motion.x,-motion.z)
  target.person.animate_motion(delta, 3.4)
  story_camera.global_position = target.global_position + Vector3(4,3.0,6)
  story_camera.look_at(target.global_position + Vector3.UP,Vector3.UP)
 elif story_phase == "departure":
  var t := clampf(story_time / 5.2,0.0,1.0)
  var ease := t*t*(3.0-2.0*t)
  var focus := story_set.global_position + Vector3(0,1.55,-5.0+ease*10.0)
  story_camera.global_position = story_set.global_position + Vector3(8.4-0.9*ease,3.7-0.65*ease,-10.0+ease*18.0)
  story_camera.look_at(focus,Vector3.UP)
  for i: int in range(departure_streaks.size()):
   var streak := departure_streaks[i]
   streak.position.z = fposmod(streak.position.z + delta*(7.5+float(i%4)*1.3) + 17.0,34.0)-17.0
 else:
  var t := clampf(story_time / 5.0,0.0,1.0)
  story_runner.position.z = 2.0 + t*3.0
  story_player.position.z = -1.0 + t*2.8
  story_runner.rotation.y = PI
  story_player.rotation.y = PI
  story_runner.animate_motion(delta,2.7)
  story_player.animate_motion(delta,2.5)
  story_camera.global_position = Vector3(25,7.5,38+2.0*t)
  story_camera.look_at(Vector3(19,4.4,38+2.0*t),Vector3.UP)
 if story_time >= (5.2 if story_phase == "departure" else 5.0): _finish_story()

func _finish_story() -> void:
 if story_phase.is_empty(): return
 if story_phase == "escape":
  escape_seen = true
  target.visible = false
  target.collision_layer = 0
  message = "Ruby: The courier boarded. Recover the dropped key, then walk through the platform door."
 elif story_phase == "departure":
  train_departure_seen = true
  message = "Ruby: The line is moving. Follow Kai through the connected carriages."
  if story_set: story_set.queue_free()
  story_set = null
  departure_streaks.clear()
 else:
  train_contact_complete = true
  train_contact.complete_objective(false)
  train_contact.collision_layer = 0
  train_contact.visible = false
  message = "Ruby: The courier named the market intermediary. Reach the forward carriage exit."
  if story_set: story_set.queue_free()
  story_set = null
 story_phase = ""
 _set_cinematic_overlay("",false)
 story_camera.queue_free()
 briefing.visible = false
 skip_button.visible = false
 hud.visible = true
 player.set_physics_process(true)
 player.set_process_unhandled_input(true)
 player.camera.make_current()
 if pause_menu: pause_menu.set_process_input(true)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 _sync_train_gate()

# Progress is committed before the presentation; Escape never duplicates a
# completion or awards anything. The scene remains interactive only afterwards.
func _begin_extraction(next: String) -> void:
 if extraction_active: return
 extraction_active = true
 extraction_time = 0.0
 extraction_next = next
 # PauseMenu processes input before its parent; it must not intercept the
 # cinematic's Escape skip or pause a completed operation.
 if pause_menu: pause_menu.set_process_input(false)
 player.set_physics_process(false)
 player.set_process_unhandled_input(false)
 player.velocity = Vector3.ZERO
 player.aiming = false
 extraction_camera = Camera3D.new()
 Campaign.configure_camera(extraction_camera)
 add_child(extraction_camera)
 var focus := player.global_position + Vector3.UP
 extraction_camera.global_position = focus + Vector3(4,2.5,5)
 extraction_camera.look_at(focus, Vector3.UP)
 extraction_camera.make_current()
 hud.visible = false
 reticle.visible = false
 briefing.text = str(config["extraction_line"])
 briefing.visible = true
 skip_button.visible = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _finish_extraction() -> void:
 if not extraction_active: return
 extraction_active = false
 get_tree().change_scene_to_file(extraction_next)

# A self-contained fictional pair of carriages is attached directly to the
# platform. The player walks across the doorway; no rail-access mechanics exist.
func _board_train() -> void:
 # Used only for checkpoint migration and deterministic capture setup.
 if train_car == null: _build_train()
 player.global_position = Vector3(19,0.05,16.5)
 player.velocity = Vector3.ZERO
 # Checkpoint restoration starts on the interior side of the threshold and
 # must not replay the one-time departure insert.
 train_departure_seen = true
 _enter_train()

func _enter_train() -> void:
 train_stage = "aboard"
 train_chase_active = false
 train_chase_finished = false
 if train_ambience and not train_ambience.playing: train_ambience.play()
 exit_marker.global_position = Vector3(19,0.05,44)
 for child: Node in exit_marker.get_children():
  if child is Label3D: (child as Label3D).text = "EXTRACTION"
 if train_contact: train_contact.visible = true
 message = "Ruby: Follow the courier through the connected carriages."
 if not train_departure_seen: _begin_story("departure")

func _update_train_chase(delta: float) -> void:
 if not train_contact or train_contact_complete or train_chase_finished: return
 # A positional fallback keeps old saves/test fixtures safe if an Area enters
 # before the body signal connects; the normal path is the physical trigger.
 if not train_chase_active and player.global_position.z >= 26.5:
  _on_train_chase_trigger(player)
 if not train_chase_active: return
 # The courier travels through both connected car sections. CharacterBody
 # collision resolves the route; player movement remains wholly user controlled.
 var remaining := 43.0 - train_contact.global_position.z
 if remaining <= 0.05:
  train_chase_finished = true
  train_contact.velocity = Vector3.ZERO
  train_contact.person.animate_motion(delta, 0.0)
  return
 var step := minf(remaining, 2.8 * delta)
 train_contact.velocity = Vector3(0, 0, 2.8)
 train_contact.move_and_collide(Vector3(0, 0, step))
 train_contact.person.animate_motion(delta, 2.8)
 if train_contact.global_position.z >= 42.95:
  train_chase_finished = true
  train_contact.velocity = Vector3.ZERO

func _on_train_chase_trigger(body: Node3D) -> void:
 if body != player or train_stage != "aboard" or train_chase_active or train_contact_complete: return
 train_chase_active = true
 message = "Ruby: Kai is moving! Pick either side of the luggage cart and catch him in the forward carriage."

func _sync_train_gate() -> void:
 if not train_gate: return
 var open: bool = target_complete and key_secured and escape_seen
 train_gate.visible = not open
 (train_gate.get_child(1) as CollisionShape3D).set_deferred("disabled", open)

func _build_train() -> void:
 if train_car: return
 train_car = Node3D.new()
 train_car.name = "FictionalTrainCarriages"
 train_car.position = Vector3(19,0,22)
 add_child(train_car)
 train_ambience = AudioStreamPlayer.new()
 train_ambience.bus = "Ambient"
 train_ambience.stream = ProceduralSound.ambience("train")
 add_child(train_ambience)
 for car_offset: float in [0.0,16.0]:
  _train_solid(Vector3(0,-0.15,car_offset),Vector3(4.5,0.3,16.1),Color(0.43,0.50,0.49),"train_floor")
  _train_solid(Vector3(0,3.04,car_offset),Vector3(4.5,0.12,16.1),Color(0.42,0.49,0.48),"painted_metal")
  for side: float in [-1.0,1.0]:
   # Invisible continuous collision preserves the window openings visually but
   # prevents an accidental step through the carriage shell.
   _train_collision(Vector3(side*2.22,1.5,car_offset),Vector3(0.18,3.0,16.0))
   _part(train_car,Vector3(side*2.22,0.42,car_offset),Vector3(0.18,0.84,15.8),Color(0.42,0.49,0.48),"painted_metal")
   _part(train_car,Vector3(side*2.22,2.79,car_offset),Vector3(0.18,0.48,15.8),Color(0.34,0.43,0.42),"painted_metal")
   _part(train_car,Vector3(side*2.22,0.93,car_offset),Vector3(0.19,0.08,15.8),Color(0.83,0.45,0.28),"emissive")
   for z: float in [-7.65,7.65]:
    _part(train_car,Vector3(side*2.22,1.88,z+car_offset),Vector3(0.18,1.75,0.7),Color(0.20,0.29,0.31),"painted_metal")
   for z: float in [-5.8,-2.2,1.4,5.0]:
    var window := _part(train_car,Vector3(side*2.13,1.87,z+car_offset),Vector3(0.035,1.55,2.65),Color(0.30,0.54,0.60,0.48),"glass")
    window.name = "CarriageWindowGlass"
    _part(train_car,Vector3(side*2.10,1.87,z+car_offset-1.35),Vector3(0.06,1.68,0.10),Color(0.47,0.55,0.53),"brushed_metal")
    _part(train_car,Vector3(side*2.10,1.87,z+car_offset+1.35),Vector3(0.06,1.68,0.10),Color(0.47,0.55,0.53),"brushed_metal")
   for z: float in [-6.0,-2.0,2.0,6.0]:
    var streak := Node3D.new()
    streak.position = Vector3(side*2.34,1.55,z+car_offset)
    streak.set_meta("second_car",car_offset>0.0)
    train_car.add_child(streak)
    _part(streak,Vector3.ZERO,Vector3(0.035,0.045,1.1),Color(0.32,0.72,0.78,0.82),"emissive")
    train_streaks.append(streak)
   # Four fixed seat rows per side; fabric, armrests and pedestal are separate.
   for z: float in [-5.3,-1.5,2.3,5.7]:
    # Keep the trolley approach and exit clear of seat collisions so either
    # side route remains a genuinely navigable choice.
    if car_offset == 0.0 and z in [-1.5, 2.3]: continue
    _train_solid(Vector3(side*1.62,0.39,z+car_offset),Vector3(1.02,0.72,1.35),Color(0.36,0.50,0.49),"fabric")
    _part(train_car,Vector3(side*1.62,0.82,z+car_offset-0.34),Vector3(1.02,0.72,0.48),Color(0.42,0.57,0.56),"fabric")
    _part(train_car,Vector3(side*1.62,0.83,z+car_offset+0.20),Vector3(0.82,0.10,0.56),Color(0.48,0.62,0.59),"fabric")
    _part(train_car,Vector3(side*1.98,0.82,z+car_offset),Vector3(0.12,0.68,1.1),Color(0.42,0.48,0.46),"brushed_metal")
    if z == -5.3 or z == 2.3:
     _part(train_car,Vector3(side*1.10,1.18,z+car_offset+0.45),Vector3(0.72,0.055,0.48),Color(0.37,0.28,0.19),"wood")
     _part(train_car,Vector3(side*1.10,1.15,z+car_offset+0.45),Vector3(0.74,0.035,0.50),Color(0.52,0.40,0.28),"wood")
  _part(train_car,Vector3(0,2.94,car_offset),Vector3(1.9,0.045,0.30),Color(0.90,0.73,0.48),"emissive")
  var light := OmniLight3D.new()
  light.position = Vector3(0,2.60,car_offset)
  light.light_color = Color(0.76,0.87,0.85) if car_offset == 0.0 else Color(1.0,0.70,0.46)
  light.light_energy = 1.1 if car_offset == 0.0 else 0.9
  light.omni_range = 10.0
  light.shadow_enabled = false
  light.add_to_group("quality_practicals")
  light.visible = Campaign.settings["graphics"] != "LOW" and bool(Campaign.settings["practicals"])
  train_car.add_child(light)
  # Interior route labels and doorway ribs visually identify the passage between cars.
  var sign := Label3D.new()
  sign.text = "01  /  HONG KONG LINE"
  sign.position = Vector3(0,2.65,car_offset-7.2)
  sign.font_size = 23
  sign.pixel_size = 0.006
  sign.modulate = Color(0.83,0.76,0.60)
  train_car.add_child(sign)
 # The trolley creates a readable route split. Its narrow width leaves room
 # for a player-controlled left or right sidestep inside the carriage aisle.
 var route_obstacle := _train_solid(Vector3(0,0.48,0.4),Vector3(1.14,0.96,0.82),Color(0.40,0.34,0.27),"wood")
 route_obstacle.name = "LuggageRouteObstacle"
 _part(train_car,Vector3(0,0.98,0.4),Vector3(1.22,0.08,0.88),Color(0.55,0.48,0.37),"brushed_metal")
 var route_sign := Label3D.new()
 route_sign.text = "LUGGAGE  /  PASS EITHER SIDE"
 route_sign.position = Vector3(0,1.55,0.4)
 route_sign.font_size = 18
 route_sign.pixel_size = 0.005
 route_sign.modulate = Color(0.96,0.78,0.49)
 train_car.add_child(route_sign)
 train_chase_trigger = Area3D.new()
 train_chase_trigger.name = "TrainPursuitTrigger"
 train_chase_trigger.position = Vector3(0,1.1,4.5)
 train_chase_trigger.collision_layer = 0
 train_chase_trigger.collision_mask = 1
 var trigger_shape := CollisionShape3D.new()
 var trigger_box := BoxShape3D.new()
 trigger_box.size = Vector3(3.7,2.2,0.55)
 trigger_shape.shape = trigger_box
 train_chase_trigger.add_child(trigger_shape)
 train_chase_trigger.body_entered.connect(_on_train_chase_trigger)
 train_car.add_child(train_chase_trigger)
 _train_solid(Vector3(0,1.5,24),Vector3(4.5,3,0.2),Color(0.29,0.35,0.36),"painted_metal")
 # The inter-carriage vestibule is intentionally open; side jambs and header
 # frame it without blocking the aisle or creating an invisible threshold.
 for side: float in [-1.0,1.0]:
  _part(train_car,Vector3(side*1.68,1.45,8),Vector3(0.22,2.8,0.34),Color(0.18,0.28,0.30),"brushed_metal")
 _part(train_car,Vector3(0,2.88,8),Vector3(3.35,0.18,0.34),Color(0.18,0.28,0.30),"brushed_metal")
 for car_offset: float in [0.0,16.0]:
  for side: float in [-1.0,1.0]:
   var passenger := StylizedPerson.new()
   passenger.role = "civilian"
   passenger.appearance_seed = int(absf(side*17.0+(car_offset+5.3)*31.0))
   passenger.position = Vector3(side*1.62,0.78,car_offset-5.3)
   passenger.rotation.y = -side*PI*0.5
   passenger.set_seated(true)
   passenger.idle_activity = "waiting" if car_offset == 0.0 else "phone"
   train_car.add_child(passenger)
   train_passengers.append(passenger)
 train_gate = StaticBody3D.new()
 train_gate.position = Vector3(19,1.5,13.9)
 add_child(train_gate)
 _part(train_gate,Vector3.ZERO,Vector3(3.8,3,0.18),Color(0.23,0.37,0.39),"painted_metal")
 var gate_shape := CollisionShape3D.new()
 var gate_box := BoxShape3D.new()
 gate_box.size = Vector3(3.8,3,0.18)
 gate_shape.shape = gate_box
 train_gate.add_child(gate_shape)
 var profile := NpcProfile.new()
 profile.identity = "Kai Venn, courier"
 profile.occupation = "manager"
 train_contact = HotelNpc.new()
 train_contact.profile = profile
 train_contact.position = Vector3(19,0.05,36)
 add_child(train_contact)
 train_contact.set_physics_process(false)
 train_contact.visible = false

func _train_solid(pos: Vector3, size: Vector3, color: Color, finish: String = "plain") -> StaticBody3D:
 var body := StaticBody3D.new()
 body.position = pos
 train_car.add_child(body)
 _part(body,Vector3.ZERO,size,color,finish)
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collider.shape = shape
 body.add_child(collider)
 return body

func _train_collision(pos: Vector3, size: Vector3) -> void:
 var body := StaticBody3D.new()
 body.position = pos
 train_car.add_child(body)
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

func _throw_coin() -> void:
 if intro_active or extraction_active or not story_phase.is_empty(): return
 message = CoinDistraction.use(player, npc_list, self)

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
   target.complete_objective(operation_id != "tung_chung")
   if operation_id == "tung_chung": _begin_story("escape")
   message = "Ruby: Target tagged. " + str(config["clue"])
  elif npc.incapacitate(12.0): message = "Assessment pulse temporarily incapacitated " + npc.profile.identity + "."
  reticle.call("confirm_hit")
 else: message = "Assessment pulse discharged."
 for npc: HotelNpc in npc_list:
  if npc.global_position.distance_to(player.global_position) < 9.0: npc.observe_disturbance(player.global_position)

func save_game() -> void:
 var p := player.global_position
 var data := {"mission_id": operation_id, "uniform_found": uniform_found, "intel_found": intel_found, "witness_found": witness_found, "target_complete": target_complete, "target_incapacitated": target.completed_incapacitated, "key_id": str(Campaign.progress.mission(operation_id).get("key_id", "")), "key_secured": key_secured, "train_stage": train_stage, "escape_seen": escape_seen, "dropped_key_pos": [key_marker.global_position.x,key_marker.global_position.y,key_marker.global_position.z], "train_contact_complete": train_contact_complete, "train_departure_seen": train_departure_seen, "train_chase_active": train_chase_active, "train_chase_finished": train_chase_finished, "train_contact_position": [train_contact.global_position.x, train_contact.global_position.y, train_contact.global_position.z] if train_contact else [], "position": [p.x,p.y,p.z], "equipment": player.equipment.snapshot()}
 message = "Checkpoint saved." if SaveStore.write(save_path, data) else "Checkpoint save failed."

func load_game() -> void:
 var data := SaveStore.read(save_path)
 if data.get("mission_id", "") != operation_id:
  message = "No valid checkpoint for this operation."
  return
 var expected := str(Campaign.progress.mission(operation_id).get("key_id", ""))
 var saved_key_valid: bool = data.get("key_id", "") == expected and data.get("key_secured", false) == true and Campaign.progress.recovered_keys.has(expected)
 var previous_stage := train_stage
 target_complete = data.get("target_complete", false) == true
 key_secured = saved_key_valid
 # A checkpoint is never resumed mid-presentation: target completion
 # converges on the same post-escape state as a cinematic skip (also migrates
 # older saves which did not have a cinematic flag).
 escape_seen = target_complete if operation_id == "tung_chung" else false
 train_departure_seen = data.get("train_departure_seen", data.get("train_stage", "") == "aboard") == true
 target.restore_objective(target_complete, data.get("target_incapacitated", false) == true)
 if operation_id == "tung_chung":
  if target_complete:
   _drop_station_key()
   var saved_drop: Variant = data.get("dropped_key_pos", [])
   if saved_drop is Array and saved_drop.size() == 3 and (saved_drop[0] is int or saved_drop[0] is float) and (saved_drop[1] is int or saved_drop[1] is float) and (saved_drop[2] is int or saved_drop[2] is float):
    var drop := _vec(saved_drop)
    if drop.is_finite() and absf(drop.x) < 21.0 and absf(drop.z) < 13.0 and drop.y > -1.0 and drop.y < 5.0: key_marker.global_position = drop
   target.visible = false
   target.collision_layer = 0
  else:
   if key_marker.get_parent() != target: key_marker.reparent(target, false)
   key_marker.position = Vector3(0,1.1,0)
   target.visible = true
   target.collision_layer = 1
   target.global_position = _vec(config["target_pos"])
   target.set_physics_process(true)
  if data.get("train_stage", "") == "aboard" and target_complete and saved_key_valid and escape_seen:
   _board_train()
   train_contact_complete = data.get("train_contact_complete", false) == true
   train_chase_active = data.get("train_chase_active", false) == true
   train_chase_finished = data.get("train_chase_finished", false) == true
   var courier_position: Variant = data.get("train_contact_position", [])
   if courier_position is Array and courier_position.size() == 3 and (courier_position[0] is int or courier_position[0] is float) and (courier_position[1] is int or courier_position[1] is float) and (courier_position[2] is int or courier_position[2] is float):
    var courier_point := _vec(courier_position)
    if courier_point.is_finite() and absf(courier_point.x - 19.0) < 1.0 and courier_point.y > -1.0 and courier_point.y < 4.0 and courier_point.z >= 35.0 and courier_point.z <= 43.1: train_contact.global_position = courier_point
   train_contact.restore_objective(false, false)
   train_contact.collision_layer = 1
   train_contact.visible = true
   if train_contact_complete:
    train_contact.complete_objective(false)
    train_contact.collision_layer = 0
    train_contact.visible = false
  else:
   train_stage = "station"
   if train_ambience: train_ambience.stop()
   exit_marker.global_position = _vec(config["exit"])
   for child: Node in exit_marker.get_children():
    if child is Label3D: (child as Label3D).text = "BOARD TRAIN"
   train_contact_complete = false
   train_contact.restore_objective(false, false)
   train_contact.collision_layer = 1
   train_contact.visible = false
   if previous_stage == "aboard": player.global_position = _vec(config["spawn"])
  _sync_train_gate()
 uniform_found = uniform_marker != null and data.get("uniform_found", false) == true
 player.set_disguise("staff" if uniform_found else "visitor")
 if uniform_marker: uniform_marker.visible = not uniform_found
 witness_found = data.get("witness_found", false) == true
 intel_found = data.get("intel_found", false) == true
 intel_marker.visible = not intel_found
 key_marker.visible = not key_secured
 player.equipment.restore(data.get("equipment"), Campaign.progress, operation_id)
 var pos: Variant = data.get("position", [])
 if pos is Array and pos.size() == 3 and (pos[0] is float or pos[0] is int) and (pos[1] is float or pos[1] is int) and (pos[2] is float or pos[2] is int):
  var p := _vec(pos)
  var bound := 21.0 if config["map"] == "station" else 44.0
  var in_bounds := absf(p.x) < bound and absf(p.z) < bound and p.y > -1.0 and p.y < 5.0
  var annex: Node = scene.find_child("MissionNeighbourhood", true, false)
  if annex and annex.call("contains_world_position", p): in_bounds = true
  if train_stage == "aboard": in_bounds = absf(p.x-19.0) < 1.8 and p.z > 14.0 and p.z < 45.5 and p.y > -1.0 and p.y < 5.0
  if is_finite(p.x) and is_finite(p.y) and is_finite(p.z) and in_bounds:
   player.global_position = p
   player.velocity = Vector3.ZERO
 message = "Checkpoint loaded. NPC routines are transient."
