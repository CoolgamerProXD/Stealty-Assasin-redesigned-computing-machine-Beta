extends Node3D
## Exploratory, fictional station blockout. This is not a campaign mission.
var player: HotelPlayer
var npcs: Array[HotelNpc] = []
var robber: HotelNpc
var operative: HotelNpc
var hud: Label
var message: String = "SCOUTING PREVIEW  /  Approach the two distinctive people. Escape returns to the menu."
var materials: Dictionary = {}

func _ready() -> void:
 _environment()
 _start_ambience("station")
 _station()
 player = HotelPlayer.new()
 player.position = Vector3(-19, 0.05, 4)
 add_child(player)
 player.mouse_sensitivity = float(Campaign.settings["sensitivity"])
 player.interaction_requested.connect(_interact)
 _population()
 var canvas := CanvasLayer.new()
 add_child(canvas)
 hud = Label.new()
 hud.position = Vector2(24, 20)
 hud.custom_minimum_size = Vector2(750, 0)
 hud.add_theme_font_size_override("font_size", 20)
 hud.add_theme_color_override("font_shadow_color", Color.BLACK)
 hud.add_theme_constant_override("shadow_offset_x", 2)
 hud.add_theme_constant_override("shadow_offset_y", 2)
 canvas.add_child(hud)

func _start_ambience(kind: String) -> void:
 var ambience := AudioStreamPlayer.new()
 ambience.name = "LocationAmbience"
 ambience.stream = ProceduralSound.ambience(kind)
 add_child(ambience)
 ambience.play()

func footstep_surface(_point: Vector3) -> String:
 return "stone"

func _environment() -> void:
 var env := WorldEnvironment.new()
 var data := Environment.new()
 data.background_mode = Environment.BG_COLOR
 data.background_color = Color(0.11, 0.17, 0.22)
 data.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 data.ambient_light_color = Color(0.75, 0.82, 0.85)
 data.ambient_light_energy = 0.9
 env.environment = data
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55, -25, 0)
 sun.light_energy = 0.85
 sun.shadow_enabled = Campaign.settings["graphics"] != "LOW"
 sun.add_to_group("quality_lights")
 add_child(sun)
 var nav := NavigationRegion3D.new()
 var mesh := NavigationMesh.new()
 mesh.vertices = PackedVector3Array([Vector3(-21,0,-13), Vector3(21,0,-13), Vector3(21,0,13), Vector3(-21,0,13)])
 mesh.add_polygon(PackedInt32Array([0,3,2,1]))
 nav.navigation_mesh = mesh
 add_child(nav)

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> void:
 var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
 holder.position = pos
 add_child(holder)
 var part := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 part.mesh = mesh
 if not materials.has(color):
  var material := StandardMaterial3D.new()
  material.albedo_color = color
  material.roughness = 0.78
  materials[color] = material
 part.material_override = materials[color]
 holder.add_child(part)
 if solid:
  var collider := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  collider.shape = shape
  holder.add_child(collider)

func _sign(text: String, pos: Vector3, size: int = 38) -> void:
 var label := Label3D.new()
 label.text = text
 label.position = pos
 label.font_size = size
 label.pixel_size = 0.004
 label.modulate = Color(0.94, 0.95, 0.9)
 label.no_depth_test = false
 add_child(label)

func _station() -> void:
 var floor_color := Color(0.51, 0.56, 0.55)
 var wall := Color(0.58, 0.64, 0.65)
 var dark := Color(0.15, 0.22, 0.25)
 var orange := Color(0.88, 0.49, 0.19)
 _box(Vector3(0,-0.2,0), Vector3(44,0.4,28), floor_color, true)
 _box(Vector3(0,5.3,0), Vector3(44,0.25,28), Color(0.36,0.42,0.43))
 _box(Vector3(0,2.6,-14), Vector3(44,5.2,0.3), wall, true)
 _box(Vector3(-22,2.6,0), Vector3(0.3,5.2,28), wall, true)
 _box(Vector3(22,2.6,0), Vector3(0.3,5.2,28), wall, true)
 _box(Vector3(0,2.6,14), Vector3(44,5.2,0.3), wall, true)
 # Rhythm of columns, floor strips and ceiling lights establishes the concourse.
 for x: float in [-18.0,-10.0,-2.0,6.0,14.0]:
  for z: float in [-6.0,6.0]:
   _box(Vector3(x,2.6,z), Vector3(0.6,5.2,0.6), Color(0.76,0.79,0.76), true)
   _box(Vector3(x,0.35,z), Vector3(0.8,0.7,0.8), dark)
  _box(Vector3(x,5.1,0), Vector3(4.8,0.05,0.3), Color(1.0,0.91,0.72))
 for x: float in [-14.0,-7.0,0.0,7.0,14.0]:
  _box(Vector3(x,0.015,0), Vector3(0.04,0.03,26), Color(0.40,0.46,0.46))
 _box(Vector3(-15,1.1,-11.5), Vector3(8,2.2,2), dark)
 _box(Vector3(-15,1.35,-10.45), Vector3(7.5,0.12,0.12), orange)
 _sign("TICKETS  /  CUSTOMER SERVICE", Vector3(-15,2.65,-10.35), 32)
 for x: float in [-19.0,-17.5,-16.0,-14.5]:
  _box(Vector3(x,0.6,-8.5), Vector3(0.75,1.2,0.55), Color(0.24,0.35,0.37))
  _box(Vector3(x,1.23,-8.5), Vector3(0.6,0.07,0.45), orange)
 # Shops are scenic frontages, not claimed as usable interiors.
 for x: float in [-3.0,4.0,11.0]:
  _box(Vector3(x,1.7,-12.6), Vector3(6,3.4,2.2), Color(0.26,0.31,0.30))
  _box(Vector3(x,1.5,-11.42), Vector3(5.3,2.1,0.06), Color(0.32,0.49,0.49))
  _box(Vector3(x,3.0,-11.35), Vector3(5.5,0.45,0.08), dark)
 _sign("PAPER & PRESS", Vector3(-3,3,-11.28), 30)
 _sign("TEA HOUSE", Vector3(4,3,-11.28), 30)
 _sign("MARKET", Vector3(11,3,-11.28), 30)
 # Fictional, decorative escalator and mezzanine; neither represents railway access.
 _box(Vector3(17,3.2,-6), Vector3(8,0.35,4), Color(0.39,0.47,0.47))
 _box(Vector3(17,3.9,-3.95), Vector3(8,1.1,0.12), Color(0.31,0.47,0.49))
 for i: int in range(11):
  _box(Vector3(14.5, float(i)*0.29+0.1, 1.0-float(i)*0.44), Vector3(2.4,0.18,0.46), Color(0.34,0.39,0.38))
  _box(Vector3(13.25,float(i)*0.29+0.7,1.0-float(i)*0.44), Vector3(0.08,0.12,0.47), dark)
  _box(Vector3(15.75,float(i)*0.29+0.7,1.0-float(i)*0.44), Vector3(0.08,0.12,0.47), dark)
 _sign("CONCOURSE  /  UPPER WALKWAY", Vector3(17,4.65,-3.85), 28)
 # The information island is solid; seating remains decorative.
 _box(Vector3(-1,0.55,0), Vector3(5,1.1,2), Color(0.26,0.36,0.38), true)
 _box(Vector3(-1,1.15,0), Vector3(5.2,0.12,2.2), Color(0.76,0.75,0.66))
 _sign("INFORMATION", Vector3(-1,2.6,0.5), 36)
 for x: float in [5.0,9.0,13.0]:
  _box(Vector3(x,0.5,5), Vector3(2.7,0.15,0.8), Color(0.30,0.29,0.25))
  _box(Vector3(x,0.8,5.4), Vector3(2.7,0.65,0.12), Color(0.30,0.29,0.25))
  for side: float in [-0.9,0.9]: _box(Vector3(x+side,0.22,5), Vector3(0.12,0.5,0.55), dark)
 # Fictional platform edge and stationary train facade; no rail-access mechanics.
 _box(Vector3(0,0.025,10.7), Vector3(43,0.05,0.25), Color(0.95,0.75,0.20))
 _box(Vector3(0,1.7,12.6), Vector3(38,3.4,1.3), Color(0.75,0.78,0.76), true)
 _box(Vector3(0,1.8,11.92), Vector3(37,1.0,0.05), dark)
 for x: float in [-16.0,-12.0,-8.0,-4.0,0.0,4.0,8.0,12.0,16.0]:
  _box(Vector3(x,1.8,11.87), Vector3(2.3,0.75,0.06), Color(0.31,0.44,0.47))
 _box(Vector3(0,0.65,11.9), Vector3(38,0.12,0.06), orange)
 _box(Vector3(1,4.2,8), Vector3(9,0.8,0.2), dark)
 _sign("PLATFORM  /  TRAINS", Vector3(1,4.2,7.86), 40)
 # Non-operational architectural details; routes are not real station layouts.
 for x: float in [-18.0,-10.0,-2.0,6.0,14.0]:
  _box(Vector3(x,5.12,-4), Vector3(0.24,0.18,17), Color(0.25,0.31,0.31))
  _box(Vector3(x,3.0,-13.82), Vector3(5.0,0.05,0.05), orange)
  _box(Vector3(x,0.08,0), Vector3(0.04,0.04,19), Color(0.64,0.68,0.64))
 for x: float in [-9.0,-5.0,2.0,6.0,9.0,13.0]:
  _box(Vector3(x,2.4,-11.34),Vector3(1.1,0.58,0.025),Color(0.84,0.72,0.50))
  _box(Vector3(x,2.4,-11.30),Vector3(0.96,0.44,0.02),Color(0.26,0.39,0.37))
 for x: float in [-17.0,-9.0,-1.0,7.0,15.0]:
  _box(Vector3(x,1.0,11.83),Vector3(0.035,1.9,0.035),Color(0.92,0.65,0.27))
  _box(Vector3(x,2.9,11.83),Vector3(0.8,0.10,0.035),Color(0.92,0.65,0.27))


func _population() -> void:
 var coats: Array[Color] = [Color(0.55,0.31,0.24), Color(0.25,0.36,0.46), Color(0.42,0.44,0.30), Color(0.48,0.36,0.46), Color(0.28,0.45,0.42), Color(0.60,0.52,0.38), Color(0.31,0.32,0.35)]
 for i: int in range(14):
  var profile := NpcProfile.new()
  profile.identity = "Passenger %02d" % i
  profile.occupation = "employee" if i % 5 == 0 else "civilian"
  var start := Vector3(-17 + float(i % 7) * 5.5, 0.05, -3.0 + float(i / 7) * 11.5)
  # Keep adjacent local routines disjoint so passengers do not walk
  # directly into each other on the broad, unbaked station navmesh.
  var end := Vector3(clampf(start.x + (1.7 if i % 2 == 0 else -1.7), -19, 19), 0.05, start.z)
  profile.schedule.append(ScheduleEntry.new(end, "waiting" if i % 3 == 0 else "conversing", 3.0 + float(i % 4)))
  profile.schedule.append(ScheduleEntry.new(start, "idle", 2.0 + float(i % 3)))
  var npc := HotelNpc.new()
  npc.profile = profile
  npc.position = start
  add_child(npc)
  npc.person.clothing.albedo_color = coats[i % coats.size()]
  npcs.append(npc)
 robber = _target("Station suspect", "manager", Vector3(-12,0.05,-5), Vector3(-7,0.05,-5))
 operative = _target("Unidentified operative", "security", Vector3(10,0.05,-5), Vector3(15,0.05,-5))

func _target(identity: String, role: String, start: Vector3, end: Vector3) -> HotelNpc:
 var profile := NpcProfile.new()
 profile.identity = identity
 profile.occupation = role
 profile.schedule.append(ScheduleEntry.new(end, "waiting", 5.0))
 profile.schedule.append(ScheduleEntry.new(start, "idle", 4.0))
 var npc := HotelNpc.new()
 npc.profile = profile
 npc.position = start
 add_child(npc)
 npcs.append(npc)
 return npc

func _interact() -> void:
 if player.global_position.distance_to(robber.global_position) < 2.0:
  message = "SCOUTING  /  A sharply dressed suspect moves between ticketing and the concourse."
 elif player.global_position.distance_to(operative.global_position) < 2.0:
  message = "SCOUTING  /  A watchful operative keeps an eye on the platform."
 else:
  message = "SCOUTING PREVIEW  /  Approach either distinctive person and press E."

func _process(_delta: float) -> void:
 hud.text = "TUNG CHUNG  /  EARLY MAP PREVIEW\n" + message + "\nWASD MOVE   ·   E OBSERVE   ·   ESC RETURN"

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("release_mouse"):
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  Campaign.return_to_maps = true
  get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
