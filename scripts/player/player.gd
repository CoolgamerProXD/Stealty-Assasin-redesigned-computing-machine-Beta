class_name HotelPlayer
extends CharacterBody3D
signal interaction_requested
var role: String = "visitor"
var inventory: Inventory = Inventory.new()
var walk_speed: float = 2.7
var run_speed: float = 4.7
var crouch_speed: float = 1.5
var mouse_sensitivity: float = 0.0025
var pivot: Node3D
var camera: Camera3D
var body_mesh: MeshInstance3D
var crouching: bool = false
var collision_shape: CollisionShape3D
var stance_height: float = 1.8

func _ready() -> void:
 var collision := CollisionShape3D.new()
 collision_shape = collision
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.34
 capsule.height = 1.8
 collision.shape = capsule
 collision.position.y = 0.9
 add_child(collision)
 body_mesh = MeshInstance3D.new()
 var mesh := CapsuleMesh.new()
 mesh.radius = 0.32
 mesh.height = 1.8
 body_mesh.mesh = mesh
 body_mesh.position.y = 0.9
 add_child(body_mesh)
 set_disguise("visitor")
 pivot = Node3D.new()
 pivot.position.y = 1.5
 add_child(pivot)
 var arm := SpringArm3D.new()
 arm.spring_length = 4.0
 arm.margin = 0.2
 pivot.add_child(arm)
 arm.add_excluded_object(get_rid())
 camera = Camera3D.new()
 arm.add_child(camera)
 camera.current = true
 pivot.rotation.x = -0.22
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_disguise(new_role: String) -> void:
 role = new_role
 if body_mesh:
  var material := StandardMaterial3D.new()
  material.albedo_color = Color(0.22, 0.36, 0.48) if role == "staff" else Color(0.18, 0.18, 0.21)
  body_mesh.material_override = material

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  rotate_y(-event.relative.x * mouse_sensitivity)
  pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -0.95, 0.55)
 if event.is_action_pressed("release_mouse"):
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 if event.is_action_pressed("interact"):
  interaction_requested.emit()

func _physics_process(delta: float) -> void:
 var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
 var direction := transform.basis * Vector3(input.x, 0, input.y)
 var wants_crouch := Input.is_action_pressed("crouch")
 if not wants_crouch and stance_height < 1.79:
  wants_crouch = not _can_stand()
 crouching = wants_crouch
 stance_height = move_toward(stance_height, 1.15 if crouching else 1.8, delta * 3.0)
 var capsule := collision_shape.shape as CapsuleShape3D
 capsule.height = stance_height
 collision_shape.position.y = stance_height * 0.5
 body_mesh.scale.y = stance_height / 1.8
 body_mesh.position.y = stance_height * 0.5
 pivot.position.y = 1.5 * stance_height / 1.8
 var speed := crouch_speed if crouching else (run_speed if Input.is_action_pressed("sprint") else walk_speed)
 velocity.x = move_toward(velocity.x, direction.x * speed, 12.0 * delta)
 velocity.z = move_toward(velocity.z, direction.z * speed, 12.0 * delta)
 if not is_on_floor(): velocity.y -= 9.8 * delta
 else: velocity.y = -0.1
 move_and_slide()

# Test the full standing capsule against real geometry; never grow through a ceiling.
func _can_stand() -> bool:
 var shape := CapsuleShape3D.new()
 shape.radius = 0.34
 shape.height = 1.8
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape = shape
 query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.9)
 query.exclude = [get_rid()]
 query.collision_mask = collision_mask
 return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
