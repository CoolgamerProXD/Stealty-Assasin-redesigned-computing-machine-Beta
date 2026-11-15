class_name EnvironmentDressing
extends Node3D
## Original, batched architectural dressing. Collision and navigation remain in
## the mission layout; decoration deliberately avoids modifying mission routes.
var core_transforms: Array[Transform3D] = []
var core_colors: Array[Color] = []
var detail_transforms: Array[Transform3D] = []
var detail_colors: Array[Color] = []
const BRASS := Color(0.69, 0.49, 0.24)
const DARK := Color(0.12, 0.15, 0.16)
const IVORY := Color(0.70, 0.67, 0.57)
const WOOD := Color(0.30, 0.18, 0.13)
const TEAL := Color(0.15, 0.29, 0.30)

func build(id: String) -> void:
 name = "EnvironmentDressing"
 if id == "meridian":
  _hotel()
  _hotel_wing()
  var furniture := preload("res://scripts/visuals/hotel_furniture.gd").new()
  add_child(furniture)
  furniture.build()
 else: _annex()
 _batch(core_transforms, core_colors, false)
 _batch(detail_transforms, detail_colors, true)

func _part(pos: Vector3, size: Vector3, color: Color, detail: bool = false) -> void:
 var transform := Transform3D(Basis.IDENTITY.scaled(size), pos)
 if detail:
  detail_transforms.append(transform)
  detail_colors.append(color)
 else:
  core_transforms.append(transform)
  core_colors.append(color)

func _batch(transforms: Array[Transform3D], colors: Array[Color], detail: bool) -> void:
 if transforms.is_empty(): return
 var multi := MultiMesh.new()
 multi.transform_format = MultiMesh.TRANSFORM_3D
 multi.use_colors = true
 var mesh := BoxMesh.new()
 mesh.size = Vector3.ONE
 var material := StandardMaterial3D.new()
 material.vertex_color_use_as_albedo = true
 material.roughness = 0.7
 mesh.material = material
 multi.mesh = mesh
 multi.instance_count = transforms.size()
 for i: int in range(transforms.size()):
  multi.set_instance_transform(i, transforms[i])
  multi.set_instance_color(i, colors[i])
 var visual := MultiMeshInstance3D.new()
 visual.name = "FineDetail" if detail else "ArchitecturalDetails"
 visual.multimesh = multi
 visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if detail:
  visual.add_to_group("quality_detail")
  visual.visible = Campaign.settings["graphics"] == "HIGH"
 add_child(visual)

func _sign(text: String, pos: Vector3, color: Color, angle: float = 0.0) -> void:
 var label := Label3D.new()
 label.text = text
 label.font_size = 48
 label.pixel_size = 0.003
 label.modulate = color
 label.position = pos
 label.rotation.y = angle
 label.no_depth_test = false
 add_child(label)

func _lamp(pos: Vector3, color: Color, energy: float, distance: float) -> void:
 var light := OmniLight3D.new()
 light.position = pos
 light.light_color = color
 light.light_energy = energy
 light.omni_range = distance
 light.shadow_enabled = false
 light.add_to_group("quality_practicals")
 light.visible = Campaign.settings["graphics"] != "LOW"
 add_child(light)

func _sofa(x: float, z: float) -> void:
 _part(Vector3(x, 0.36, z), Vector3(2.0, 0.38, 0.8), Color(0.22, 0.30, 0.30))
 _part(Vector3(x, 0.70, z - 0.32), Vector3(2.0, 0.45, 0.18), Color(0.18, 0.25, 0.26))
 for side: float in [-0.92, 0.92]:
  _part(Vector3(x + side, 0.57, z), Vector3(0.16, 0.42, 0.78), WOOD)
  _part(Vector3(x + side * 0.8, 0.10, z), Vector3(0.10, 0.20, 0.55), DARK)
 _part(Vector3(x, 0.57, z + 0.05), Vector3(1.65, 0.07, 0.55), Color(0.30, 0.39, 0.38), true)

func _plant(x: float, z: float) -> void:
 _part(Vector3(x, 0.28, z), Vector3(0.46, 0.56, 0.46), Color(0.38, 0.31, 0.24))
 _part(Vector3(x, 0.65, z), Vector3(0.11, 0.65, 0.11), WOOD)
 for dx: float in [-0.24, 0.0, 0.24]:
  _part(Vector3(x + dx, 1.12 + absf(dx) * 0.6, z), Vector3(0.22, 0.50, 0.34), Color(0.19, 0.34, 0.23))

func _hotel() -> void:
 # Lobby: reception, upholstered lounge, brass inlay and potted plants.
 _part(Vector3(-5, 1.04, -4.8), Vector3(4.25, 0.10, 1.15), Color(0.68, 0.59, 0.46))
 _part(Vector3(-5, 0.55, -4.24), Vector3(3.8, 0.60, 0.035), Color(0.37, 0.25, 0.17))
 for x: float in [-6.5, -5.5, -4.5, -3.5]:
  _part(Vector3(x, 0.56, -4.20), Vector3(0.04, 0.55, 0.035), BRASS)
 _part(Vector3(-5, 1.67, -7.72), Vector3(4.0, 1.25, 0.05), WOOD)
 _part(Vector3(-5, 1.67, -7.67), Vector3(3.8, 0.04, 0.04), BRASS)
 _sign("THE MERIDIAN", Vector3(-5, 1.9, -7.62), Color(0.92, 0.77, 0.48))
 _sign("RECEPTION  /  GUEST SERVICES", Vector3(-5, 1.48, -7.62), IVORY)
 _plant(-10.6, -6.8)
 _plant(0.6, 6.8)
 # Framed wall panels, baseboards, and high-contrast wayfinding at access boundaries.
 for x: float in [-10.0, -7.5, -2.5, 0.0, 4.5, 9.5]:
  _part(Vector3(x, 0.22, -7.76), Vector3(2.1, 0.36, 0.08), WOOD if x < 2 else DARK)
  _part(Vector3(x, 2.65, -7.76), Vector3(2.1, 0.08, 0.08), BRASS if x < 2 else TEAL)
  _part(Vector3(x, 1.65, -7.72), Vector3(0.04, 1.6, 0.05), BRASS if x < 2 else TEAL, true)
 for x: float in [2.0, 7.0]:
  for z: float in [-3.0, 3.0]:
   _part(Vector3(x - 0.22, 2.45, z), Vector3(0.08, 0.30, 1.70), DARK if x > 2 else WOOD)
 _sign("STAFF ONLY", Vector3(1.75, 2.45, -3), Color(0.73, 0.85, 0.82), -PI / 2)
 _sign("SECURE ARCHIVE", Vector3(6.75, 2.45, -3), Color(0.93, 0.65, 0.40), -PI / 2)
 # Continuous mouldings and framed wall bays communicate the corridor rather
 # than changing the physical openings that navigation and cover rely on.
 for x: float in [1.86, 2.14, 6.86, 7.14]:
  for z: float in [-6.0, 0.0, 6.0]:
   _part(Vector3(x, 0.50, z), Vector3(0.035, 0.90, 3.75), Color(0.22, 0.24, 0.22) if x > 2 else WOOD)
   _part(Vector3(x, 0.98, z), Vector3(0.055, 0.05, 3.75), BRASS if x < 3 else Color(0.40, 0.51, 0.49))
   _part(Vector3(x, 2.55, z), Vector3(0.045, 0.05, 3.75), BRASS if x < 3 else Color(0.40, 0.51, 0.49))
   for dz: float in [-1.45, 1.45]:
    _part(Vector3(x, 1.75, z + dz), Vector3(0.055, 1.45, 0.05), BRASS if x < 3 else TEAL, true)
 # Framed abstract artwork and floor borders provide landmarks in the lobby.
 for x: float in [-9.0, -1.5]:
  _part(Vector3(x, 1.75, 7.76), Vector3(1.7, 1.2, 0.08), BRASS)
  _part(Vector3(x, 1.75, 7.70), Vector3(1.56, 1.06, 0.05), Color(0.12, 0.23, 0.25))
  _part(Vector3(x - 0.2, 1.78, 7.66), Vector3(0.18, 0.75, 0.025), Color(0.70, 0.51, 0.31), true)
 for z: float in [-2.7, 2.7]:
  _part(Vector3(-5, 0.045, z), Vector3(9.8, 0.01, 0.045), BRASS)
 for x: float in [-9.8, -0.2]:
  _part(Vector3(x, 0.045, 0), Vector3(0.045, 0.01, 5.4), BRASS)
 # Exit landmark on the outer wall, not a new interactive collision.
 _part(Vector3(-11.82, 1.4, 5.5), Vector3(0.06, 2.7, 1.5), DARK)
 _part(Vector3(-11.76, 1.4, 5.5), Vector3(0.05, 2.5, 1.3), Color(0.24, 0.28, 0.27))
 _sign("EXIT", Vector3(-11.68, 2.65, 5.5), Color(0.77, 0.85, 0.70), PI / 2)
 # Staff workstations and archive shelving, away from door openings.
 for x: float in [4.5, 9.5]:
  _part(Vector3(x, 1.02, -5), Vector3(2.25, 0.08, 1.05), Color(0.58, 0.59, 0.53))
  _part(Vector3(x, 1.28, -5.3), Vector3(0.60, 0.42, 0.07), DARK)
  _part(Vector3(x, 1.29, -5.25), Vector3(0.50, 0.31, 0.015), TEAL)
  for z: float in [5.2, 6.4]:
   _part(Vector3(x, 1.1, z), Vector3(2.4, 2.1, 0.40), DARK)
   for y: float in [0.35, 0.85, 1.35, 1.85]:
    _part(Vector3(x, y, z - 0.23), Vector3(2.2, 0.06, 0.10), IVORY)
    for dx: float in [-0.7, 0.0, 0.7]:
     _part(Vector3(x + dx, y + 0.15, z - 0.22), Vector3(0.38, 0.24, 0.10), Color(0.42, 0.38, 0.30), true)
 for x: float in [-8.0, -2.0, 4.5, 9.5]:
  _part(Vector3(x, 2.92, 0), Vector3(1.2, 0.025, 0.14), Color(1.0, 0.83, 0.57))
 # A reflection probe was removed: in Compatibility it darkened the lobby.
 var polished := MeshInstance3D.new()
 polished.name = "PolishedReceptionInlay"
 var polished_mesh := BoxMesh.new()
 polished_mesh.size = Vector3(3.9, 0.015, 0.85)
 polished.mesh = polished_mesh
 polished.position = Vector3(-5, 1.10, -4.8)
 var polished_material := StandardMaterial3D.new()
 polished_material.albedo_color = Color(0.43, 0.31, 0.20)
 polished_material.metallic = 0.45
 polished_material.roughness = 0.24
 polished.material_override = polished_material
 polished.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(polished)
 _lamp(Vector3(-6, 2.65, -3.5), Color(1.0, 0.70, 0.42), 0.55, 7.0)
 _lamp(Vector3(-5, 2.65, 3), Color(1.0, 0.73, 0.48), 0.45, 7.0)
 _lamp(Vector3(4.5, 2.6, 0), Color(0.65, 0.82, 1.0), 0.35, 6.0)
 _lamp(Vector3(9.5, 2.6, 0), Color(0.65, 0.82, 1.0), 0.35, 6.0)

# West wing detail uses the same instanced box batches as the original lobby.
# Furnishings are deliberately outside the circulation and scripted routes.
func _dining_crockery() -> void:
 var transforms: Array[Transform3D] = []
 var colors: Array[Color] = []
 for x: float in [-38.0,-31.0,-24.0,-17.0]:
  for dx: float in [-0.8,0.8]:
   for item: Array in [
    [Vector3(x+dx,1.03,-10), Vector3(0.40,0.025,0.40), Color(0.93,0.90,0.82)],
    [Vector3(x+dx+0.30,1.09,-10.30), Vector3(0.13,0.15,0.13), Color(0.88,0.85,0.77)],
    [Vector3(x+dx+0.30,1.17,-10.30), Vector3(0.10,0.01,0.10), Color(0.25,0.17,0.12)]]:
    transforms.append(Transform3D(Basis.IDENTITY.scaled(item[1]), item[0]))
    colors.append(item[2])
 var batch := MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 batch.use_colors = true
 var cylinder := CylinderMesh.new()
 cylinder.height = 1.0
 cylinder.radial_segments = 16
 cylinder.rings = 1
 var material := StandardMaterial3D.new()
 material.vertex_color_use_as_albedo = true
 material.roughness = 0.42
 cylinder.material = material
 batch.mesh = cylinder
 batch.instance_count = transforms.size()
 for i: int in range(transforms.size()):
  batch.set_instance_transform(i, transforms[i])
  batch.set_instance_color(i, colors[i])
 var dishes := MultiMeshInstance3D.new()
 dishes.name = "DiningCrockery"
 dishes.multimesh = batch
 dishes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(dishes)

func _hotel_wing() -> void:
 var ivory := Color(0.76, 0.72, 0.63)
 var walnut := Color(0.25, 0.15, 0.11)
 var bronze := Color(0.64, 0.46, 0.25)
 var teal := Color(0.15, 0.28, 0.29)
 var carpet := Color(0.29, 0.17, 0.16)
 # A continuous runner and inlaid edge lead from the old lobby to the wing.
 _part(Vector3(-27,0.022,-2), Vector3(29.5,0.014,3.5), carpet)
 for z: float in [-3.65,-0.35]:
  _part(Vector3(-27,0.035,z), Vector3(29.3,0.015,0.045), bronze)
 for x: float in [-40.0,-34.0,-28.0,-22.0,-16.0]:
  _part(Vector3(x,0.042,-2), Vector3(0.055,0.018,3.0), Color(0.46,0.31,0.23), true)
 # Paneled walls, picture lights and framed abstract art give navigational rhythm.
 for floor_y: float in [0.0,3.6]:
  for x: float in [-39.0,-33.0,-27.0,-21.0,-15.0]:
   for z: float in [-15.82,15.82]:
    _part(Vector3(x,floor_y+0.52,z), Vector3(5.5,0.95,0.06), walnut)
    _part(Vector3(x,floor_y+1.04,z), Vector3(5.5,0.06,0.08), bronze)
    _part(Vector3(x,floor_y+2.68,z), Vector3(5.5,0.05,0.08), bronze)
    for dx: float in [-2.35,2.35]:
     _part(Vector3(x+dx,floor_y+1.9,z),Vector3(0.055,1.45,0.06),ivory, true)
  # The small ceiling coves and fixtures are geometry, not extra shadow lights.
  for x: float in [-39.0,-33.0,-27.0,-21.0,-15.0]:
   _part(Vector3(x,floor_y+3.30,-2), Vector3(2.0,0.045,0.85), walnut)
   _part(Vector3(x,floor_y+3.27,-2), Vector3(1.65,0.025,0.57), Color(0.95,0.79,0.55))
   _part(Vector3(x,floor_y+3.23,-2), Vector3(0.65,0.04,0.14), Color(1.0,0.89,0.67), true)
 # Windows are stylised landscape panels with curtains on the public lounge side;
 # they don't cut holes into collision walls or imply an exterior accessible area.
 for x: float in [-38.0,-30.0,-22.0,-15.0]:
  for y: float in [0.91,2.95]:
   _part(Vector3(x,y,15.73),Vector3(3.7,0.10,0.10),walnut)
  _part(Vector3(x,1.50,15.62),Vector3(3.20,0.08,0.025),Color(0.43,0.47,0.42), true)
  for dx: float in [-1.83,1.83]:
   _part(Vector3(x+dx,1.95,15.55),Vector3(0.27,2.1,0.20),Color(0.45,0.38,0.32))
  _part(Vector3(x,2.08,15.60),Vector3(0.05,1.75,0.03),bronze)
 # A shallow original scenic backdrop gives the glazed bays an exterior read.
 # It is a vista only; it does not expand the accessible hotel footprint.
 _part(Vector3(-27,2.0,18.1),Vector3(31,4.0,0.08),Color(0.25,0.38,0.45))
 _part(Vector3(-27,0.55,17.95),Vector3(31,1.1,0.06),Color(0.17,0.30,0.34))
 for i: int in range(15):
  var x := -41.0 + float(i) * 2.0
  var height := 0.9 + float((i * 7) % 5) * 0.40
  _part(Vector3(x,height*0.5+0.55,17.8),Vector3(1.5,height,0.08),Color(0.16+float(i%3)*0.025,0.25,0.29))
  for row: int in range(2):
   for col: int in range(3):
    _part(Vector3(x-0.45+float(col)*0.45,0.85+float(row)*0.52,17.74),Vector3(0.13,0.19,0.02),Color(0.75,0.65,0.43),true)
 # Dining table bases and small metal place-setting details. Round plates and
 # cups are batched separately rather than represented by coloured squares.
 for x: float in [-38.0,-31.0,-24.0,-17.0]:
  _part(Vector3(x,0.16,-10),Vector3(1.9,0.30,0.9),walnut)
  for dx: float in [-0.8,0.8]:
   for side: float in [-1.0,1.0]:
    _part(Vector3(x+dx+side*0.24,1.025,-10),Vector3(0.025,0.014,0.30),bronze,true)
 _dining_crockery()
 for x: float in [-35.0,-19.0]:
  _part(Vector3(x,3.25,-10),Vector3(2.0,0.045,0.7),walnut)
  _part(Vector3(x,3.22,-10),Vector3(1.65,0.025,0.45),Color(1.0,0.82,0.58))
 # Framed prints and console cabinets subdivide the large room visually.
 for x: float in [-36.0,-26.0,-16.0]:
  _part(Vector3(x,1.85,-15.72),Vector3(2.25,1.4,0.08),bronze)
  _part(Vector3(x,1.85,-15.66),Vector3(2.04,1.19,0.04),Color(0.22,0.32,0.32))
  _part(Vector3(x-0.25,1.85,-15.62),Vector3(0.09,0.9,0.025),Color(0.77,0.55,0.34),true)
  _part(Vector3(x+0.25,1.85,-15.62),Vector3(0.09,0.7,0.025),Color(0.60,0.68,0.59),true)
 # Lounge tables, textiles and planters.
 for x: float in [-38.0,-30.0,-22.0,-15.0]:
  _part(Vector3(x,0.03,10),Vector3(3.3,0.018,3.3),Color(0.36,0.23,0.20))
 # Upper gallery door frames, floor runner, room numbers and suite furnishings.
 _part(Vector3(0,3.645,0),Vector3(23.5,0.018,2.7),carpet)
 for z: float in [-1.24,1.24]:
  _part(Vector3(0,3.66,z),Vector3(23.4,0.015,0.035),bronze)
 for x: float in [-9.0,-3.0,3.0,9.0]:
  for side: float in [-1.0,1.0]:
   for dx: float in [-0.72,0.72]:
    _part(Vector3(x+dx,5.12,side*3.91),Vector3(0.08,2.95,0.12),walnut)
   _part(Vector3(x,6.60,side*3.91),Vector3(1.50,0.09,0.12),walnut)
   _part(Vector3(x+1.15,5.45,side*3.89),Vector3(0.32,0.22,0.04),bronze)
   _part(Vector3(x,3.69,side*5.8),Vector3(3.5,0.03,3.4),Color(0.42,0.32,0.27),true)
 # Room numbers and furnishings establish the upstairs accommodation wing.
 for room_index: int in range(4):
  var x: float = [-9.0,-3.0,3.0,9.0][room_index]
  for side: float in [-1.0,1.0]:
   var room_id := 201 + room_index * 2 + (1 if side > 0.0 else 0)
   _sign(str(room_id), Vector3(x+1.15,5.45,side*3.85), Color(0.13,0.11,0.09), 0.0 if side < 0.0 else PI)
   _part(Vector3(x,4.74,side*7.35),Vector3(3.1,1.3,0.12),walnut)
   _part(Vector3(x,4.73,side*7.28),Vector3(2.85,1.03,0.04),Color(0.43,0.34,0.28))
   _part(Vector3(x-1.65,4.01,side*6.7),Vector3(0.58,0.82,0.6),walnut)
   _part(Vector3(x-1.65,4.53,side*6.7),Vector3(0.30,0.23,0.3),Color(0.84,0.75,0.59))
   _part(Vector3(x+2.3,5.1,side*5.1),Vector3(0.08,1.3,1.5),bronze)
   _part(Vector3(x+2.24,5.1,side*5.1),Vector3(0.04,1.1,1.3),Color(0.22,0.32,0.33))
 _sign("DINING  /  LOUNGE",Vector3(-19,2.65,-7.8),Color(0.92,0.79,0.56))
 _sign("GUEST ROOMS  /  PRIVATE SUITE",Vector3(-13.0,6.55,-1.5),Color(0.92,0.79,0.56),-PI / 2)
 # Locke's private suite: bed headboard, art, nightstands and warm reading lamps.
 _part(Vector3(-38,4.75,-12.12),Vector3(4.2,1.5,0.16),walnut)
 _part(Vector3(-38,4.70,-12.01),Vector3(3.8,1.15,0.06),Color(0.38,0.31,0.26))
 for x: float in [-40.5,-35.5]:
  _part(Vector3(x,3.98,-11.2),Vector3(0.72,0.76,0.72),walnut)
  _part(Vector3(x,4.43,-11.2),Vector3(0.07,0.38,0.07),bronze)
  _part(Vector3(x,4.68,-11.2),Vector3(0.42,0.20,0.42),Color(0.86,0.76,0.58))
 _part(Vector3(-38,5.75,-13.84),Vector3(3.0,1.0,0.06),bronze)
 _part(Vector3(-38,5.75,-13.79),Vector3(2.8,0.8,0.04),Color(0.25,0.34,0.32))
 _part(Vector3(-41.8,5.0,-9.0),Vector3(0.08,1.8,2.6),walnut)
 _part(Vector3(-41.72,5.0,-9.0),Vector3(0.035,1.55,2.35),Color(0.24,0.35,0.39))

func _annex() -> void:
 # A cooler training facility with numbered assessment lanes and observation desks.
 for x: float in [-11.5, -8.5, -5.5, -2.5, 4.5, 10.5]:
  _part(Vector3(x, 1.5, -9.75), Vector3(2.1, 2.45, 0.08), Color(0.25, 0.31, 0.31))
  _part(Vector3(x, 2.55, -9.68), Vector3(1.85, 0.07, 0.05), Color(0.48, 0.68, 0.66))
  _part(Vector3(x, 0.34, -9.68), Vector3(1.85, 0.35, 0.05), DARK)
 for z: float in [-6.8, 6.8]:
  _part(Vector3(-6.0, 0.04, z), Vector3(14.0, 0.015, 0.05), Color(0.58, 0.68, 0.59))
 for x: float in [-11.0, -8.0, -5.0, -2.0]:
  _part(Vector3(x, 0.04, 0), Vector3(0.035, 0.015, 12), Color(0.39, 0.49, 0.46), true)
 _sign("CIVIC EVALUATION  /  ASSESSMENT", Vector3(-8, 2.1, -9.58), Color(0.73, 0.88, 0.83))
 _sign("OBSERVATION", Vector3(4.5, 2.1, -9.58), Color(0.73, 0.88, 0.83))
 _sign("CONTROLLED AREA", Vector3(10.5, 2.1, -9.58), Color(0.92, 0.69, 0.42))
 for x: float in [-10.0, 4.5, 10.0]:
  _part(Vector3(x, 1.0, -7), Vector3(2.6, 0.08, 1.1), Color(0.53, 0.56, 0.53))
  _part(Vector3(x, 1.25, -7.3), Vector3(0.7, 0.42, 0.08), DARK)
  _part(Vector3(x, 1.26, -7.25), Vector3(0.58, 0.31, 0.02), TEAL)
 for x: float in [2.14, 6.86, 7.14]:
  for z: float in [-7.0, 0.0, 7.0]:
   _part(Vector3(x, 0.48, z), Vector3(0.04, 0.80, 3.7), Color(0.20, 0.27, 0.27))
   _part(Vector3(x, 0.92, z), Vector3(0.06, 0.05, 3.7), Color(0.46, 0.62, 0.60))
 _part(Vector3(-14.82, 1.4, 7), Vector3(0.06, 2.7, 1.5), DARK)
 _part(Vector3(-14.76, 1.4, 7), Vector3(0.05, 2.5, 1.3), TEAL)
 _sign("EXIT", Vector3(-14.68, 2.65, 7), Color(0.77, 0.85, 0.70), PI / 2)
 for x: float in [-9.0, -3.0, 4.5, 10.5]:
  _lamp(Vector3(x, 2.6, 0), Color(0.66, 0.84, 0.90), 0.35, 6.0)
