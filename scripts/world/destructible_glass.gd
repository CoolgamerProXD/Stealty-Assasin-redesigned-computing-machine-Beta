class_name DestructibleGlass
extends StaticBody3D
## Reusable, low-cost fictional glazing: a pulse disables the pane collider and
## emits a handful of non-physical fragments that fade within 1.25 seconds.
var collider: CollisionShape3D
var pane: MeshInstance3D
var pane_size := Vector3(1.0, 1.0, 0.05)
var lifetime := 0.0
var fragments: Array[Dictionary] = []
var broken: bool = false

func configure(size: Vector3, tint: Color = Color(0.40, 0.70, 0.76, 0.62)) -> void:
 pane_size = size
 collision_layer = 1
 collision_mask = 1
 collider = CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collider.shape = shape
 add_child(collider)
 pane = MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 pane.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = tint
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.roughness = 0.18
 material.metallic = 0.12
 pane.material_override = material
 pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(pane)

func break_glass() -> bool:
 if broken or not is_inside_tree(): return false
 broken = true
 collider.set_deferred("disabled", true)
 collision_layer = 0
 pane.visible = false
 var material := pane.material_override as StandardMaterial3D
 for index: int in range(8):
  var fragment := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = Vector3(pane_size.x / 3.6, pane_size.y / 3.0, 0.035)
  fragment.mesh = mesh
  fragment.material_override = material
  fragment.position = Vector3(
   (float(index % 4) - 1.5) * pane_size.x / 4.0,
   (float(index / 4) - 0.5) * pane_size.y / 2.0,
   0.04
  )
  add_child(fragment)
  var velocity := Vector3(
   (float(index % 4) - 1.5) * 0.55,
   1.1 + float(index % 3) * 0.18,
   0.4 + float(index % 2) * 0.25
  )
  fragments.append({"node": fragment, "velocity": velocity})
 set_process(true)
 return true

func _process(delta: float) -> void:
 if not broken: return
 lifetime += delta
 for piece: Dictionary in fragments:
  var fragment := piece["node"] as Node3D
  var velocity: Vector3 = piece["velocity"]
  velocity.y -= 4.5 * delta
  piece["velocity"] = velocity
  fragment.position += velocity * delta
  fragment.rotation += Vector3(delta * 1.8, delta * 2.2, delta * 1.4)
 if lifetime >= 1.25:
  queue_free()
