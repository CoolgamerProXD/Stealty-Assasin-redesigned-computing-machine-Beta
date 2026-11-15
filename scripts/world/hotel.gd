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
var prompt_panel: PanelContainer
var equipment_hud: Label
var awareness_hud: Label
var interaction_dot: Label
var crosshair: Control
var shot_audio: AudioStreamPlayer
var objective_audio: AudioStreamPlayer
var ambience_audio: AudioStreamPlayer
var last_shot_start: Vector3
var last_shot_end: Vector3
var instinct_label: Label
var fps_label: Label
var instinct_strength: float = 0.0
var instinct_red: StandardMaterial3D
var instinct_yellow: StandardMaterial3D
@export var instinct_item_range: float = 4.0
@export var instinct_target_range: float = 16.0
@export var instinct_target_color: Color = Color(1.0, 0.08, 0.05)
@export var instinct_item_color: Color = Color(1.0, 0.82, 0.05)
var message: String = ""
var last_message: String = ""
var message_remaining: float = 0.0

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
 var dressing := EnvironmentDressing.new()
 add_child(dressing)
 dressing.build(mission_id())
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
 var disturbances := DisturbanceSystem.new()
 disturbances.npcs = npcs
 add_child(disturbances)
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
 light.add_to_group("quality_lights")
 light.shadow_enabled = Campaign.settings["graphics"] != "LOW"
 add_child(light)
 _box(Vector3(0, -0.15, 0), Vector3(24, 0.3, 16), Color(0.34, 0.32, 0.29))
 # Preserve the original hotel and open its west wall into the new wing.
 for z: float in [-5.0, 5.0]:
  _box(Vector3(-12, 1.5, z), Vector3(0.25, 3, 6), Color(0.52, 0.49, 0.43))
 _build_meridian_wing()
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

func _build_meridian_wing() -> void:
 # A new west wing and upper level retain all original coordinates. Walkable
 # area is approximately seven times the original single-floor area; the
 # ground footprint itself is approximately 3.5 times the original.
 var floor_mat := Color(0.34,0.32,0.29)
 var walls := Color(0.55,0.52,0.46)
 var dark := Color(0.25,0.20,0.17)
 var brass := Color(0.70,0.53,0.29)
 _box(Vector3(-27,-0.15,0),Vector3(30,0.3,32),floor_mat)
 for z: float in [-16.0,16.0]:
  _box(Vector3(-27,3.5,z),Vector3(30,7,0.25),walls)
  _box(Vector3(0,5.4,z * 0.5),Vector3(24,3.6,0.25),walls)
 _box(Vector3(-42,3.5,0),Vector3(0.25,7,32),walls)
 _box(Vector3(12,5.4,0),Vector3(0.25,3.6,16),walls)
 for z: float in [-12.0,12.0]: _box(Vector3(-12,3.5,z),Vector3(0.25,7,8),walls)
 # Upper slabs leave a four metre stairwell, instead of a solid ceiling over it.
 _box(Vector3(-27,3.45,-7.5),Vector3(30,0.3,17),floor_mat)
 _box(Vector3(-27,3.45,10.5),Vector3(30,0.3,11),floor_mat)
 _box(Vector3(-39.5,3.45,3),Vector3(5,0.3,4),floor_mat)
 _box(Vector3(-18.5,3.45,3),Vector3(13,0.3,4),floor_mat)
 _box(Vector3(0,3.45,0),Vector3(24,0.3,16),floor_mat)
 # One gentle, collision-bearing architectural stair ramp: both directions.
 var ramp := StaticBody3D.new()
 ramp.name = "WestWingRamp"
 ramp.position = Vector3(-31,1.70,3)
 ramp.rotation.z = -atan(3.6 / 12.0)
 add_child(ramp)
 var ramp_mesh := MeshInstance3D.new()
 var shape := BoxMesh.new()
 shape.size = Vector3(12.55,0.2,3.4)
 ramp_mesh.mesh = shape
 var ramp_mat := StandardMaterial3D.new()
 ramp_mat.albedo_color = Color(0.38,0.27,0.20)
 ramp_mesh.material_override = ramp_mat
 ramp.add_child(ramp_mesh)
 var collider := CollisionShape3D.new()
 var ramp_shape := BoxShape3D.new()
 ramp_shape.size = shape.size
 collider.shape = ramp_shape
 ramp.add_child(collider)
 for side: float in [-1.9,1.9]:
  _box(Vector3(-31,2.4,3+side),Vector3(12.2,0.08,0.08),brass,false)
 # Private room door faces the upper corridor, with real physical partitions.
 for z: float in [-12.5,-7.0]: _box(Vector3(-34,5.25,z),Vector3(0.2,3.3,3.0),walls)
 _box(Vector3(-38,5.25,-14),Vector3(8,3.3,0.2),walls)
 _box(Vector3(-38,5.25,-5.5),Vector3(8,3.3,0.2),walls)
 _box(Vector3(-38,4.0,-11),Vector3(4,0.8,2.2),Color(0.62,0.58,0.48),false)
 _box(Vector3(-38,4.45,-11.7),Vector3(4,0.15,0.6),Color(0.83,0.80,0.70),false)
 _box(Vector3(-40,4.05,-7),Vector3(1.3,0.9,0.8),dark,false)
 _box(Vector3(-39,3.63,-8.7),Vector3(4,0.04,2),Color(0.33,0.20,0.18),false)
 # Upper guest gallery and lower dining / service lounge.
 for x: float in [-38.0,-30.0,-22.0,-15.0]:
  for y: float in [2.95,6.85]:
   _box(Vector3(x,y,0),Vector3(2,0.06,0.22),Color(0.90,0.76,0.53),false)
  for z: float in [-15.7,15.7]:
   _box(Vector3(x,4.9,z),Vector3(2.1,1.8,0.06),dark,false)
   _box(Vector3(x,4.9,z + (0.04 if z < 0 else -0.04)),Vector3(1.7,1.35,0.04),Color(0.42,0.39,0.31),false)
 for x: float in [-38.0,-31.0,-24.0,-17.0]:
  _box(Vector3(x,0.45,-10),Vector3(2.4,0.9,1.3),dark,false)
  _box(Vector3(x,0.95,-10),Vector3(2.5,0.12,1.4),Color(0.65,0.57,0.46),false)
  for z: float in [-11.5,-8.5]:
   _box(Vector3(x,0.35,z),Vector3(1.2,0.7,0.55),Color(0.22,0.30,0.29),false)
 for x: float in [-38.0,-30.0,-22.0,-15.0]:
  _box(Vector3(x,0.4,11),Vector3(2.3,0.8,0.8),Color(0.23,0.33,0.32),false)
  _box(Vector3(x,0.8,11.3),Vector3(2.3,0.7,0.15),Color(0.20,0.28,0.28),false)
 _box(Vector3(-27,7.1,0),Vector3(30,0.2,32),Color(0.32,0.32,0.30),false)
 _box(Vector3(0,7.1,0),Vector3(24,0.2,16),Color(0.32,0.32,0.30),false)
 # Navigation on the original floor remains untouched; the stationary target
 # receives a separate upper region. NPCs do not yet route across the ramp.
 var region := NavigationRegion3D.new()
 var nav := NavigationMesh.new()
 nav.vertices = PackedVector3Array([Vector3(-41.5,3.6,-15.5),Vector3(-12.5,3.6,-15.5),Vector3(-12.5,3.6,15.5),Vector3(-41.5,3.6,15.5)])
 nav.add_polygon(PackedInt32Array([0,3,2,1]))
 region.navigation_mesh = nav
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
 var mat := StandardMaterial3D.new()
 mat.roughness = 0.72
 if kind == "clue":
  mesh.size = Vector3(0.5, 0.07, 0.34)
  mat.albedo_color = Color(0.65, 0.48, 0.29)
  visual.position.y = 0.81
  if id in ["archive", "sensor_log"]:
   mesh.size = Vector3(0.52,0.34,0.06)
   visual.position.y = 1.05
   mat.albedo_color = Color(0.12,0.18,0.19)
 elif kind == "disguise":
  mesh.size = Vector3(0.48, 0.65, 0.20)
  mat.albedo_color = Color(0.24, 0.36, 0.42)
  visual.position.y = 0.7
 elif kind == "extract":
  mesh.size = Vector3(0.70, 0.025, 0.70)
  mat.albedo_color = Color(0.40, 0.65, 0.46)
  visual.position.y = 0.025
 elif kind in ["primary", "target"]:
  mesh.size = Vector3(0.2, 0.025, 0.2)
  mat.albedo_color = color
  visual.visible = false
 else:
  mesh.size = Vector3(0.55, 0.55, 0.55)
  mat.albedo_color = color
  visual.position.y = 0.4
 visual.mesh = mesh
 visual.material_override = mat
 object.add_child(visual)
 if kind == "clue":
  # Folder, layered paper and ink lines sit on a small desk-like surface.
  if id in ["archive", "sensor_log"]:
   _pickup_detail(visual, Vector3(0,0,-0.04), Vector3(0.43,0.25,0.015), Color(0.22,0.45,0.45))
   _pickup_detail(visual, Vector3(0,-0.24,0), Vector3(0.06,0.18,0.06), Color(0.18,0.22,0.22))
  else:
   _pickup_detail(visual, Vector3(0, 0.05, 0), Vector3(0.42,0.03,0.27), Color(0.87,0.84,0.72))
   for z: float in [-0.08, -0.02, 0.04]:
    _pickup_detail(visual, Vector3(0,0.071,z), Vector3(0.27,0.005,0.01), Color(0.24,0.25,0.24))
  _box(pos + Vector3(0,0.38,0), Vector3(0.9,0.76,0.65), Color(0.30,0.23,0.18), false)
 elif kind == "disguise":
  for x: float in [-0.29,0.29]: _pickup_detail(visual, Vector3(x,0,0), Vector3(0.16,0.58,0.18), Color(0.24,0.36,0.42))
  _pickup_detail(visual, Vector3(0,0.1,-0.11), Vector3(0.08,0.3,0.02), Color(0.78,0.77,0.72))
 object.activated.connect(_on_interaction)
 interactables.append(object)

func _pickup_detail(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
 var part := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 part.mesh = mesh
 part.position = pos
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.8
 part.material_override = mat
 parent.add_child(part)

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
  marker_visual.position.y = 2.05
  marker_visual.scale = Vector3.ONE * 0.35

func _build_ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 var overlay := Control.new()
 overlay.theme = BlacklineTheme.create()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(overlay)
 # Original restrained HUD: only mission-derived information, no invented health.
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.025, 0.04, 0.05, 0.64)
 style.content_margin_left = 12
 style.content_margin_right = 12
 style.content_margin_top = 6
 style.content_margin_bottom = 6
 var objective := PanelContainer.new()
 objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
 objective.offset_left = -300
 objective.offset_right = 300
 objective.offset_top = 18
 objective.offset_bottom = 76
 objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
 objective.add_theme_stylebox_override("panel", style)
 overlay.add_child(objective)
 hud = Label.new()
 hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 hud.add_theme_font_size_override("font_size", 16)
 objective.add_child(hud)
 var right := PanelContainer.new()
 right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
 right.offset_left = -245
 right.offset_right = -20
 right.offset_top = -80
 right.offset_bottom = -20
 right.mouse_filter = Control.MOUSE_FILTER_IGNORE
 right.add_theme_stylebox_override("panel", style.duplicate())
 overlay.add_child(right)
 equipment_hud = Label.new()
 equipment_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 equipment_hud.add_theme_font_size_override("font_size", 17)
 right.add_child(equipment_hud)
 var bottom := PanelContainer.new()
 prompt_panel = bottom
 bottom.position = Vector2(20, 22)
 bottom.custom_minimum_size = Vector2(300, 0)
 bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bottom.add_theme_stylebox_override("panel", style.duplicate())
 overlay.add_child(bottom)
 awareness_hud = Label.new()
 awareness_hud.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
 awareness_hud.offset_left = 24
 awareness_hud.offset_top = -70
 awareness_hud.offset_right = 420
 awareness_hud.offset_bottom = -20
 awareness_hud.add_theme_font_size_override("font_size", 16)
 awareness_hud.add_theme_color_override("font_shadow_color", Color.BLACK)
 awareness_hud.add_theme_constant_override("shadow_offset_x", 2)
 awareness_hud.add_theme_constant_override("shadow_offset_y", 2)
 overlay.add_child(awareness_hud)
 crosshair = preload("res://scripts/ui/aim_reticle.gd").new()
 crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
 crosshair.set_anchors_preset(Control.PRESET_CENTER)
 crosshair.offset_left = -20
 crosshair.offset_right = 20
 crosshair.offset_top = -20
 crosshair.offset_bottom = 20
 crosshair.visible = false
 overlay.add_child(crosshair)
 interaction_dot = Label.new()
 interaction_dot.text = "·"
 interaction_dot.set_anchors_preset(Control.PRESET_CENTER)
 interaction_dot.offset_left = -5
 interaction_dot.offset_right = 5
 interaction_dot.offset_top = -14
 interaction_dot.offset_bottom = 14
 interaction_dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 interaction_dot.visible = false
 overlay.add_child(interaction_dot)
 instinct_label = Label.new()
 instinct_label.text = "INSTINCT  /  ACTIVE"
 instinct_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
 instinct_label.offset_left = 24
 instinct_label.offset_top = -98
 instinct_label.offset_right = 260
 instinct_label.offset_bottom = -75
 instinct_label.add_theme_font_size_override("font_size", 15)
 instinct_label.modulate = Color(0.95, 0.82, 0.5)
 instinct_label.visible = false
 overlay.add_child(instinct_label)
 fps_label = Label.new()
 fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 fps_label.offset_left = -100
 fps_label.offset_right = -20
 fps_label.offset_top = 20
 fps_label.offset_bottom = 45
 fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 overlay.add_child(fps_label)
 shot_audio = AudioStreamPlayer.new()
 shot_audio.stream = ProceduralSound.tone(180.0, 0.12, 0.14)
 add_child(shot_audio)
 objective_audio = AudioStreamPlayer.new()
 objective_audio.stream = ProceduralSound.tone(440.0, 0.20, 0.05)
 add_child(objective_audio)
 mission.changed.connect(objective_audio.play)
 ambience_audio = AudioStreamPlayer.new()
 ambience_audio.stream = ProceduralSound.tone(55.0 if mission_id() == "initiation" else 45.0, 1.0, 0.012, true)
 add_child(ambience_audio)
 ambience_audio.play()
 prompt = Label.new()
 prompt.add_theme_font_size_override("font_size", 16)
 prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 prompt.custom_minimum_size.x = 280
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
   if distance < best and not npc.objective_completed and npc.stunned_time <= 0 and _clear_reach(npc.global_position, 1.8, npc.get_rid()):
    nearest = npc
    best = distance
  if nearest:
   nearest.incapacitate(12.0)
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
 var screen_center := player.camera.get_viewport().get_visible_rect().size * 0.5
 var origin := player.camera.project_ray_origin(screen_center)
 # A shoulder camera cannot fire from the far side of a wall when the
 # character is still behind it. The shot itself remains the centre ray.
 var eye := player.global_position + Vector3.UP * (player.stance_height * 0.8)
 var camera_clearance := PhysicsRayQueryParameters3D.create(eye, origin)
 camera_clearance.exclude = [player.get_rid()]
 if not get_world_3d().direct_space_state.intersect_ray(camera_clearance).is_empty():
  message = "Camera obstructed. Move to get a clear shot."
  return
 player.equipment.charges -= 1
 player.shot_feedback()
 var direction := player.camera.project_ray_normal(screen_center)
 var end := origin + direction * 50.0
 var query := PhysicsRayQueryParameters3D.create(origin, end)
 query.exclude = [player.get_rid()]
 query.collide_with_areas = true
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 var confirmed_hit := false
 if not hit.is_empty():
  end = hit["position"]
  _impact_flash(end)
  var collider: Object = hit["collider"]
  if collider is Area3D and collider.get_parent() is Interactable:
   var object := collider.get_parent() as Interactable
   if object.kind == "robot" and not object.used:
    _on_interaction(object)
    confirmed_hit = true
   else: message = "Assessment pulse hit an inactive unit."
  elif collider is HotelNpc:
   var npc := collider as HotelNpc
   confirmed_hit = true
   if npc.objective_completed:
    message = "Target objective already complete."
   elif npc == primary_npc and mission.mark_target(str(mission.primary_target.get("id", "")), true):
    npc.complete_objective(true)
    for obj: Interactable in interactables:
     if obj.kind == "primary":
      obj.used = true
      obj.visible = false
    message = "Ruby: Locke tagged for Blackline follow-up."
   else:
    npc.incapacitate(12.0)
    message = "Assessment pulse temporarily incapacitated " + npc.profile.identity + "."
  else: message = "Assessment pulse struck a surface."
 else: message = "Assessment pulse discharged."
 if confirmed_hit: crosshair.call("confirm_hit")
 for npc: HotelNpc in npcs:
  if npc.stunned_time <= 0 and npc.global_position.distance_to(player.global_position) < 9.0:
   npc.observe_trespass(player.global_position)
 last_shot_start = origin
 last_shot_end = end
 shot_audio.play()
 _shot_trace(origin, end)

func _impact_flash(point: Vector3) -> void:
 var flash := MeshInstance3D.new()
 var mesh := SphereMesh.new()
 mesh.radius = 0.09
 mesh.height = 0.18
 flash.mesh = mesh
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color = Color(0.7, 0.95, 1.0)
 flash.material_override = material
 add_child(flash)
 flash.global_position = point
 var tween := create_tween()
 tween.tween_interval(0.13)
 tween.tween_callback(flash.queue_free)

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
 # The primary identity is provided by the briefing. Draw its actual mesh even
 # behind opaque walls; ordinary NPCs and unknown items never use this pass.
 instinct_red.no_depth_test = true
 instinct_red.render_priority = 1
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
 instinct_strength = 1.0 if player.instinct_active else 0.0
 instinct_label.visible = player.instinct_active
 instinct_red.albedo_color.a = instinct_strength * 0.9
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
    if object.get_parent() is HotelNpc: (object.get_parent() as HotelNpc).complete_objective(false)
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
 var local_state := "NO LOCAL ALERT"
 for npc: HotelNpc in npcs:
  if npc.suspicion > highest and _clear_reach(npc.global_position, 9.0, npc.get_rid()):
   highest = npc.suspicion
   local_state = "INVESTIGATING" if npc.state == "investigating" else "SUSPICIOUS"
 var target := "ASSESSMENT UNIT" if mission_id() == "initiation" else "ADRIAN LOCKE"
 hud.text = target + "  /  " + mission.objective_text() + "\n" + "RECORDS  %d / %d  ·  REQUIRED %d" % [mission.clues.size(), mission.available_records.size(), mission.required_records]
 awareness_hud.text = "%s  /  %s\n%s" % [area.to_upper(), access, local_state]
 fps_label.visible = Campaign.settings["show_fps"]
 fps_label.text = "%d FPS" % Engine.get_frames_per_second()
 equipment_hud.text = Campaign.item_label(player.equipment.selected).to_upper()
 if player.equipment.selected == "training_sidearm": equipment_hud.text += "\nCHARGES  %d / 5" % player.equipment.charges
 crosshair.visible = player.aiming
 var nearest := _nearest()
 interaction_dot.visible = nearest != null and not player.aiming
 if message != last_message:
  last_message = message
  message_remaining = 7.0
 message_remaining = maxf(0.0, message_remaining - _delta)
 var current_message := message if message_remaining > 0.0 else ""
 prompt.text = ("E  /  " + nearest.label + ("\n" if not current_message.is_empty() else "") if nearest else "") + current_message
 prompt_panel.visible = not prompt.text.strip_edges().is_empty()
 prompt_panel.modulate.a = move_toward(prompt_panel.modulate.a, 1.0 if prompt_panel.visible else 0.0, _delta * 6.0)
