class_name HotelPlayer
extends CharacterBody3D
signal interaction_requested
signal equipment_use_requested
signal coin_requested
signal equipment_selected(slot: int)
signal fire_requested
signal disguise_requested
var role: String = "visitor"
var outfit_id: String = "civilian"
var outfit_inventory: Array[String] = ["civilian"]
var inventory: Inventory = Inventory.new()
var equipment: MissionEquipment = MissionEquipment.new()
var walk_speed: float = 2.7
var run_speed: float = 4.7
var crouch_speed: float = 1.5
var mouse_sensitivity: float = 0.0025
var pivot: Node3D
var camera: Camera3D
var arm: SpringArm3D
var aiming: bool = false
var instinct_active: bool = false
var body_mesh: StylizedPerson
var crouching: bool = false
var sprinting: bool = false
var collision_shape: CollisionShape3D
var stance_height: float = 1.8
var camera_kick: float = 0.0
var stagger_remaining: float = 0.0
var last_footstep_index: int = 0
var footsteps: AudioStreamPlayer3D
var step_streams: Dictionary = {}

func _ready() -> void:
 var collision := CollisionShape3D.new()
 collision_shape = collision
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.34
 capsule.height = 1.8
 collision.shape = capsule
 collision.position.y = 0.9
 add_child(collision)
 body_mesh = StylizedPerson.new()
 body_mesh.role = "visitor"
 add_child(body_mesh)
 var wardrobe_campaign_service := get_node_or_null("/root/Campaign")
 if wardrobe_campaign_service and wardrobe_campaign_service.get("progress"):
  var progress: CampaignProgress = wardrobe_campaign_service.get("progress")
  outfit_inventory.assign(["civilian"])
  for outfit_variant: Variant in progress.acquired_outfits:
   var outfit_name := str(outfit_variant)
   if DisguiseSystem.has_outfit(outfit_name) and not outfit_inventory.has(outfit_name): outfit_inventory.append(outfit_name)
  equip_outfit(progress.equipped_outfit)
 else:
  equip_outfit("civilian")
 body_mesh.add_sidearm()
 body_mesh.add_quiet_tool()
 pivot = Node3D.new()
 pivot.position.y = 1.5
 add_child(pivot)
 arm = SpringArm3D.new()
 arm.spring_length = 4.0
 arm.margin = 0.2
 pivot.add_child(arm)
 arm.add_excluded_object(get_rid())
 camera = Camera3D.new()
 # Player is also compiled by standalone test scripts before autoloads are
 # resolved, so look up the optional runtime service rather than statically
 # binding the Campaign singleton from this reusable class.
 var campaign_service := get_node_or_null("/root/Campaign")
 if campaign_service: campaign_service.call("configure_camera", camera)
 arm.add_child(camera)
 camera.current = true
 camera.fov = 68.0
 footsteps = AudioStreamPlayer3D.new()
 footsteps.bus = "SFX"
 step_streams["stone"] = ProceduralSound.footstep("stone")
 step_streams["wood"] = ProceduralSound.footstep("wood")
 step_streams["carpet"] = ProceduralSound.footstep("carpet")
 step_streams["grass"] = ProceduralSound.footstep("grass")
 footsteps.stream = step_streams["stone"]
 footsteps.max_distance = 6.0
 add_child(footsteps)
 pivot.rotation.x = -0.22
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_disguise(new_role: String) -> void:
 # Legacy checkpoint roles are migrated to the closest known outfit.
 var mapped := "civilian"
 if new_role in ["staff", "employee"]: mapped = "office_employee"
 elif new_role == "security": mapped = "private_security"
 elif new_role == "manager": mapped = "executive"
 if not outfit_inventory.has(mapped): outfit_inventory.append(mapped)
 outfit_id = mapped
 role = DisguiseSystem.role_for_outfit(outfit_id)
 if body_mesh: body_mesh.set_outfit(outfit_id)

func acquire_outfit(id: String) -> bool:
 if not DisguiseSystem.has_outfit(id) or outfit_inventory.has(id): return false
 outfit_inventory.append(id)
 return true

func equip_outfit(id: String) -> bool:
 if not DisguiseSystem.has_outfit(id) or not outfit_inventory.has(id): return false
 outfit_id = id
 role = DisguiseSystem.role_for_outfit(id)
 if body_mesh: body_mesh.set_outfit(id)
 return true

func outfit_snapshot() -> Dictionary:
 return {"owned": outfit_inventory.duplicate(), "equipped": outfit_id}

func restore_outfits(data: Variant) -> void:
 outfit_inventory.assign(["civilian"])
 var chosen := "civilian"
 if data is Dictionary:
  var owned: Variant = data.get("owned", [])
  if owned is Array:
   for item: Variant in owned:
    var id := str(item)
    if DisguiseSystem.has_outfit(id) and not outfit_inventory.has(id): outfit_inventory.append(id)
  var equipped: Variant = data.get("equipped", "civilian")
  if equipped is String and outfit_inventory.has(equipped): chosen = equipped
 equip_outfit(chosen)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  rotate_y(-event.relative.x * mouse_sensitivity)
  pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -0.95, 0.55)
 if event.is_action_pressed("release_mouse"):
  aiming = false
  instinct_active = false
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 var mouse_ready := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"
 if event is InputEventMouseButton and event.pressed and not mouse_ready:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  return
 if event.is_action_pressed("instinct"): instinct_active = true
 if event.is_action_released("instinct"): instinct_active = false
 if event.is_action_pressed("aim") and mouse_ready: aiming = true
 if event.is_action_released("aim"): aiming = false
 if event.is_action_pressed("fire") and aiming and mouse_ready: fire_requested.emit()
 if event.is_action_pressed("interact"):
  if body_mesh: body_mesh.interact()
  interaction_requested.emit()
 if event.is_action_pressed("equip_primary"): equipment_selected.emit(0)
 if event.is_action_pressed("equip_secondary"): equipment_selected.emit(1)
 if event.is_action_pressed("use_equipment"): equipment_use_requested.emit()
 if event.is_action_pressed("throw_coin"): coin_requested.emit()
 if event.is_action_pressed("disguise_inventory"): disguise_requested.emit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
  aiming = false
  instinct_active = false

func shot_feedback() -> void:
 camera_kick = 1.0
 body_mesh.fire_weapon()

# Stylised alert pulses cause only a short movement stagger; no injury,
# health or permanent failure is implied by this prototype response.
func receive_alert_pulse() -> void:
 stagger_remaining = maxf(stagger_remaining, 0.65)
 camera_kick = maxf(camera_kick, 0.55)
 if body_mesh: body_mesh.hit_reaction = 1.0

func _physics_process(delta: float) -> void:
 stagger_remaining = maxf(0.0, stagger_remaining - delta)
 var blend := 1.0 - exp(-delta * 9.0)
 camera.fov = lerpf(camera.fov, (58.0 if aiming else 68.0) + camera_kick * 1.2, 1.0 - exp(-delta * 8.0))
 camera_kick = move_toward(camera_kick, 0.0, delta * 5.0)
 arm.spring_length = lerpf(arm.spring_length, 2.4 if aiming else 4.0, blend)
 arm.position.x = lerpf(arm.position.x, 0.55 if aiming else 0.15, blend)
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
 body_mesh.crouch_amount = clampf((1.8 - stance_height) / 0.65, 0.0, 1.0)
 body_mesh.weapon_equipped = equipment.selected == "training_sidearm"
 body_mesh.quiet_tool_equipped = equipment.selected == "quiet_line"
 body_mesh.weapon_aiming = aiming and body_mesh.weapon_equipped
 pivot.position.y = 1.5 * stance_height / 1.8
 sprinting = Input.is_action_pressed("sprint") and input.length_squared() > 0.05 and not crouching
 var speed := crouch_speed if crouching else (run_speed if sprinting else walk_speed)
 if stagger_remaining > 0.0: speed *= 0.35
 var acceleration := 14.0 if direction.length_squared() > 0.01 else 18.0
 velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
 velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
 if not is_on_floor(): velocity.y -= 9.8 * delta
 else: velocity.y = -0.1
 move_and_slide()
 var moving_speed := Vector2(velocity.x, velocity.z).length()
 var previous_visual_heading := body_mesh.rotation.y
 if moving_speed > 0.2 and not aiming:
  var local_motion := global_basis.inverse() * Vector3(velocity.x, 0, velocity.z)
  body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, atan2(-local_motion.x, -local_motion.z), 1.0 - exp(-delta * 10.0))
 elif aiming:
  body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, 0.0, 1.0 - exp(-delta * 12.0))
 var turn_rate := angle_difference(previous_visual_heading, body_mesh.rotation.y) / maxf(delta, 0.001)
 body_mesh.animate_motion(delta, moving_speed, turn_rate)
 # Trigger steps from the same phase driving the legs, not a separate timer.
 var step_index := floori(body_mesh.phase / PI)
 if is_on_floor() and moving_speed > 0.5 and step_index != last_footstep_index:
  var surface := "stone"
  if get_parent().has_method("footstep_surface"): surface = str(get_parent().call("footstep_surface", global_position))
  footsteps.stream = step_streams.get(surface, step_streams["stone"])
  footsteps.pitch_scale = 0.85 if crouching else (1.15 if moving_speed > 3.3 else 1.0)
  footsteps.play()
 last_footstep_index = step_index

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
