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
 if id == "meridian": _hotel()
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
 _sofa(-7.8, 2.1)
 _sofa(-4.8, 3.7)
 _part(Vector3(-7.0, 0.40, 3.2), Vector3(1.25, 0.08, 0.70), WOOD)
 for x: float in [-7.5, -6.5]: _part(Vector3(x, 0.20, 3.2), Vector3(0.06, 0.4, 0.06), BRASS)
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
 _lamp(Vector3(-6, 2.65, -3.5), Color(1.0, 0.70, 0.42), 0.55, 7.0)
 _lamp(Vector3(-5, 2.65, 3), Color(1.0, 0.73, 0.48), 0.45, 7.0)
 _lamp(Vector3(4.5, 2.6, 0), Color(0.65, 0.82, 1.0), 0.35, 6.0)
 _lamp(Vector3(9.5, 2.6, 0), Color(0.65, 0.82, 1.0), 0.35, 6.0)

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
 for x: float in [-9.0, -3.0, 4.5, 10.5]:
  _lamp(Vector3(x, 2.6, 0), Color(0.66, 0.84, 0.90), 0.35, 6.0)
