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

func _ready() -> void:
 var collision := CollisionShape3D.new()
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
 crouching = Input.is_action_pressed("crouch")
 var speed := crouch_speed if crouching else (run_speed if Input.is_action_pressed("sprint") else walk_speed)
 velocity.x = move_toward(velocity.x, direction.x * speed, 12.0 * delta)
 velocity.z = move_toward(velocity.z, direction.z * speed, 12.0 * delta)
 if not is_on_floor(): velocity.y -= 9.8 * delta
 else: velocity.y = -0.1
 move_and_slide()
