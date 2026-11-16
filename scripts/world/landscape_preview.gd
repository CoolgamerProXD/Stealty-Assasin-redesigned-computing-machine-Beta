extends "res://scripts/world/tung_chung_preview.gd"
## Original explorable landscape studies, separate from campaign progression.
@export_enum("city", "mountain") var preview_kind: String = "city"
var accents: Array[Transform3D] = []
var accent_colors: Array[Color] = []
var canopy_transforms: Array[Transform3D] = []

func _ready() -> void:
 _environment()
 _start_ambience("city" if preview_kind == "city" else "mountain")
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

func footstep_surface(point: Vector3) -> String:
 if preview_kind == "mountain" and absf(point.x) > 5.5: return "grass"
 return "stone"

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
   # Godot's front-facing triangle winding also determines the solid side
   # of the concave collision mesh. Reversing this makes an uphill walk hit
   # the underside of the terrain and stick at the seam with the flat floor.
   for corner: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(0,1),Vector2i(0,0),Vector2i(1,0),Vector2i(1,1)]:
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

# Parked street vehicles are fictional low-poly props, not controllable. Their
# simple body collider is outside all public-space NPC routes and the ramp.
func _parked_car(x: float, z: float, paint: Color) -> void:
 var dark := Color(0.11,0.15,0.16)
 _box(Vector3(x,0.48,z),Vector3(2.25,0.72,4.1),paint,true)
 _accent(Vector3(x,1.03,z-0.15),Vector3(1.90,0.65,2.0),paint.darkened(0.08))
 _accent(Vector3(x,1.05,z-1.17),Vector3(1.67,0.43,0.035),Color(0.28,0.42,0.45))
 _accent(Vector3(x,1.05,z+0.87),Vector3(1.67,0.43,0.035),Color(0.28,0.42,0.45))
 for side: float in [-1.0,1.0]:
  _accent(Vector3(x+side*1.14,1.06,z-0.15),Vector3(0.04,0.40,1.75),Color(0.25,0.38,0.41))
  for dz: float in [-1.3,1.3]:
   _accent(Vector3(x+side*1.14,0.30,z+dz),Vector3(0.22,0.54,0.70),dark)
 for dx: float in [-0.78,0.78]:
  _accent(Vector3(x+dx,0.55,z-2.07),Vector3(0.30,0.17,0.04),Color(0.93,0.82,0.57))
  _accent(Vector3(x+dx,0.55,z+2.07),Vector3(0.30,0.17,0.04),Color(0.68,0.16,0.12))

func _parked_bus(x: float, z: float) -> void:
 var red := Color(0.58,0.20,0.16)
 var glass := Color(0.23,0.36,0.39)
 _box(Vector3(x,1.76,z),Vector3(2.4,3.5,7.2),red,true)
 for side: float in [-1.0,1.0]:
  for y: float in [1.35,2.75]:
   for dz: float in [-2.7,-1.35,0.0,1.35,2.7]:
    _accent(Vector3(x+side*1.21,y,z+dz),Vector3(0.04,0.8,1.1),glass)
  for dz: float in [-2.2,2.2]:
   _accent(Vector3(x+side*1.22,0.35,z+dz),Vector3(0.25,0.66,0.85),Color(0.10,0.12,0.13))
 _accent(Vector3(x,2.55,z-3.61),Vector3(2.0,0.75,0.04),glass)
 _accent(Vector3(x,1.18,z-3.61),Vector3(2.0,0.75,0.04),glass)
 _accent(Vector3(x,3.20,z-3.63),Vector3(1.7,0.20,0.04),Color(0.90,0.74,0.43))

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
   if _is_operation_interior(x, z):
    _operation_interior(x, z)
    continue
   var building := Color(0.42+absf(x)*0.002,0.44,0.42+absf(z)*0.002)
   _box(Vector3(x,h/2,z),Vector3(10,h,9),building,true)
   for level: int in range(1,3):
    for dx: float in [-3.0,0.0,3.0]:
     _box(Vector3(x+dx,2.0+level*2.0,z+4.54),Vector3(1.6,1.2,0.06),Color(0.22,0.34,0.38))
   _box(Vector3(x,0.3,z+4.9),Vector3(10,0.6,0.8),dark)
   # Street-facing bays give the blocks readable fronts from the main road.
   var face_x := x + (5.04 if x < 0.0 else -5.04)
   var glass := Color(0.22,0.34,0.37) if z > 0.0 else Color(0.17,0.29,0.34)
   for floor_index: int in range(1,4):
    var y := 2.0 + float(floor_index)*1.65
    if y + 0.6 < h:
     for dz: float in [-2.8,0.0,2.8]:
      _accent(Vector3(face_x,y,z+dz),Vector3(0.08,1.18,1.65),glass)
      _accent(Vector3(face_x + (0.06 if x < 0.0 else -0.06),y,z+dz),Vector3(0.04,1.22,0.05),pale)
    _accent(Vector3(face_x,y+0.72,z),Vector3(0.11,0.07,8.5),Color(0.58,0.57,0.50))
   # Setback roof volumes vary the silhouette without creating fake interiors.
   var extra_height := 2.5 + float(int(absf(x+z)) % 4) * 0.8
   _accent(Vector3(x,h+extra_height*0.5,z),Vector3(7.8,extra_height,6.8),building.darkened(0.1))
   _accent(Vector3(x,h+extra_height+0.25,z),Vector3(8.1,0.5,7.1),dark)
   for dx: float in [-2.3,0.0,2.3]:
    _accent(Vector3(x+dx,h+extra_height*0.55,z+3.43),Vector3(1.2,extra_height*0.6,0.04),glass)
 _city_walkway()
 # Parked cars, a double-decker and crossings make the public street legible.
 # Their bodies are solid and lie beyond the short central visitor routes.
 _parked_car(-8.9,20,Color(0.67,0.18,0.15))
 _parked_car(8.9,-18,Color(0.38,0.43,0.42))
 _parked_bus(-9.2,-27)
 for z: float in [-5.8,5.8]:
  for x: float in [-4.5,-3.0,-1.5,0.0,1.5,3.0,4.5]:
   _accent(Vector3(x,0.075,z),Vector3(0.75,0.02,1.25),Color(0.78,0.76,0.67))
 # A layered skyline is scenic outside the walkable boundary, not interiors.
 for i: int in range(13):
  var x := -45.0 + float(i)*7.5
  var h := 10.0 + float((i*11)%7)*1.3
  _accent(Vector3(x,h*0.5,-49),Vector3(6.8,h,3.0),Color(0.20+float(i%3)*0.025,0.28,0.31))
  for y: float in [4.0,7.0,10.0]:
   if y < h - 0.5:
    for dx: float in [-2.0,0.0,2.0]:
     _accent(Vector3(x+dx,y,-47.47),Vector3(0.7,0.9,0.05),Color(0.52,0.54,0.45))
 # Market stalls, pedestrian streets and waterfront promenade.
 for x: float in [-30.0,-24.0,-18.0,-12.0]:
  _box(Vector3(x,0.55,8),Vector3(3.8,1.1,1.8),Color(0.38,0.25,0.17),true)
  _box(Vector3(x,2.2,8),Vector3(4.1,0.12,2.4),Color(0.67,0.25,0.18))
  for side: float in [-1.7,1.7]: _box(Vector3(x+side,1.3,8),Vector3(0.1,2.5,0.1),dark)
 _sign("MARKET STREET",Vector3(-21,3.0,5),38)
 _sign("COMMERCIAL DISTRICT",Vector3(18,3.0,-6),38)
 _sign("BACKSTREETS",Vector3(-21,3.0,-8),38)
 for entry: Array in [["JADE TEA",Vector3(-11.90,3.2,16.0),PI/2], ["NORTH MARKET",Vector3(-11.90,3.2,30.0),PI/2], ["HARBOUR OFFICE",Vector3(11.90,3.2,-16.0),-PI/2], ["CENTRAL ARCADE",Vector3(11.90,3.2,16.0),-PI/2]]:
  var placard := Label3D.new()
  placard.text = entry[0]
  placard.position = entry[1]
  placard.rotation.y = entry[2]
  placard.font_size = 38
  placard.pixel_size = 0.004
  placard.modulate = Color(0.90,0.78,0.58)
  add_child(placard)
 _box(Vector3(0,0.03,-40),Vector3(84,0.06,5),Color(0.27,0.38,0.40))
 _box(Vector3(0,0.03,-43),Vector3(84,0.06,3),Color(0.14,0.30,0.38))
 _sign("HARBOUR PROMENADE",Vector3(0,3,-37),38)
 # Facade bays, awnings and signs establish distinct public-facing streets.
 for x: float in [-31.0,-17.0,17.0,31.0]:
  for z: float in [-30.0,-16.0,16.0,30.0]:
   if _is_operation_interior(x, z): continue
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

# Three mission-specific, walk-in interiors replace (rather than overlap) a
# solid scenic block. The surrounding city remains a shared destination.
func _is_operation_interior(x: float, z: float) -> bool:
 var op := str(get_meta("operation_id", ""))
 return (op == "the_streets" and x == -17.0 and z == 16.0) or (op == "the_district" and x == 17.0 and z == 16.0) or (op == "the_harbour" and x == 17.0 and z == -30.0)

func _operation_interior(x: float, z: float) -> void:
 var op := str(get_meta("operation_id", ""))
 var wall := Color(0.60,0.57,0.49) if op == "the_streets" else (Color(0.45,0.52,0.51) if op == "the_district" else Color(0.52,0.49,0.42))
 var dark := Color(0.23,0.28,0.28)
 # Front split around an actual 2.4 m doorway. Other walls and the roof are solid.
 if op == "the_harbour":
  _box(Vector3(x,2.1,z+4.5),Vector3(10,4.2,0.25),wall,true)
  for side: float in [-1.0,1.0]:
   _box(Vector3(x+side*5,2.1,z),Vector3(0.25,4.2,9),wall,true)
   _box(Vector3(x+side*3.1,2.1,z-4.5),Vector3(3.8,4.2,0.25),wall,true)
 else:
  var front: float = x + (5.0 if x < 0 else -5.0)
  var back: float = x - (5.0 if x < 0 else -5.0)
  _box(Vector3(back,2.1,z),Vector3(0.25,4.2,9),wall,true)
  for side: float in [-1.0,1.0]:
   _box(Vector3(x,2.1,z+side*4.5),Vector3(10,4.2,0.25),wall,true)
   _box(Vector3(front,2.1,z+side*2.85),Vector3(0.25,4.2,3.3),wall,true)
 _box(Vector3(x,4.3,z),Vector3(10,0.2,9),dark,true)
 _box(Vector3(x,0.015,z),Vector3(9.7,0.03,8.7),Color(0.48,0.45,0.38))
 # A desk and wall fixtures are tucked away from the doorway and actor routes.
 var desk_x := x + (-3.0 if op == "the_streets" else 3.0)
 _box(Vector3(desk_x,0.5,z-2.8),Vector3(1.6,1.0,1.0),Color(0.36,0.25,0.18),true)
 _box(Vector3(desk_x,1.2,z-2.8),Vector3(0.65,0.5,0.12),Color(0.18,0.31,0.33))
 _box(Vector3(x,4.12,z),Vector3(2.8,0.08,0.6),Color(0.95,0.84,0.62))
 var label := "MARKET OFFICE" if op == "the_streets" else ("DISTRICT RECORDS" if op == "the_district" else "HARBOUR LIAISON")
 _sign(label, Vector3(x,2.9,z+4.31), 34)
 var region := NavigationRegion3D.new()
 region.name = "InteriorLocalNavigation"
 var nav := NavigationMesh.new()
 nav.vertices = PackedVector3Array([Vector3(x-4.5,0,z-4.0),Vector3(x+4.5,0,z-4.0),Vector3(x+4.5,0,z+4.0),Vector3(x-4.5,0,z+4.0)])
 nav.add_polygon(PackedInt32Array([0,3,2,1]))
 region.navigation_mesh = nav
 add_child(region)

func _mountain() -> void:
 _ground(Color(0.36,0.46,0.34))
 var stone := Color(0.61,0.60,0.53)
 _terrain_patch(-43,-38,33,36,2.6)
 _terrain_patch(10,-38,33,36,2.9)
 if str(get_meta("operation_id", "")) == "ngong_ping": _mountain_field_office()
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
 # The landmark is intentionally a respectful, stylised public monument,
 # not a mission target. Its proportions are enlarged relative to visitors,
 # rather than presenting a six-metre miniature in the landscape.
 _box(Vector3(0,1.2,-29),Vector3(34,2.4,18),Color(0.42,0.39,0.33),true)
 _box(Vector3(0,2.43,-29),Vector3(32,0.15,16),Color(0.64,0.53,0.36))
 _buddha_approach()
 # A broad lotus-like ring sits on the pedestal; it remains scenic only.
 for i: int in range(16):
  var angle := TAU * float(i) / 16.0
  var petal := _sphere(Vector3(cos(angle)*12.3,2.80,-29+sin(angle)*5.7),Vector3(3.8,0.65,2.5),Color(0.48,0.39,0.27))
  petal.rotation.y = -angle
 var landmark := Node3D.new()
 landmark.name = "ScenicBuddhaLandmark"
 landmark.position = Vector3(0,2.5,-29)
 landmark.scale = Vector3.ONE * 5.0
 add_child(landmark)
 # Original abstract seated figure, with no interaction or damage behavior.
 _landmark_part(landmark, Vector3(0,2.15,-29),Vector3(6.2,1.25,3.6),Color(0.38,0.31,0.23))
 _landmark_part(landmark, Vector3(0,3.35,-29),Vector3(3.6,2.8,2.0),Color(0.43,0.35,0.25))
 # A restrained seated silhouette with a raised right hand and a hand in the
 # lap.  The landmark is purely scenic and has no target or damage behavior.
 _landmark_part(landmark, Vector3(2.0,2.85,-29),Vector3(1.0,2.0,0.9),Color(0.43,0.35,0.25))
 var raised_arm := _landmark_part(landmark, Vector3(-1.95,3.15,-28.75),Vector3(0.85,1.85,0.80),Color(0.43,0.35,0.25))
 raised_arm.rotation.z = -0.22
 _landmark_part(landmark, Vector3(-2.10,4.03,-28.50),Vector3(0.60,0.80,0.24),Color(0.47,0.38,0.27))
 # Separate raised fingers and thumb distinguish the blessing gesture.
 for finger: int in range(4):
  _landmark_part(landmark, Vector3(-2.32+float(finger)*0.14,4.47,-28.50),Vector3(0.11,0.35,0.14),Color(0.47,0.38,0.27))
 var thumb := _landmark_part(landmark, Vector3(-1.75,4.02,-28.48),Vector3(0.12,0.33,0.14),Color(0.47,0.38,0.27))
 thumb.rotation.z = -0.75
 _landmark_part(landmark, Vector3(1.10,2.35,-27.78),Vector3(1.2,0.45,0.55),Color(0.47,0.38,0.27))
 _landmark_part(landmark, Vector3(0,2.15,-27.85),Vector3(1.9,0.45,0.8),Color(0.47,0.38,0.27))
 # Broad, low-contrast robe folds follow the chest rather than using signage.
 for y: float in [2.9,3.25,3.6]:
  _landmark_part(landmark, Vector3(0.25,y,-27.98),Vector3(2.5,0.10,0.12),Color(0.39,0.32,0.24))
 var head := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 0.75
 sphere.height = 1.5
 head.mesh = sphere
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.47,0.38,0.27)
 material.roughness = 0.9
 head.material_override = material
 head.position = Vector3(0,5.0,-29) - Vector3(0,1.65,-29)
 landmark.add_child(head)
 _landmark_part(landmark, Vector3(0,5.75,-29),Vector3(0.55,0.5,0.55),Color(0.37,0.30,0.22))
 # Small stylised curls describe the hair cap rather than a generic head.
 for row: int in range(3):
  for column: int in range(-2,3):
   var x := float(column) * 0.24
   var y := 5.53 + float(row) * 0.12
   var z := -29.48 + float(row) * 0.10
   _landmark_part(landmark, Vector3(x,y,z),Vector3(0.18,0.18,0.18),Color(0.36,0.30,0.22))
 for x: float in [-0.72,0.72]:
  _landmark_part(landmark, Vector3(x,4.93,-28.94),Vector3(0.23,0.47,0.20),Color(0.46,0.37,0.26))
 for x: float in [-0.25,0.25]:
  _landmark_part(landmark, Vector3(x,5.05,-28.29),Vector3(0.26,0.045,0.035),Color(0.28,0.24,0.20))
 _landmark_part(landmark, Vector3(0,4.91,-28.22),Vector3(0.15,0.20,0.12),Color(0.45,0.36,0.25))
 _landmark_part(landmark, Vector3(0,4.75,-28.33),Vector3(0.28,0.035,0.025),Color(0.31,0.25,0.20))
 for x: float in [-30.0,-20.0,-12.0,12.0,20.0,30.0]:
  for z: float in [-33.0,-17.0,0.0,26.0,36.0]:
   if absf(x) < 17.5 and z < -20.0: continue # Keep the plinth clear.
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

# A small fictional field office for the final operation, physically separate
# from the public monument and its viewing terrace.
func _mountain_field_office() -> void:
 var marker := Node3D.new()
 marker.name = "MountainFieldOffice"
 add_child(marker)
 var wall := Color(0.51,0.52,0.45)
 var trim := Color(0.26,0.31,0.27)
 _box(Vector3(11.5,1.6,5),Vector3(0.2,3.2,5),wall,true)
 for side: float in [-1.0,1.0]:
  _box(Vector3(9,1.6,5+side*2.5),Vector3(5,3.2,0.2),wall,true)
  _box(Vector3(6.5,1.6,5+side*1.75),Vector3(0.2,3.2,1.5),wall,true)
 _box(Vector3(9,3.25,5),Vector3(5.2,0.16,5.2),trim,true)
 _box(Vector3(9,0.018,5),Vector3(4.9,0.036,4.9),Color(0.45,0.43,0.36))
 _box(Vector3(11.2,1.2,6.5),Vector3(0.12,1.8,1.3),Color(0.34,0.27,0.20))
 _sign("FIELD ARCHIVE", Vector3(9,2.7,7.35), 28)

# A broad physical approach to the public viewing terrace. The sloped
# collider backs the visible shallow steps and overlaps the existing plinth.
func _buddha_approach() -> void:
 var ramp := StaticBody3D.new()
 ramp.name = "BuddhaViewingApproach"
 # Shift the high end just beyond the leading edge of the plinth so the
 # capsule meets the terrace at floor height rather than hitting a vertical lip.
 ramp.position = Vector3(0,1.17,-17.45)
 ramp.rotation.x = atan(2.4 / 5.0)
 add_child(ramp)
 var shape := BoxShape3D.new()
 shape.size = Vector3(6.0,0.14,sqrt(2.4*2.4+5.0*5.0))
 var collider := CollisionShape3D.new()
 collider.shape = shape
 ramp.add_child(collider)
 for i: int in range(10):
  _box(Vector3(0, float(i)*0.24+0.03, -15.5-float(i)*0.5), Vector3(6.0,0.06,0.48), Color(0.61,0.57,0.48))
 for side: float in [-1.0,1.0]:
  _box(Vector3(side*3.15,0.65,-17.8),Vector3(0.15,1.3,5.4),Color(0.44,0.41,0.35))

func _landmark_part(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
 var visual := _sphere(pos, dimensions, color)
 visual.reparent(parent, false)
 # Original proportions are expressed around the model's seated base.
 visual.position = pos - Vector3(0,1.65,-29)
 return visual

func _sphere(pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
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
 return visual

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
