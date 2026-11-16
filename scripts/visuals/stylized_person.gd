class_name StylizedPerson
extends Node3D
## Original low-poly procedural character. Limbs are animated independent nodes.
var role: String = "visitor"
var appearance_seed: int = 0
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
var upper_body: Node3D
var crouch_amount: float = 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
var gait_speed: float = 0.0
var torso: MeshInstance3D
var weapon: Node3D
var muzzle_flash: MeshInstance3D
var quiet_tool: Node3D
var quiet_tool_equipped: bool = false
var quiet_tool_draw: float = 0.0
var quiet_tool_action: float = 0.0
var weapon_recoil: float = 0.0
var weapon_aiming: bool = false
var weapon_equipped: bool = false
var weapon_draw: float = 0.0
var weapon_aim_blend: float = 0.0
var phase: float = 0.0
var idle_phase: float = 0.0
var idle_activity: String = "idle"
var ground_adjust: float = 0.0
var clothing: StandardMaterial3D
# Identical immutable primitive meshes are reused across the population. Each
# person retains independent materials, transforms and animated joints.
static var primitive_meshes: Dictionary = {}
static var jacket_mesh: ArrayMesh

func _ready() -> void:
 upper_body = Node3D.new()
 upper_body.name = "UpperBody"
 add_child(upper_body)
 var skin_variants: Array[Color] = [Color(0.68, 0.46, 0.34), Color(0.46, 0.29, 0.23), Color(0.76, 0.57, 0.46), Color(0.56, 0.39, 0.30)]
 var hair_variants: Array[Color] = [Color(0.12, 0.13, 0.15), Color(0.23, 0.15, 0.12), Color(0.10, 0.09, 0.08)]
 var skin := _material(skin_variants[absi(appearance_seed) % skin_variants.size()])
 var dark := _material(hair_variants[absi(appearance_seed) % hair_variants.size()])
 clothing = _material(_role_color())
 var trousers := _material(Color(0.16, 0.18, 0.20))
 torso = _box(upper_body, Vector3(0, 1.22, 0), Vector3(0.48, 0.60, 0.24), clothing)
 torso.mesh = _jacket_mesh()
 _box(upper_body, Vector3(0, 0.91, 0), Vector3(0.42, 0.16, 0.23), trousers)
 _box(upper_body, Vector3(0, 1.56, 0), Vector3(0.14, 0.12, 0.14), skin)
 var head := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 0.15
 sphere.height = 0.33
 sphere.radial_segments = 16
 sphere.rings = 8
 head.mesh = sphere
 head.position = Vector3(0, 1.73, 0)
 head.material_override = skin
 upper_body.add_child(head)
 _ellipsoid(upper_body, Vector3(0, 1.87, 0.015), Vector3(0.29, 0.11, 0.27), dark)
 var eye := _material(Color(0.08, 0.09, 0.10))
 _box(upper_body, Vector3(-0.055, 1.76, -0.143), Vector3(0.035, 0.025, 0.015), eye)
 _box(upper_body, Vector3(0.055, 1.76, -0.143), Vector3(0.035, 0.025, 0.015), eye)
 _box(upper_body, Vector3(0, 1.72, -0.158), Vector3(0.035, 0.045, 0.04), skin)
 _box(upper_body, Vector3(0, 1.66, -0.143), Vector3(0.07, 0.012, 0.015), dark)
 # Lapels, collar and belt establish clothed silhouettes instead of a capsule.
 _box(upper_body, Vector3(0, 1.38, -0.127), Vector3(0.12, 0.27, 0.02), _material(Color(0.78, 0.77, 0.70)))
 _box(upper_body, Vector3(0, 0.98, -0.13), Vector3(0.40, 0.06, 0.025), dark)
 # Visible jacket seams, collar and a small lapel accent give the silhouette
 # structure without introducing any imported assets.
 for x: float in [-0.17, 0.17]:
  _box(upper_body, Vector3(x, 1.26, -0.13), Vector3(0.025, 0.38, 0.02), dark)
 _box(upper_body, Vector3(0, 1.48, -0.13), Vector3(0.20, 0.06, 0.025), skin)
 left_leg = _leg(Vector3(-0.12, 0.88, 0), trousers, dark)
 right_leg = _leg(Vector3(0.12, 0.88, 0), trousers, dark)
 left_knee = left_leg.get_node("Knee")
 right_knee = right_leg.get_node("Knee")
 left_arm = _arm(Vector3(-0.29, 1.47, 0), clothing, skin)
 right_arm = _arm(Vector3(0.29, 1.47, 0), clothing, skin)
 left_elbow = left_arm.get_node("Elbow")
 right_elbow = right_arm.get_node("Elbow")
 if role == "security":
  _box(upper_body, Vector3(-0.14, 1.40, -0.15), Vector3(0.09, 0.08, 0.02), _material(Color(0.68, 0.72, 0.65)))
  _box(upper_body, Vector3(0, 1.95, 0), Vector3(0.34, 0.07, 0.28), dark)
 if role == "ruby":
  _box(upper_body, Vector3(0, 1.61, 0.12), Vector3(0.29, 0.48, 0.09), dark)
  _box(upper_body, Vector3(0, 1.03, 0.02), Vector3(0.48, 0.40, 0.25), clothing)
  _box(upper_body, Vector3(0, 1.40, -0.15), Vector3(0.06, 0.24, 0.02), _material(Color(0.68, 0.41, 0.32)))
 if role == "manager":
  _box(upper_body, Vector3(0, 1.38, -0.15), Vector3(0.06, 0.29, 0.025), _material(Color(0.68, 0.42, 0.20)))
  _box(upper_body, Vector3(-0.13, 1.45, -0.15), Vector3(0.09, 0.06, 0.02), _material(Color(0.85, 0.67, 0.31)))

# Original stylized assessment sidearm, attached to the animated hand joint.
func add_sidearm() -> void:
 if weapon: return
 weapon = Node3D.new()
 weapon.position = Vector3(0, -0.30, -0.04)
 right_elbow.add_child(weapon)
 var metal := _material(Color(0.12, 0.15, 0.18))
 var accent := _material(Color(0.36, 0.54, 0.58))
 _box(weapon, Vector3(0, -0.16, 0), Vector3(0.10, 0.34, 0.10), metal)
 _box(weapon, Vector3(0, -0.13, 0.07), Vector3(0.08, 0.13, 0.10), accent)
 # Project-original stylised device: a separate grip, casing and front sight.
 _box(weapon, Vector3(0, -0.04, 0.085), Vector3(0.085, 0.18, 0.09), metal)
 _box(weapon, Vector3(0, -0.25, -0.055), Vector3(0.07, 0.17, 0.025), accent)
 _box(weapon, Vector3(0, -0.34, -0.03), Vector3(0.04, 0.03, 0.04), metal)
 var flash_mat := _material(Color(1.0, 0.85, 0.32))
 flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 muzzle_flash = _box(weapon, Vector3(0, -0.38, 0), Vector3(0.13, 0.14, 0.13), flash_mat)
 muzzle_flash.visible = false

# An abstract coiled Quiet Line device is a visual cue for the existing
# non-graphic fictional gadget. It does not add or change equipment mechanics.
func add_quiet_tool() -> void:
 if quiet_tool: return
 quiet_tool = Node3D.new()
 quiet_tool.position = Vector3(0,-0.30,-0.03)
 left_elbow.add_child(quiet_tool)
 var ring := MeshInstance3D.new()
 var mesh := TorusMesh.new()
 mesh.inner_radius = 0.075
 mesh.outer_radius = 0.105
 mesh.rings = 12
 mesh.ring_segments = 6
 ring.mesh = mesh
 ring.rotation.x = PI / 2.0
 ring.material_override = _material(Color(0.55,0.64,0.59))
 quiet_tool.add_child(ring)
 var grip := _material(Color(0.12,0.18,0.19))
 for side: float in [-1.0,1.0]:
  _box(quiet_tool, Vector3(side*0.095,-0.02,0), Vector3(0.045,0.13,0.05), grip)
 quiet_tool.visible = false

func use_quiet_tool() -> void:
 quiet_tool_action = 1.0

func fire_weapon() -> void:
 weapon_recoil = 1.0

func _role_color() -> Color:
 match role:
  "security": return Color(0.17, 0.25, 0.34)
  "employee", "staff": return Color(0.28, 0.38, 0.43)
  "civilian": return Color(0.58, 0.38, 0.24)
  "ruby": return Color(0.31, 0.15, 0.19)
  "manager": return Color(0.31, 0.24, 0.16)
  _: return Color(0.20, 0.21, 0.25)

func set_role(value: String) -> void:
 role = value
 if clothing: clothing.albedo_color = _role_color()

func animate_motion(delta: float, speed: float) -> void:
 if not left_leg: return
 var blend := 1.0 - exp(-delta * 10.0)
 gait_speed = lerpf(gait_speed, speed, 1.0 - exp(-delta * 8.0))
 phase += delta * minf(gait_speed, 5.0) * 2.6
 idle_phase += delta * 2.0
 var swing := sin(phase) * minf(gait_speed * 0.16, 0.6)
 weapon_draw = move_toward(weapon_draw, 1.0 if weapon_equipped else 0.0, delta * 3.0)
 quiet_tool_draw = move_toward(quiet_tool_draw, 1.0 if quiet_tool_equipped else 0.0, delta * 3.0)
 weapon_aim_blend = move_toward(weapon_aim_blend, 1.0 if weapon_aiming and weapon_equipped else 0.0, delta * 4.0)
 torso.rotation.z = sin(idle_phase * 0.5) * 0.008
 torso.rotation.x = sin(idle_phase * 0.5) * 0.008
 # Independent knees bend during swing and crouch. Torso descends without
 # squashing the head or changing the model's horizontal proportions.
 upper_body.position.y = lerpf(upper_body.position.y, -0.70 * crouch_amount + ground_adjust, blend)
 var lean := -0.055 * clampf((gait_speed - 2.7) / 2.0, 0.0, 1.0) - 0.08 * crouch_amount
 upper_body.rotation.x = lerp_angle(upper_body.rotation.x, lean, blend)
 left_leg.position.y = lerpf(left_leg.position.y, 0.88 - 0.52 * crouch_amount + ground_adjust, blend)
 right_leg.position.y = left_leg.position.y
 var stride := swing * (1.0 - 0.45 * crouch_amount)
 left_leg.rotation.x = lerp_angle(left_leg.rotation.x, stride + 1.40 * crouch_amount, blend)
 right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -stride + 1.40 * crouch_amount, blend)
 left_knee.rotation.x = lerp_angle(left_knee.rotation.x, -2.80 * crouch_amount - maxf(0.0, -swing) * 0.65, blend)
 right_knee.rotation.x = lerp_angle(right_knee.rotation.x, -2.80 * crouch_amount - maxf(0.0, swing) * 0.65, blend)
 # Compensate the procedural stride for the lowest shoe, without moving the
 # collision capsule. This is a small visual hip offset, not full terrain IK.
 # Both feet previously floated together at the extremes of a stride.
 var low_foot := minf(_shoe_bottom(left_leg, left_knee), _shoe_bottom(right_leg, right_knee))
 var correction := clampf(-low_foot, -0.20, 0.20)
 if crouch_amount < 0.05: correction *= clampf(gait_speed / 0.5, 0.0, 1.0)
 var adjustment_delta := correction - ground_adjust
 upper_body.position.y += adjustment_delta
 left_leg.position.y += adjustment_delta
 right_leg.position.y += adjustment_delta
 ground_adjust = correction
 var left_pose := -swing * 0.7
 if speed < 0.1 and idle_activity == "warning": left_pose = 0.95 + sin(idle_phase * 0.6) * 0.08
 elif speed < 0.1 and idle_activity == "seeking_help": left_pose = 0.58 + sin(idle_phase * 0.9) * 0.12
 elif speed < 0.1 and idle_activity == "conversing": left_pose = 0.30 + sin(idle_phase * 0.6) * 0.16
 elif speed < 0.1 and idle_activity == "working": left_pose = 0.40 + sin(idle_phase * 0.5) * 0.06
 left_pose = lerpf(left_pose, 0.40 + quiet_tool_action * 0.35, quiet_tool_draw)
 left_arm.rotation.x = lerp_angle(left_arm.rotation.x, lerpf(left_pose, 1.05, weapon_aim_blend), blend)
 left_arm.rotation.z = lerp_angle(left_arm.rotation.z, -0.20 * weapon_aim_blend, blend)
 var ready_pose := lerpf(0.35, 1.35, weapon_aim_blend)
 var right_pose := lerpf(swing * 0.7, ready_pose, weapon_draw)
 right_pose -= weapon_recoil * 0.35
 right_arm.rotation.x = lerp_angle(right_arm.rotation.x, right_pose, blend)
 # Elbows bend subtly during the stride and extend as the device is presented.
 left_elbow.rotation.x = lerp_angle(left_elbow.rotation.x, lerpf(-0.15 - absf(swing) * 0.20, -0.36, weapon_aim_blend), blend)
 right_elbow.rotation.x = lerp_angle(right_elbow.rotation.x, lerpf(-0.15 - absf(swing) * 0.20, -0.12, weapon_draw), blend)
 if quiet_tool: quiet_tool.visible = quiet_tool_draw > 0.03
 quiet_tool_action = maxf(0.0, quiet_tool_action - delta * 3.0)
 if weapon:
  weapon.visible = weapon_draw > 0.03
  muzzle_flash.visible = weapon_draw > 0.5 and weapon_recoil > 0.72
 weapon_recoil = maxf(0.0, weapon_recoil - delta * 6.0)

# Approximate the low point of the rotating ellipsoid shoe in character-local
# space. The shared root is already grounded by CharacterBody3D; we deliberately
# remove last frame's visual adjustment before computing the next one.
func _shoe_bottom(hip: Node3D, knee: Node3D) -> float:
 var thigh_angle := hip.rotation.x
 var foot_angle := thigh_angle + knee.rotation.x
 var center_y := hip.position.y - ground_adjust - 0.39 * cos(thigh_angle) - 0.42 * cos(foot_angle) + 0.06 * sin(foot_angle)
 var radius_y := 0.5 * sqrt(pow(0.12 * cos(foot_angle), 2.0) + pow(0.30 * sin(foot_angle), 2.0))
 return center_y - radius_y

func _jacket_mesh() -> ArrayMesh:
 if jacket_mesh: return jacket_mesh
 # Tapered shoulders and waist, flat normals: original low-poly tailoring.
 var points: Array[Vector3] = [
  Vector3(-0.20, -0.30, -0.12), Vector3(0.20, -0.30, -0.12),
  Vector3(0.25, 0.30, -0.12), Vector3(-0.25, 0.30, -0.12),
  Vector3(-0.20, -0.30, 0.12), Vector3(0.20, -0.30, 0.12),
  Vector3(0.25, 0.30, 0.12), Vector3(-0.25, 0.30, 0.12)]
 var faces := PackedInt32Array([0, 2, 1, 0, 3, 2, 5, 6, 4, 6, 7, 4, 4, 3, 0, 4, 7, 3, 1, 2, 5, 2, 6, 5, 3, 7, 2, 7, 6, 2, 4, 0, 5, 0, 1, 5])
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index: int in faces: surface.add_vertex(points[index])
 surface.generate_normals()
 jacket_mesh = surface.commit()
 return jacket_mesh

func _material(color: Color) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.85
 return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 var key := "box:" + str(size)
 if not primitive_meshes.has(key):
  var mesh := BoxMesh.new()
  mesh.size = size
  primitive_meshes[key] = mesh
 part.mesh = primitive_meshes[key]
 part.material_override = mat
 part.position = pos
 parent.add_child(part)
 return part

func _ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 if not primitive_meshes.has("ellipsoid"):
  var mesh := SphereMesh.new()
  mesh.radius = 0.5
  mesh.height = 1.0
  mesh.radial_segments = 10
  mesh.rings = 5
  primitive_meshes["ellipsoid"] = mesh
 part.mesh = primitive_meshes["ellipsoid"]
 part.scale = size
 part.position = pos
 part.material_override = mat
 parent.add_child(part)
 return part

func _tapered(parent: Node3D, pos: Vector3, top_radius: float, bottom_radius: float, length: float, mat: Material) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 var key := "taper:" + str(Vector3(top_radius,bottom_radius,length))
 if not primitive_meshes.has(key):
  var mesh := CylinderMesh.new()
  mesh.top_radius = top_radius
  mesh.bottom_radius = bottom_radius
  mesh.height = length
  mesh.radial_segments = 8
  primitive_meshes[key] = mesh
 part.mesh = primitive_meshes[key]
 part.position = pos
 part.material_override = mat
 parent.add_child(part)
 return part

func _arm(pos: Vector3, fabric: Material, skin: Material) -> Node3D:
 var shoulder := Node3D.new()
 shoulder.position = pos
 upper_body.add_child(shoulder)
 _ellipsoid(shoulder, Vector3(0,-0.025,0), Vector3(0.19,0.19,0.19), fabric)
 _tapered(shoulder, Vector3(0,-0.14,0), 0.082, 0.065, 0.28, fabric)
 var elbow := Node3D.new()
 elbow.name = "Elbow"
 elbow.position.y = -0.28
 shoulder.add_child(elbow)
 _tapered(elbow, Vector3(0,-0.13,0), 0.067, 0.055, 0.26, fabric)
 _ellipsoid(elbow, Vector3(0,-0.30,0), Vector3(0.12,0.14,0.13), skin)
 return shoulder

func _leg(pos: Vector3, trousers: Material, shoes: Material) -> Node3D:
 var hip := Node3D.new()
 hip.position = pos
 add_child(hip)
 _tapered(hip, Vector3(0,-0.195,0), 0.09, 0.072, 0.39, trousers)
 var knee := Node3D.new()
 knee.name = "Knee"
 knee.position = Vector3(0,-0.39,0)
 hip.add_child(knee)
 _tapered(knee, Vector3(0,-0.195,0), 0.072, 0.055, 0.39, trousers)
 _ellipsoid(knee, Vector3(0,-0.42,-0.06), Vector3(0.18,0.12,0.30), shoes)
 return hip
