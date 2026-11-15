extends Node3D
## Original greybox: The Meridian Hotel, after a missing archive incident.
var save_path: String = "user://meridian_save.json"
var player: HotelPlayer
var mission: Mission = Mission.new()
var interactables: Array[Interactable] = []
var npcs: Array[HotelNpc] = []
var primary_npc: HotelNpc
var hud: Label
var prompt: Label
var equipment_hud: Label
var crosshair: Label
var shot_audio: AudioStreamPlayer
var last_shot_start: Vector3
var last_shot_end: Vector3
var instinct_label: Label
var instinct_strength: float = 0.0
var instinct_red: StandardMaterial3D
var instinct_yellow: StandardMaterial3D
@export var instinct_item_range: float = 4.0
@export var instinct_target_range: float = 16.0
@export var instinct_target_color: Color = Color(1.0, 0.08, 0.05)
@export var instinct_item_color: Color = Color(1.0, 0.82, 0.05)
var message: String = ""

func mission_id() -> String:
 return "meridian"

func mission_path() -> String:
 return "res://resources/meridian_mission.json"

func safe_position(pos: Vector3) -> bool:
 return HotelLayout.is_safe_player_position(pos)

func _ready() -> void:
 save_path = Campaign.checkpoint_path(mission_id())
 var mission_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(mission_path()))
 if not mission.configure(mission_data):
  push_error("Invalid or missing Meridian mission configuration")
 _build_environment()
 _build_player()
 if mission.configured and mission.required_records > player.inventory.capacity:
  push_error("Mission requires more records than the inventory can hold")
  mission.configure(null)
 if mission.configured:
  for record: Dictionary in mission.available_records:
   if not safe_position(_vector(record["position"])):
    push_error("Mission record is outside the playable floor or inside a partition")
    mission.configure(null)
    break
 _build_npcs()
 _build_interactions()
 _build_ui()
 _setup_instinct()
 if Campaign.active_mission == mission_id():
  player.mouse_sensitivity = float(Campaign.settings["sensitivity"])
  var pause := preload("res://scripts/ui/pause_menu.gd").new()
  pause.world = self
  add_child(pause)
  if Campaign.load_checkpoint:
   load_game()
   Campaign.load_checkpoint = false

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
 var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
 holder.position = pos
 add_child(holder)
 var mesh := BoxMesh.new()
 mesh.size = size
 var visual := MeshInstance3D.new()
 visual.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.85
 visual.material_override = material
 holder.add_child(visual)
 if solid:
  var collider := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  collider.shape = shape
  holder.add_child(collider)

func _build_environment() -> void:
 var environment := WorldEnvironment.new()
 var sky := Environment.new()
 sky.background_mode = Environment.BG_COLOR
 sky.background_color = Color(0.10, 0.13, 0.16)
 sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 sky.ambient_light_color = Color(0.73, 0.76, 0.78)
 sky.ambient_light_energy = 0.8
 environment.environment = sky
 add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55, -30, 0)
 light.light_energy = 0.8
 light.shadow_enabled = false
 add_child(light)
 _box(Vector3(0, -0.15, 0), Vector3(24, 0.3, 16), Color(0.34, 0.32, 0.29))
 _box(Vector3(-12, 1.5, 0), Vector3(0.25, 3, 16), Color(0.52, 0.49, 0.43))
 _box(Vector3(12, 1.5, 0), Vector3(0.25, 3, 16), Color(0.48, 0.46, 0.41))
 _box(Vector3(0, 1.5, -8), Vector3(24, 3, 0.25), Color(0.49, 0.47, 0.42))
 _box(Vector3(0, 1.5, 8), Vector3(24, 3, 0.25), Color(0.49, 0.47, 0.42))
 # The two openings in each partition provide alternate routes. Furniture remains non-solid.
 _box(Vector3(4.5, 0.01, 0), Vector3(5, 0.02, 15.5), Color(0.26, 0.29, 0.29), false)
 _box(Vector3(9.45, 0.02, 0), Vector3(4.8, 0.03, 15.5), Color(0.24, 0.25, 0.27), false)
 _box(Vector3(-5, 0.5, -4.8), Vector3(4, 1, 1), Color(0.28, 0.18, 0.13), false)
 _box(Vector3(-5, 0.35, 3.5), Vector3(2.4, 0.7, 1), Color(0.33, 0.22, 0.18), false)
 _box(Vector3(4.5, 0.45, -5), Vector3(2.2, 0.9, 1), Color(0.32, 0.27, 0.22), false)
 _box(Vector3(9.5, 0.5, -5), Vector3(2.5, 1, 1), Color(0.28, 0.27, 0.24), false)
 for boundary: float in [2.0, 7.0]:
  for z: float in [-6.0, 0.0, 6.0]:
   _box(Vector3(boundary, 1.5, z), Vector3(0.2, 3.0, 4.0), Color(0.42, 0.40, 0.36))
 # Architectural trim and lamps are non-colliding; existing routes remain unchanged.
 _box(Vector3(0, 3.05, 0), Vector3(24, 0.1, 16), Color(0.31, 0.31, 0.29), false)
 _box(Vector3(-5, 0.025, 0), Vector3(10, 0.025, 5), Color(0.34, 0.22, 0.20), false)
 for x: float in [-8.0, -2.0, 4.5, 9.5]:
  _box(Vector3(x, 2.95, 0), Vector3(1.8, 0.06, 0.18), Color(0.9, 0.77, 0.52), false)
  _box(Vector3(x, 1.3, -7.84), Vector3(1.5, 1.0, 0.04), Color(0.22, 0.27, 0.29), false)
  _box(Vector3(x, 1.3, -7.79), Vector3(1.25, 0.75, 0.04), Color(0.40, 0.39, 0.34), false)
 for boundary: float in [2.0, 7.0]:
  for z: float in [-3.0, 3.0]:
   _box(Vector3(boundary, 2.85, z), Vector3(0.32, 0.3, 2.0), Color(0.30, 0.27, 0.23), false)
   for side: float in [-0.92, 0.92]:
    _box(Vector3(boundary, 1.4, z + side), Vector3(0.32, 2.8, 0.14), Color(0.30, 0.27, 0.23), false)
 var region := NavigationRegion3D.new()
 region.navigation_mesh = HotelLayout.navigation_mesh()
 add_child(region)

func _build_player() -> void:
 player = HotelPlayer.new()
 player.position = Vector3(-9, 0.05, 5)
 add_child(player)
 player.interaction_requested.connect(_interact_nearest)
 player.equipment.configure(Campaign.progress, mission_id())
 player.equipment_use_requested.connect(_use_equipment)
 player.fire_requested.connect(_fire)
 player.equipment_selected.connect(_select_equipment)

func _vector(data: Array) -> Vector3:
 return Vector3(float(data[0]), float(data[1]), float(data[2]))

func _build_npcs() -> void:
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/hotel_population.json"))
 if not data is Array:
  push_error("Invalid hotel population data")
  return
 for record: Dictionary in data:
  var profile := NpcProfile.new()
  profile.identity = str(record["identity"])
  profile.occupation = str(record["occupation"])
  profile.alertness = float(record["alertness"])
  for entry: Dictionary in record["schedule"]:
   profile.schedule.append(ScheduleEntry.new(_vector(entry["destination"]), str(entry["activity"]), float(entry["duration"])))
  var npc := HotelNpc.new()
  npc.profile = profile
  npc.player = player
  npc.position = _vector(record["start"])
  add_child(npc)
  npcs.append(npc)
 if mission.primary_target.get("id") == "adrian_locke":
  var data_target: Dictionary = mission.primary_target
  var profile := NpcProfile.new()
  profile.identity = str(data_target["name"])
  profile.occupation = "manager"
  profile.alertness = 0.7
  for entry: Dictionary in data_target["schedule"]:
   profile.schedule.append(ScheduleEntry.new(_vector(entry["destination"]), str(entry["activity"]), float(entry["duration"])))
  primary_npc = HotelNpc.new()
  primary_npc.profile = profile
  primary_npc.player = player
  primary_npc.position = _vector(data_target["start"])
  add_child(primary_npc)
  npcs.append(primary_npc)

func _add_interactable(pos: Vector3, title: String, kind: String, id: String, color: Color) -> void:
 var object := Interactable.new()
 object.position = pos
 object.label = title
 object.kind = kind
 object.identifier = id
 add_child(object)
 var visual := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = Vector3(0.55, 0.55, 0.55)
 visual.mesh = mesh
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.emission_enabled = true
 mat.emission = color * 0.3
 visual.material_override = mat
 visual.position.y = 0.4
 object.add_child(visual)
 object.activated.connect(_on_interaction)
 interactables.append(object)

func _build_interactions() -> void:
 for record: Dictionary in mission.available_records:
  _add_interactable(_vector(record["position"]), record["label"], "clue", record["id"], Color(0.9, 0.72, 0.34))
 _add_interactable(Vector3(-1, 0, 5.5), "Change into staff uniform", "disguise", "staff", Color(0.3, 0.6, 0.85))
 _add_interactable(Vector3(-10, 0, 5.5), "Leave hotel", "extract", "exit", Color(0.4, 0.8, 0.5))
 # The existing records employee is now the named witness to the archive transfer.
 for npc: HotelNpc in npcs:
  if npc.profile.identity == "Ivo Chen":
   _add_interactable(Vector3.ZERO, "Question Ivo Chen", "target", "interview_ivo", Color(0.9, 0.55, 0.2))
   var target: Interactable = interactables.back()
   target.reparent(npc, false)
   target.position = Vector3.ZERO
   var marker := target.get_child(0) as Node3D
   marker.position.y = 2.15
   break
 if primary_npc:
  _add_interactable(Vector3.ZERO, "Confront Adrian Locke", "primary", "adrian_locke", Color(0.95, 0.24, 0.20))
  var target_marker: Interactable = interactables.back()
  target_marker.reparent(primary_npc, false)
  target_marker.position = Vector3.ZERO
  var marker_visual := target_marker.get_child(0) as Node3D
  marker_visual.position.y = 2.15

func _build_ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 var overlay := Control.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(overlay)
 var left := PanelContainer.new()
 left.position = Vector2(20, 20)
 left.custom_minimum_size = Vector2(485, 0)
 left.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.025, 0.04, 0.05, 0.88)
 style.border_width_left = 3
 style.border_color = Color(0.75, 0.54, 0.31)
 style.content_margin_left = 16
 style.content_margin_right = 16
 style.content_margin_top = 12
 style.content_margin_bottom = 12
 left.add_theme_stylebox_override("panel", style)
 overlay.add_child(left)
 hud = Label.new()
 hud.custom_minimum_size.x = 450
 hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 hud.add_theme_font_size_override("font_size", 17)
 left.add_child(hud)
 var right := PanelContainer.new()
 right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 right.offset_left = -315
 right.offset_right = -20
 right.offset_top = 20
 right.offset_bottom = 150
 right.mouse_filter = Control.MOUSE_FILTER_IGNORE
 right.add_theme_stylebox_override("panel", style.duplicate())
 overlay.add_child(right)
 equipment_hud = Label.new()
 equipment_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 equipment_hud.add_theme_font_size_override("font_size", 17)
 right.add_child(equipment_hud)
 var bottom := PanelContainer.new()
 bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
 bottom.offset_left = 20
 bottom.offset_right = 850
 bottom.offset_top = -105
 bottom.offset_bottom = -20
 bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bottom.add_theme_stylebox_override("panel", style.duplicate())
 overlay.add_child(bottom)
 crosshair = Label.new()
 crosshair.text = "+"
 crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 crosshair.add_theme_font_size_override("font_size", 32)
 crosshair.add_theme_color_override("font_outline_color", Color.BLACK)
 crosshair.add_theme_constant_override("outline_size", 4)
 crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
 crosshair.set_anchors_preset(Control.PRESET_CENTER)
 crosshair.offset_left = -20
 crosshair.offset_right = 20
 crosshair.offset_top = -20
 crosshair.offset_bottom = 20
 crosshair.visible = false
 overlay.add_child(crosshair)
 instinct_label = Label.new()
 instinct_label.text = "INSTINCT"
 instinct_label.position = Vector2(20, 230)
 instinct_label.add_theme_font_size_override("font_size", 15)
 instinct_label.modulate = Color(0.95, 0.82, 0.5)
 instinct_label.visible = false
 overlay.add_child(instinct_label)
 shot_audio = AudioStreamPlayer.new()
 shot_audio.stream = ProceduralSound.tone(180.0, 0.12, 0.14)
 add_child(shot_audio)
 prompt = Label.new()
 prompt.add_theme_font_size_override("font_size", 16)
 bottom.add_child(prompt)

func _select_equipment(slot: int) -> void:
 if player.equipment.select_slot(slot):
  message = "Equipped: " + Campaign.item_label(player.equipment.selected)
 else: message = "No equipment in that slot."

func _use_equipment() -> void:
 if player.equipment.selected == "training_sidearm":
  message = "Aim with right mouse, then fire with left mouse."
 elif player.equipment.selected == "quiet_line":
  var nearest: HotelNpc = null
  var best := 1.8
  for npc: HotelNpc in npcs:
   var distance := npc.global_position.distance_to(player.global_position)
   if distance < best and npc.stunned_time <= 0 and _clear_reach(npc.global_position, 1.8, npc.get_rid()):
    nearest = npc
    best = distance
  if nearest:
   nearest.stunned_time = 12.0
   nearest.set_state("disabled")
   message = "Quiet Line: " + nearest.profile.identity + " temporarily incapacitated."
  else: message = "Quiet Line requires a nearby unobstructed person."

func _fire() -> void:
 if not player.aiming: return
 if player.equipment.selected != "training_sidearm":
  message = "Select the training sidearm to fire."
  return
 if player.equipment.charges <= 0:
  message = "Training sidearm empty."
  return
 player.equipment.charges -= 1
 var screen_center := player.camera.get_viewport().get_visible_rect().size * 0.5
 var origin := player.camera.project_ray_origin(screen_center)
 var direction := player.camera.project_ray_normal(screen_center)
 var end := origin + direction * 50.0
 var query := PhysicsRayQueryParameters3D.create(origin, end)
 query.exclude = [player.get_rid()]
 query.collide_with_areas = true
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():
  end = hit["position"]
  var collider: Object = hit["collider"]
  if collider is Area3D and collider.get_parent() is Interactable:
   var object := collider.get_parent() as Interactable
   if object.kind == "robot" and not object.used: _on_interaction(object)
   else: message = "Assessment pulse hit an inactive unit."
  elif collider is HotelNpc:
   var npc := collider as HotelNpc
   npc.stunned_time = 12.0
   npc.set_state("disabled")
   message = "Assessment pulse temporarily incapacitated " + npc.profile.identity + "."
  else: message = "Assessment pulse struck a surface."
 else: message = "Assessment pulse discharged."
 for npc: HotelNpc in npcs:
  if npc.stunned_time <= 0 and npc.global_position.distance_to(player.global_position) < 9.0:
   npc.observe_trespass(player.global_position)
 last_shot_start = origin
 last_shot_end = end
 shot_audio.play()
 _shot_trace(origin, end)

func _shot_trace(origin: Vector3, end: Vector3) -> void:
 var trace := MeshInstance3D.new()
 var mesh := ImmediateMesh.new()
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color = Color(0.65, 0.9, 1.0)
 mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
 mesh.surface_add_vertex(to_local(origin))
 mesh.surface_add_vertex(to_local(end))
 mesh.surface_end()
 trace.mesh = mesh
 add_child(trace)
 var tween := create_tween()
 tween.tween_interval(0.12)
 tween.tween_callback(trace.queue_free)

func _clear_reach(point: Vector3, maximum: float, excluded: RID = RID()) -> bool:
 if player.global_position.distance_to(point) > maximum: return false
 var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, point + Vector3.UP)
 var exclusions: Array[RID] = [player.get_rid()]
 if excluded.is_valid(): exclusions.append(excluded)
 query.exclude = exclusions
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _setup_instinct() -> void:
 instinct_red = _highlight_material(instinct_target_color)
 instinct_yellow = _highlight_material(instinct_item_color)

func _highlight_material(color: Color) -> StandardMaterial3D:
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.albedo_color = Color(color.r, color.g, color.b, 0.0)
 return material

func _overlay_recursive(node: Node, material: Material) -> void:
 if node is MeshInstance3D: (node as MeshInstance3D).material_overlay = material
 for child: Node in node.get_children(): _overlay_recursive(child, material)

func _target_node() -> Node3D:
 if mission_id() == "initiation": return get("robot") as Node3D
 return primary_npc

func _in_player_view(point: Vector3) -> bool:
 if player.camera.is_position_behind(point): return false
 var screen := player.camera.unproject_position(point)
 return player.camera.get_viewport().get_visible_rect().has_point(screen)

func _update_instinct(delta: float) -> void:
 var target := _target_node()
 if target and not mission.target_discovered:
  var point := target.global_position + Vector3.UP
  var excluded: RID = primary_npc.get_rid() if primary_npc else RID()
  if _in_player_view(point) and _clear_reach(target.global_position, instinct_target_range, excluded):
   mission.target_discovered = true
 instinct_strength = move_toward(instinct_strength, 1.0, delta * 5.0) if player.instinct_active else 0.0
 instinct_label.visible = player.instinct_active
 instinct_red.albedo_color.a = instinct_strength * 0.7
 instinct_yellow.albedo_color.a = instinct_strength * 0.7
 if target:
  var target_done := mission.action_complete if mission_id() == "initiation" else mission.target_complete
  var can_highlight := player.instinct_active and mission.target_discovered and not target_done
  var visual: Node = primary_npc.person if primary_npc else target
  _overlay_recursive(visual, instinct_red if can_highlight else null)
 for object: Interactable in interactables:
  if object.kind not in ["clue", "disguise"]: continue
  var eligible := player.instinct_active and not object.used and _in_player_view(object.global_position + Vector3.UP * 0.4) and _clear_reach(object.global_position, instinct_item_range)
  _overlay_recursive(object, instinct_yellow if eligible else null)

func _nearest() -> Interactable:
 var best: Interactable = null
 var distance := 1.8
 for object: Interactable in interactables:
  var d := player.global_position.distance_to(object.global_position)
  if object.kind in ["target", "primary"] and object.get_parent() is HotelNpc and (object.get_parent() as HotelNpc).stunned_time > 0.0: continue
  if d < distance and object.available(player.role):
   var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, object.global_position + Vector3.UP * 0.4)
   var excluded: Array[RID] = [player.get_rid()]
   if object.kind in ["target", "primary"] and object.get_parent() is HotelNpc:
    excluded.append((object.get_parent() as HotelNpc).get_rid())
   query.exclude = excluded
   if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
    best = object
    distance = d
 return best

func _interact_nearest() -> void:
 var object := _nearest()
 if object: object.interact(player.role)

func _on_interaction(object: Interactable) -> void:
 match object.kind:
  "clue":
   if not mission.has_record(object.identifier) or mission.clues.has(object.identifier): return
   if not player.inventory.has_item(object.identifier) and not player.inventory.add(object.identifier):
    message = "Inventory full. The record was not collected."
    return
   if not mission.record_clue(object.identifier): return
   object.used = true
   object.visible = false
   for record: Dictionary in mission.available_records:
    if record["id"] == object.identifier:
     message = record["message"]
     break
  "primary":
   if object.get_parent() is HotelNpc and (object.get_parent() as HotelNpc).stunned_time > 0.0:
    message = "Locke cannot speak while incapacitated. Wait for recovery."
    return
   if mission.mark_target(object.identifier):
    object.used = true
    object.visible = false
    message = "Locke: The transfer was authorized. I never saw who collected it."
  "target":
   if object.get_parent() is HotelNpc and (object.get_parent() as HotelNpc).stunned_time > 0.0:
    message = "Ivo cannot talk while incapacitated. Wait for recovery."
    return
   if mission.mark_action(object.identifier):
    object.used = true
    object.visible = false
    message = "Ivo: The archive left before my shift. A manager signed it out."
  "disguise":
   player.set_disguise("staff")
   object.used = true
   object.visible = false
   message = "Staff uniform acquired. Staff area access granted; secure area remains restricted."
  "extract":
   if mission.extracted: message = "Investigation already complete."
   elif mission.can_extract():
    if Campaign.active_mission == mission_id():
     if Campaign.complete(mission_id(), mission.clues.size()):
      mission.extract()
      get_tree().change_scene_to_file("res://scenes/ruby_meeting.tscn" if mission_id() == "initiation" else "res://scenes/ending.tscn")
     else: message = "Could not save campaign progress. Try again."
    elif mission.extract(): message = "INVESTIGATION COMPLETE — you left with the evidence."
   else: message = mission.objective_text()

func save_game() -> void:
 if SaveStore.write(save_path, SessionSnapshot.capture(player, mission)):
  message = "Progress saved."
 else:
  message = "Save failed. Check storage permissions."

func load_game() -> void:
 var data := SaveStore.read(save_path)
 if data.is_empty():
  message = "No valid compatible save found."
 else:
  SessionSnapshot.restore(data, player, mission, interactables, safe_position, Campaign.progress)
  message = "Progress loaded. NPCs continue their current routines."

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("save_game"): save_game()
 elif event.is_action_pressed("load_game"): load_game()


func _process(_delta: float) -> void:
 if player == null or hud == null: return
 _update_instinct(_delta)
 var area := AccessRules.area_at(player.global_position)
 var access := "AUTHORIZED" if AccessRules.can_enter(player.role, area) else "RESTRICTED"
 var highest := 0.0
 for npc: HotelNpc in npcs: highest = maxf(highest, npc.suspicion)
 var title := "01  /  INITIATION" if mission_id() == "initiation" else "02  /  THE MERIDIAN"
 var target := "ASSESSMENT UNIT" if mission_id() == "initiation" else "ADRIAN LOCKE  /  OPERATIONS DIRECTOR"
 var target_done := mission.action_complete if mission_id() == "initiation" else mission.target_complete
 var target_state := "COMPLETE" if target_done else "LOCATE AND INTERACT"
 if mission_id() == "initiation" and not mission.action_complete and get("robot_alert") == true:
  target_state = "SCANNING NEARBY"
 hud.text = title + "\nPRIMARY  /  " + target + "  ·  " + target_state + "\nSECONDARY  /  " + mission.progress_text() + ("  |  IVO: " + ("QUESTIONED" if mission.action_complete else "QUESTION") if mission_id() == "meridian" else "") + "\nNEXT  /  " + mission.objective_text() + "\n" + "%s  /  %s  ·  AWARENESS %.0f%%" % [player.role.to_upper(), access, highest]
 var slots := "1  TRAINING SIDEARM"
 if player.equipment.available.has("quiet_line"): slots += "\n2  QUIET LINE"
 equipment_hud.text = "EQUIPMENT\n" + slots + "\nEQUIPPED  /  " + Campaign.item_label(player.equipment.selected).to_upper()
 if player.equipment.selected == "training_sidearm": equipment_hud.text += "\nCHARGES  %d / 5" % player.equipment.charges
 crosshair.visible = player.aiming
 var nearest := _nearest()
 prompt.text = ("E  /  " + nearest.label + "\n" if nearest else "") + message + "\n1 / 2 select   ·   RMB aim / LMB fire   ·   Q gadget   ·   Ctrl instinct"
