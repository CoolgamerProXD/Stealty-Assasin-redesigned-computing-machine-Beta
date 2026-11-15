class_name StylizedPerson
extends Node3D
## Original low-poly procedural character. Limbs are animated independent nodes.
var role: String = "visitor"
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var torso: MeshInstance3D
var weapon: Node3D
var muzzle_flash: MeshInstance3D
var weapon_recoil: float = 0.0
var weapon_aiming: bool = false
var weapon_equipped: bool = false
var weapon_draw: float = 0.0
var weapon_aim_blend: float = 0.0
var phase: float = 0.0
var clothing: StandardMaterial3D

func _ready() -> void:
 var skin := _material(Color(0.68, 0.46, 0.34))
 var dark := _material(Color(0.12, 0.13, 0.15))
 clothing = _material(_role_color())
 var trousers := _material(Color(0.16, 0.18, 0.20))
 torso = _box(self, Vector3(0, 1.22, 0), Vector3(0.48, 0.60, 0.24), clothing)
 _box(self, Vector3(0, 0.91, 0), Vector3(0.42, 0.16, 0.23), trousers)
 _box(self, Vector3(0, 1.56, 0), Vector3(0.14, 0.12, 0.14), skin)
 var head := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 0.15
 sphere.height = 0.33
 head.mesh = sphere
 head.position = Vector3(0, 1.73, 0)
 head.material_override = skin
 add_child(head)
 _box(self, Vector3(0, 1.88, 0.015), Vector3(0.28, 0.07, 0.23), dark)
 var eye := _material(Color(0.08, 0.09, 0.10))
 _box(self, Vector3(-0.055, 1.76, -0.143), Vector3(0.035, 0.025, 0.015), eye)
 _box(self, Vector3(0.055, 1.76, -0.143), Vector3(0.035, 0.025, 0.015), eye)
 _box(self, Vector3(0, 1.72, -0.158), Vector3(0.035, 0.045, 0.04), skin)
 _box(self, Vector3(0, 1.66, -0.143), Vector3(0.07, 0.012, 0.015), dark)
 # Lapels, collar and belt establish clothed silhouettes instead of a capsule.
 _box(self, Vector3(0, 1.38, -0.127), Vector3(0.12, 0.27, 0.02), _material(Color(0.78, 0.77, 0.70)))
 _box(self, Vector3(0, 0.98, -0.13), Vector3(0.40, 0.06, 0.025), dark)
 left_leg = _limb(Vector3(-0.12, 0.88, 0), Vector3(0.16, 0.76, 0.18), trousers)
 right_leg = _limb(Vector3(0.12, 0.88, 0), Vector3(0.16, 0.76, 0.18), trousers)
 _box(left_leg, Vector3(0, -0.82, -0.06), Vector3(0.18, 0.12, 0.30), dark)
 _box(right_leg, Vector3(0, -0.82, -0.06), Vector3(0.18, 0.12, 0.30), dark)
 left_arm = _limb(Vector3(-0.31, 1.47, 0), Vector3(0.14, 0.54, 0.16), clothing)
 right_arm = _limb(Vector3(0.31, 1.47, 0), Vector3(0.14, 0.54, 0.16), clothing)
 _box(left_arm, Vector3(0, -0.57, 0), Vector3(0.12, 0.13, 0.13), skin)
 _box(right_arm, Vector3(0, -0.57, 0), Vector3(0.12, 0.13, 0.13), skin)
 if role == "security":
  _box(self, Vector3(0, 1.95, 0), Vector3(0.34, 0.07, 0.28), dark)
 if role == "ruby":
  _box(self, Vector3(0, 1.61, 0.12), Vector3(0.29, 0.48, 0.09), dark)
  _box(self, Vector3(0, 1.03, 0.02), Vector3(0.48, 0.40, 0.25), clothing)
  _box(self, Vector3(0, 1.40, -0.15), Vector3(0.06, 0.24, 0.02), _material(Color(0.68, 0.41, 0.32)))
 if role == "manager":
  _box(self, Vector3(0, 1.38, -0.15), Vector3(0.06, 0.29, 0.025), _material(Color(0.68, 0.42, 0.20)))
  _box(self, Vector3(-0.13, 1.45, -0.15), Vector3(0.09, 0.06, 0.02), _material(Color(0.85, 0.67, 0.31)))

# Original stylized assessment sidearm, attached to the animated hand joint.
func add_sidearm() -> void:
 if weapon: return
 weapon = Node3D.new()
 weapon.position = Vector3(0, -0.58, -0.04)
 right_arm.add_child(weapon)
 var metal := _material(Color(0.12, 0.15, 0.18))
 var accent := _material(Color(0.36, 0.54, 0.58))
 _box(weapon, Vector3(0, -0.16, 0), Vector3(0.10, 0.34, 0.10), metal)
 _box(weapon, Vector3(0, -0.13, 0.07), Vector3(0.08, 0.13, 0.10), accent)
 var flash_mat := _material(Color(1.0, 0.85, 0.32))
 flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 muzzle_flash = _box(weapon, Vector3(0, -0.38, 0), Vector3(0.13, 0.14, 0.13), flash_mat)
 muzzle_flash.visible = false

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
 phase += delta * (3.0 + minf(speed, 5.0) * 3.0)
 var swing := sin(phase) * minf(speed * 0.16, 0.6)
 var blend := 1.0 - exp(-delta * 10.0)
 weapon_draw = move_toward(weapon_draw, 1.0 if weapon_equipped else 0.0, delta * 3.0)
 weapon_aim_blend = move_toward(weapon_aim_blend, 1.0 if weapon_aiming and weapon_equipped else 0.0, delta * 4.0)
 torso.rotation.z = sin(phase * 0.5) * 0.008
 torso.rotation.x = sin(phase * 0.5) * 0.008
 left_leg.rotation.x = lerp_angle(left_leg.rotation.x, swing, blend)
 right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -swing, blend)
 left_arm.rotation.x = lerp_angle(left_arm.rotation.x, lerpf(-swing * 0.7, 1.05, weapon_aim_blend), blend)
 left_arm.rotation.z = lerp_angle(left_arm.rotation.z, -0.20 * weapon_aim_blend, blend)
 var ready_pose := lerpf(0.35, 1.35, weapon_aim_blend)
 var right_pose := lerpf(swing * 0.7, ready_pose, weapon_draw)
 right_pose -= weapon_recoil * 0.35
 right_arm.rotation.x = lerp_angle(right_arm.rotation.x, right_pose, blend)
 if weapon:
  weapon.visible = weapon_draw > 0.03
  muzzle_flash.visible = weapon_draw > 0.5 and weapon_recoil > 0.72
 weapon_recoil = maxf(0.0, weapon_recoil - delta * 6.0)

func _material(color: Color) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.85
 return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 part.mesh = mesh
 part.material_override = mat
 part.position = pos
 parent.add_child(part)
 return part

func _limb(pos: Vector3, size: Vector3, mat: Material) -> Node3D:
 var joint := Node3D.new()
 joint.position = pos
 add_child(joint)
 _box(joint, Vector3(0, -size.y * 0.5, 0), size, mat)
 return joint
