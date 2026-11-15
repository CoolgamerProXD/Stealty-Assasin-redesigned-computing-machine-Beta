extends "res://scripts/world/tung_chung_preview.gd"
## Original explorable landscape studies, separate from campaign progression.
@export_enum("city", "mountain") var preview_kind: String = "city"

func _ready() -> void:
 _environment()
 if preview_kind == "city": _city()
 else: _mountain()
 player = HotelPlayer.new()
 player.position = Vector3(0,0.05,20)
 add_child(player)
 player.mouse_sensitivity = float(Campaign.settings["sensitivity"])
 var canvas := CanvasLayer.new()
 add_child(canvas)
 hud = Label.new()
 hud.position = Vector2(24,20)
 hud.add_theme_font_size_override("font_size", 20)
 hud.add_theme_color_override("font_shadow_color", Color.BLACK)
 hud.add_theme_constant_override("shadow_offset_x", 2)
 hud.add_theme_constant_override("shadow_offset_y", 2)
 canvas.add_child(hud)

func _process(_delta: float) -> void:
 var title := "HONG KONG  /  CITY SANDBOX" if preview_kind == "city" else "NGONG PING  /  TIAN TAN BUDDHA"
 hud.text = title + "  —  EXPLORATION PREVIEW\nWASD MOVE   ·   MOUSE LOOK   ·   ESC MAP SELECTION"

func _ground(color: Color) -> void:
 _box(Vector3(0,-0.2,0), Vector3(90,0.4,90), color, true)
 for x: float in [-45.0,45.0]: _box(Vector3(x,2,0),Vector3(0.3,4,90),color.darkened(0.2),true)
 for z: float in [-45.0,45.0]: _box(Vector3(0,2,z),Vector3(90,4,0.3),color.darkened(0.2),true)

func _city() -> void:
 _ground(Color(0.34,0.36,0.36))
 var road := Color(0.20,0.23,0.25)
 var pale := Color(0.76,0.68,0.52)
 var dark := Color(0.18,0.25,0.27)
 _box(Vector3(0,0.02,0),Vector3(11,0.04,88),road)
 _box(Vector3(0,0.025,0),Vector3(88,0.04,10),road)
 for z: float in [-36.0,-24.0,-12.0,0.0,12.0,24.0,36.0]:
  _box(Vector3(0,0.06,z),Vector3(0.16,0.03,4),pale)
 # Blocks with open passages around them form a connected set of streets.
 for x: float in [-31.0,-17.0,17.0,31.0]:
  for z: float in [-30.0,-16.0,16.0,30.0]:
   var h := 6.0 + absf(x + z) * 0.09
   var building := Color(0.42+absf(x)*0.002,0.44,0.42+absf(z)*0.002)
   _box(Vector3(x,h/2,z),Vector3(10,h,9),building,true)
   for level: int in range(1,3):
    for dx: float in [-3.0,0.0,3.0]:
     _box(Vector3(x+dx,2.0+level*2.0,z+4.54),Vector3(1.6,1.2,0.06),Color(0.22,0.34,0.38))
   _box(Vector3(x,0.3,z+4.9),Vector3(10,0.6,0.8),dark)
 # Market stalls, pedestrian streets and waterfront promenade.
 for x: float in [-30.0,-24.0,-18.0,-12.0]:
  _box(Vector3(x,0.55,8),Vector3(3.8,1.1,1.8),Color(0.38,0.25,0.17))
  _box(Vector3(x,2.2,8),Vector3(4.1,0.12,2.4),Color(0.67,0.25,0.18))
  for side: float in [-1.7,1.7]: _box(Vector3(x+side,1.3,8),Vector3(0.1,2.5,0.1),dark)
 _sign("MARKET STREET",Vector3(-21,3.0,5),38)
 _sign("COMMERCIAL DISTRICT",Vector3(18,3.0,-6),38)
 _sign("BACKSTREETS",Vector3(-21,3.0,-8),38)
 _box(Vector3(0,0.03,-40),Vector3(84,0.06,5),Color(0.27,0.38,0.40))
 _box(Vector3(0,0.03,-43),Vector3(84,0.06,3),Color(0.14,0.30,0.38))
 _sign("HARBOUR PROMENADE",Vector3(0,3,-37),38)
 for x: float in [-35.0,-25.0,-15.0,-5.0,5.0,15.0,25.0,35.0]:
  _box(Vector3(x,1.4,-38),Vector3(0.12,2.8,0.12),dark)
  _box(Vector3(x,2.85,-38),Vector3(0.7,0.1,0.7),Color(0.95,0.80,0.58))

func _mountain() -> void:
 _ground(Color(0.36,0.46,0.34))
 var stone := Color(0.61,0.60,0.53)
 var red := Color(0.42,0.17,0.14)
 var dark := Color(0.22,0.24,0.20)
 # Broad public approach. The statue is a non-destructible landmark.
 _box(Vector3(0,0.03,0),Vector3(11,0.06,80),stone)
 _box(Vector3(0,0.06,-22),Vector3(26,0.12,18),stone.lightened(0.08))
 for x: float in [-22.0,-14.0,14.0,22.0]:
  _box(Vector3(x,1.5,13),Vector3(7,3,7),Color(0.65,0.53,0.39),true)
  _box(Vector3(x,3.2,13),Vector3(8,0.4,8),red)
  _box(Vector3(x,1.5,9.44),Vector3(5,1.7,0.05),Color(0.25,0.35,0.32))
 _sign("VILLAGE APPROACH",Vector3(0,3.2,12),38)
 _box(Vector3(0,0.7,-29),Vector3(12,1.4,9),Color(0.42,0.39,0.33),true)
 _box(Vector3(0,1.55,-29),Vector3(8,0.3,6),Color(0.64,0.53,0.36))
 # Stylised seated figure: original abstract forms, not a destructive element.
 _box(Vector3(0,2.2,-29),Vector3(5,1.0,3),Color(0.38,0.31,0.23))
 _box(Vector3(0,3.3,-29),Vector3(3.1,2.2,1.8),Color(0.43,0.35,0.25))
 var head := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 0.75
 sphere.height = 1.5
 head.mesh = sphere
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.47,0.38,0.27)
 material.roughness = 0.9
 head.material_override = material
 head.position = Vector3(0,5.0,-29)
 add_child(head)
 for x: float in [-30.0,-20.0,-12.0,12.0,20.0,30.0]:
  for z: float in [-33.0,-17.0,0.0,26.0,36.0]:
   _box(Vector3(x,1.1,z),Vector3(0.45,2.2,0.45),Color(0.28,0.22,0.14))
   _box(Vector3(x,2.7,z),Vector3(2.8,2.4,2.8),Color(0.19,0.36,0.22))
 # Distant, stylised peaks, and an atmospheric decorative cable-car vista.
 for x: float in [-38.0,-26.0,26.0,38.0]:
  _box(Vector3(x,5,-41),Vector3(16,10,4),Color(0.27,0.37,0.35))
 _box(Vector3(0,8,30),Vector3(80,0.07,0.07),dark)
 for x: float in [-20.0,10.0,32.0]:
  _box(Vector3(x,6.3,30),Vector3(2.0,2.3,1.8),Color(0.66,0.26,0.18))
  _box(Vector3(x,6.6,29.08),Vector3(1.6,1.1,0.05),Color(0.30,0.46,0.48))
  _box(Vector3(x,7.8,30),Vector3(0.12,0.7,0.12),dark)
