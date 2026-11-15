extends "res://scripts/world/tung_chung_preview.gd"
## Original explorable landscape studies, separate from campaign progression.
@export_enum("city", "mountain") var preview_kind: String = "city"
var accents: Array[Transform3D] = []
var accent_colors: Array[Color] = []
var canopy_transforms: Array[Transform3D] = []

func _ready() -> void:
 _environment()
 if preview_kind == "city": _city()
 else: _mountain()
 _flush_accents()
 _flush_canopies()
 _scene_population()
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

func _accent(pos: Vector3, size: Vector3, color: Color) -> void:
 accents.append(Transform3D(Basis.IDENTITY.scaled(size),pos))
 accent_colors.append(color)

func _flush_accents() -> void:
 if accents.is_empty(): return
 var multi := MultiMesh.new()
 multi.transform_format = MultiMesh.TRANSFORM_3D
 multi.use_colors = true
 var mesh := BoxMesh.new()
 var material := StandardMaterial3D.new()
 material.vertex_color_use_as_albedo = true
 material.roughness = 0.82
 mesh.material = material
 multi.mesh = mesh
 multi.instance_count = accents.size()
 for i: int in range(accents.size()):
  multi.set_instance_transform(i, accents[i])
  multi.set_instance_color(i, accent_colors[i])
 var visual := MultiMeshInstance3D.new()
 visual.name = "DistrictDetails"
 visual.multimesh = multi
 visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(visual)

func _flush_canopies() -> void:
 if canopy_transforms.is_empty(): return
 var multi := MultiMesh.new()
 multi.transform_format = MultiMesh.TRANSFORM_3D
 var mesh := SphereMesh.new()
 mesh.radius = 0.5
 mesh.height = 1.0
 mesh.radial_segments = 8
 mesh.rings = 4
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.22,0.39,0.23)
 material.roughness = 0.95
 mesh.material = material
 multi.mesh = mesh
 multi.instance_count = canopy_transforms.size()
 for i: int in range(canopy_transforms.size()): multi.set_instance_transform(i,canopy_transforms[i])
 var trees := MultiMeshInstance3D.new()
 trees.name = "TreeCanopies"
 trees.multimesh = multi
 trees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(trees)

# Fictional accessible upper walkway; it is not connected to the NPC navmesh.
func _city_walkway() -> void:
 var ramp := StaticBody3D.new()
 ramp.name = "CityWalkwayRamp"
 ramp.position = Vector3(12,1.10,0)
 ramp.rotation.z = atan(2.4 / 6.0)
 add_child(ramp)
 var size := Vector3(6.5,0.2,2.8)
 var mesh := BoxMesh.new()
 mesh.size = size
 var visual := MeshInstance3D.new()
 visual.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.38,0.40,0.38)
 material.roughness = 0.88
 visual.material_override = material
 ramp.add_child(visual)
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collider.shape = shape
 ramp.add_child(collider)
 for z: float in [-1.35,1.35]:
  var rail := MeshInstance3D.new()
  var rail_mesh := BoxMesh.new()
  rail_mesh.size = Vector3(6.5,0.08,0.08)
  rail.mesh = rail_mesh
  rail.position = Vector3(0,0.9,z)
  rail.material_override = material
  ramp.add_child(rail)
 # The terrace overlaps the ramp slightly below its high end, so the
 # character capsule does not collide with a raised vertical lip on ascent.
 _box(Vector3(19,2.0,0),Vector3(8.5,0.3,8),Color(0.44,0.45,0.41),true)
 for z: float in [-4.0,4.0]:
  _box(Vector3(19,2.70,z),Vector3(8.5,1.1,0.10),Color(0.25,0.32,0.32),true)
 _box(Vector3(23.2,2.70,0),Vector3(0.10,1.1,8),Color(0.25,0.32,0.32),true)
 _sign("PUBLIC WALKWAY", Vector3(16.5,4.2,-3.8),30)

# Gently rolling terrain meshes meet the surrounding ground at their edges.
# Physics uses the same triangles as the visible terrain, not a flat fake floor.
func _terrain_patch(x0: float, z0: float, width: float, depth: float, height: float) -> void:
 var divisions := 12
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for ix: int in range(divisions):
  for iz: int in range(divisions):
   var points: Array[Vector3] = []
   for corner: Vector2i in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(1,0)]:
    var u := float(ix+corner.x)/float(divisions)
    var v := float(iz+corner.y)/float(divisions)
    var y := maxf(0.0, sin(PI*u) * sin(PI*v)) * height
    points.append(Vector3(x0+u*width,y,z0+v*depth))
   for point: Vector3 in points: surface.add_vertex(point)
 surface.generate_normals()
 var mesh := surface.commit()
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.31,0.43,0.30)
 material.roughness = 1.0
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 var body := StaticBody3D.new()
 body.name = "MountainTerrain"
 add_child(body)
 var visual := MeshInstance3D.new()
 visual.mesh = mesh
 visual.material_override = material
 body.add_child(visual)
 var collider := CollisionShape3D.new()
 collider.shape = mesh.create_trimesh_shape()
 body.add_child(collider)

func _village_roof(center: Vector3) -> void:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var a := Vector3(-4,0,-4)
 var b := Vector3(4,0,-4)
 var c := Vector3(4,0,4)
 var d := Vector3(-4,0,4)
 var e := Vector3(-4,1.2,0)
 var f := Vector3(4,1.2,0)
 for p: Vector3 in [a,b,f,a,f,e, d,e,f,d,f,c, a,e,d, b,c,f]: surface.add_vertex(p)
 surface.generate_normals()
 var visual := MeshInstance3D.new()
 visual.mesh = surface.commit()
 visual.position = center
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.40,0.17,0.13)
 material.roughness = 0.9
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 visual.material_override = material
 add_child(visual)

func _scene_population() -> void:
 # Short, explicitly unobstructed routes in public space; no cross-district AI.
 var roles := ["civilian", "employee", "civilian", "civilian"]
 var routes := [
  [Vector3(-2,0.05,9), Vector3(-2,0.05,-9)],
  [Vector3(2,0.05,-8), Vector3(2,0.05,8)],
  [Vector3(-7,0.05,2), Vector3(7,0.05,2)],
  [Vector3(7,0.05,-2), Vector3(-7,0.05,-2)]]
 if preview_kind == "mountain":
  routes = [
   [Vector3(-2,0.05,10), Vector3(-2,0.05,-10)],
   [Vector3(2,0.05,-9), Vector3(2,0.05,9)],
   [Vector3(-4,0.05,5), Vector3(4,0.05,5)]]
 var coats: Array[Color] = [Color(0.31,0.40,0.48), Color(0.49,0.33,0.23), Color(0.40,0.45,0.32), Color(0.52,0.43,0.41)]
 for i: int in range(routes.size()):
  var person := _target(("Visitor " if preview_kind == "mountain" else "Commuter ") + str(i+1), roles[i], routes[i][0], routes[i][1])
  person.person.clothing.albedo_color = coats[i]

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
 _city_walkway()
 # Market stalls, pedestrian streets and waterfront promenade.
 for x: float in [-30.0,-24.0,-18.0,-12.0]:
  _box(Vector3(x,0.55,8),Vector3(3.8,1.1,1.8),Color(0.38,0.25,0.17),true)
  _box(Vector3(x,2.2,8),Vector3(4.1,0.12,2.4),Color(0.67,0.25,0.18))
  for side: float in [-1.7,1.7]: _box(Vector3(x+side,1.3,8),Vector3(0.1,2.5,0.1),dark)
 _sign("MARKET STREET",Vector3(-21,3.0,5),38)
 _sign("COMMERCIAL DISTRICT",Vector3(18,3.0,-6),38)
 _sign("BACKSTREETS",Vector3(-21,3.0,-8),38)
 _box(Vector3(0,0.03,-40),Vector3(84,0.06,5),Color(0.27,0.38,0.40))
 _box(Vector3(0,0.03,-43),Vector3(84,0.06,3),Color(0.14,0.30,0.38))
 _sign("HARBOUR PROMENADE",Vector3(0,3,-37),38)
 # Facade bays, awnings and signs establish distinct public-facing streets.
 for x: float in [-31.0,-17.0,17.0,31.0]:
  for z: float in [-30.0,-16.0,16.0,30.0]:
   _accent(Vector3(x,3.5,z+4.62),Vector3(9.8,0.15,0.12),Color(0.69,0.62,0.49))
   _accent(Vector3(x,0.13,z+5.2),Vector3(10.4,0.20,0.7),Color(0.49,0.49,0.45))
   for dx: float in [-3.8,3.8]:
    _accent(Vector3(x+dx,1.8,z+4.63),Vector3(0.15,3.4,0.12),Color(0.31,0.33,0.31))
   _accent(Vector3(x,2.8,z+4.75),Vector3(6.8,0.34,0.15),Color(0.18,0.28,0.30))
   _accent(Vector3(x,1.65,z+4.68),Vector3(5.5,1.65,0.06),Color(0.29,0.42,0.43))
 for x: float in [-30.0,-24.0,-18.0,-12.0]:
  for dx: float in [-1.2,0.0,1.2]:
   _accent(Vector3(x+dx,1.21,8),Vector3(0.7,0.22,0.7),Color(0.52,0.57,0.27) if dx == 0.0 else Color(0.66,0.39,0.21))
  _accent(Vector3(x,2.26,8),Vector3(3.9,0.1,2.2),Color(0.73,0.30,0.20))
  for dx: float in [-1.3,0.0,1.3]:
   _accent(Vector3(x+dx,2.28,8),Vector3(0.35,0.12,2.2),Color(0.89,0.75,0.55))
 for x: float in [-36.0,-28.0,-20.0,-12.0,-4.0,4.0,12.0,20.0,28.0,36.0]:
  _accent(Vector3(x,0.8,-39.7),Vector3(0.08,1.6,0.08),Color(0.56,0.61,0.57))
 _accent(Vector3(0,1.45,-39.7),Vector3(80,0.08,0.08),Color(0.56,0.61,0.57))
 for z: float in [-25.0,-15.0,-5.0,5.0,15.0,25.0]:
  for x: float in [-7.3,7.3]:
   _accent(Vector3(x,1.9,z),Vector3(0.11,3.8,0.11),Color(0.22,0.27,0.26))
   _accent(Vector3(x,3.85,z),Vector3(0.65,0.10,0.45),Color(0.94,0.78,0.56))
 for x: float in [-35.0,-25.0,-15.0,-5.0,5.0,15.0,25.0,35.0]:
  _box(Vector3(x,1.4,-38),Vector3(0.12,2.8,0.12),dark)
  _box(Vector3(x,2.85,-38),Vector3(0.7,0.1,0.7),Color(0.95,0.80,0.58))

func _mountain() -> void:
 _ground(Color(0.36,0.46,0.34))
 var stone := Color(0.61,0.60,0.53)
 _terrain_patch(-43,-38,33,36,2.6)
 _terrain_patch(10,-38,33,36,2.9)
 var dark := Color(0.22,0.24,0.20)
 # Broad public approach. The statue is a non-destructible landmark.
 _box(Vector3(0,0.03,0),Vector3(11,0.06,80),stone)
 _box(Vector3(0,0.06,-22),Vector3(26,0.12,18),stone.lightened(0.08))
 for x: float in [-22.0,-14.0,14.0,22.0]:
  _box(Vector3(x,1.5,13),Vector3(7,3,7),Color(0.65,0.53,0.39),true)
  _village_roof(Vector3(x,3.15,13))
  _accent(Vector3(x,3.18,9.0),Vector3(8.2,0.16,0.18),Color(0.30,0.18,0.14))
  _accent(Vector3(x,3.18,17.0),Vector3(8.2,0.16,0.18),Color(0.30,0.18,0.14))
  _box(Vector3(x,1.5,9.44),Vector3(5,1.7,0.05),Color(0.25,0.35,0.32))
 _sign("VILLAGE APPROACH",Vector3(0,3.2,12),38)
 _box(Vector3(0,0.7,-29),Vector3(12,1.4,9),Color(0.42,0.39,0.33),true)
 _box(Vector3(0,1.55,-29),Vector3(8,0.3,6),Color(0.64,0.53,0.36))
 # Stylised seated figure: original abstract forms, never a destructive element.
 _sphere(Vector3(0,2.15,-29),Vector3(6.2,1.25,3.6),Color(0.38,0.31,0.23))
 _sphere(Vector3(0,3.35,-29),Vector3(3.6,2.8,2.0),Color(0.43,0.35,0.25))
 for x: float in [-2.0,2.0]:
  _sphere(Vector3(x,2.85,-29),Vector3(1.0,2.0,0.9),Color(0.43,0.35,0.25))
  _sphere(Vector3(x*0.55,2.25,-30),Vector3(1.2,0.55,0.7),Color(0.47,0.38,0.27))
 _sphere(Vector3(0,2.15,-30.1),Vector3(1.9,0.45,0.8),Color(0.47,0.38,0.27))
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
 _sphere(Vector3(0,5.75,-29),Vector3(0.55,0.5,0.55),Color(0.37,0.30,0.22))
 for x: float in [-30.0,-20.0,-12.0,12.0,20.0,30.0]:
  for z: float in [-33.0,-17.0,0.0,26.0,36.0]:
   _box(Vector3(x,1.1,z),Vector3(0.45,2.2,0.45),Color(0.28,0.22,0.14))
   canopy_transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(3.0,2.7,3.0)),Vector3(x,2.7,z)))
   canopy_transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.9,1.8,1.9)),Vector3(x+0.8,3.45,z-0.4)))
 # Benches, visitor railings and path edging respect the landmark's public use.
 for z: float in [-16.0,-6.0,4.0,14.0,24.0]:
  for x: float in [-6.5,6.5]:
   _accent(Vector3(x,0.43,z),Vector3(1.8,0.12,0.65),Color(0.37,0.25,0.17))
   _accent(Vector3(x,0.22,z),Vector3(1.5,0.45,0.08),Color(0.27,0.27,0.23))
 for z: float in [-20.0,-12.0,-4.0,4.0,12.0,20.0,28.0]:
  for x: float in [-5.6,5.6]:
   _accent(Vector3(x,0.10,z),Vector3(0.12,0.18,7.5),Color(0.45,0.47,0.37))
 for x: float in [-9.0,9.0]:
  for z: float in [-18.0,-10.0,0.0,10.0,22.0]:
   _accent(Vector3(x,0.16,z),Vector3(0.9,0.32,0.9),Color(0.39,0.38,0.30))
   _accent(Vector3(x,0.70,z),Vector3(1.4,0.95,1.4),Color(0.23,0.39,0.23))
 # Distant, stylised peaks, and an atmospheric decorative cable-car vista.
 for x: float in [-39.0,-27.0,27.0,39.0]:
  _peak(Vector3(x,0,-42), 12.0, 15.0 + absf(x)*0.12, Color(0.27,0.37,0.35))
 _box(Vector3(0,8,30),Vector3(80,0.07,0.07),dark)
 for x: float in [-20.0,10.0,32.0]:
  _box(Vector3(x,6.3,30),Vector3(2.0,2.3,1.8),Color(0.66,0.26,0.18))
  _box(Vector3(x,6.6,29.08),Vector3(1.6,1.1,0.05),Color(0.30,0.46,0.48))
  _box(Vector3(x,7.8,30),Vector3(0.12,0.7,0.12),dark)

func _sphere(pos: Vector3, dimensions: Vector3, color: Color) -> void:
 var visual := MeshInstance3D.new()
 var mesh := SphereMesh.new()
 mesh.radius = 0.5
 mesh.height = 1.0
 mesh.radial_segments = 12
 mesh.rings = 6
 visual.mesh = mesh
 visual.scale = dimensions
 visual.position = pos
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.92
 visual.material_override = material
 add_child(visual)

func _peak(pos: Vector3, radius: float, height: float, color: Color) -> void:
 var visual := MeshInstance3D.new()
 var mesh := CylinderMesh.new()
 mesh.top_radius = 0.0
 mesh.bottom_radius = radius
 mesh.height = height
 mesh.radial_segments = 7
 visual.mesh = mesh
 visual.position = pos + Vector3.UP * height * 0.5
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 1.0
 visual.material_override = material
 add_child(visual)
