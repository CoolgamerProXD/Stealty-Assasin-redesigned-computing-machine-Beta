extends "res://scripts/world/hotel.gd"
## The fictional Civic Evaluation Annex uses the existing player, NPC and interactions.
var robot: Interactable
var patrol_clock: float = 0.0

func mission_id() -> String:
 return "initiation"

func mission_path() -> String:
 return "res://resources/initiation_mission.json"

func safe_position(p: Vector3) -> bool:
 if not p.is_finite() or absf(p.x) > 14.0 or p.y < 0.0 or p.y > 3.0 or absf(p.z) > 9.0: return false
 for boundary: float in [2.0, 7.0]:
  if absf(p.x - boundary) < 0.44 and not (absf(p.z) >= 2.35 and absf(p.z) <= 3.65): return false
 return true

func _build_environment() -> void:
 var environment := WorldEnvironment.new()
 var settings := Environment.new()
 settings.background_mode = Environment.BG_COLOR
 settings.background_color = Color(0.09, 0.12, 0.14)
 settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 settings.ambient_light_color = Color(0.70, 0.76, 0.76)
 settings.ambient_light_energy = 0.75
 environment.environment = settings
 add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55, -25, 0)
 light.light_energy = 0.8
 light.shadow_enabled = false
 add_child(light)
 _box(Vector3(0, -0.15, 0), Vector3(30, 0.3, 20), Color(0.27, 0.30, 0.30))
 _box(Vector3(-15, 1.5, 0), Vector3(0.25, 3, 20), Color(0.48, 0.50, 0.47))
 _box(Vector3(15, 1.5, 0), Vector3(0.25, 3, 20), Color(0.48, 0.50, 0.47))
 _box(Vector3(0, 1.5, -10), Vector3(30, 3, 0.25), Color(0.48, 0.50, 0.47))
 _box(Vector3(0, 1.5, 10), Vector3(30, 3, 0.25), Color(0.48, 0.50, 0.47))
 # Split assessment, observation and controlled training areas; two routes each.
 for boundary: float in [2.0, 7.0]:
  _box(Vector3(boundary, 1.5, -7), Vector3(0.2, 3, 6), Color(0.38, 0.42, 0.42))
  _box(Vector3(boundary, 1.5, 0), Vector3(0.2, 3, 4), Color(0.38, 0.42, 0.42))
  _box(Vector3(boundary, 1.5, 7), Vector3(0.2, 3, 6), Color(0.38, 0.42, 0.42))
 _box(Vector3(-7, 0.01, 0), Vector3(15, 0.02, 19), Color(0.25, 0.29, 0.30), false)
 _box(Vector3(4.5, 0.01, 0), Vector3(4.5, 0.02, 19), Color(0.29, 0.32, 0.29), false)
 _box(Vector3(11, 0.01, 0), Vector3(7.5, 0.02, 19), Color(0.29, 0.27, 0.24), false)
 # Low-cost visual furnishings; marked records remain accessible.
 _box(Vector3(-10, 0.45, -7), Vector3(3, 0.9, 1), Color(0.30, 0.27, 0.23), false)
 _box(Vector3(4.5, 0.45, -7), Vector3(2, 0.9, 1), Color(0.28, 0.32, 0.32), false)
 _box(Vector3(10, 0.45, 7), Vector3(3, 0.9, 1), Color(0.32, 0.30, 0.25), false)
 var region := NavigationRegion3D.new()
 var nav := NavigationMesh.new()
 var xs := [-14.5, 1.5, 2.5, 6.5, 7.5, 14.5]
 var zs := [-9.5, -3.65, -2.35, 2.35, 3.65, 9.5]
 var vertices := PackedVector3Array()
 for z: float in zs:
  for x: float in xs: vertices.append(Vector3(x, 0, z))
 nav.vertices = vertices
 for row: int in range(zs.size() - 1):
  for col: int in range(xs.size() - 1):
   if col in [1, 3] and row not in [1, 3]: continue
   var a: int = row * xs.size() + col
   nav.add_polygon(PackedInt32Array([a, a + xs.size(), a + xs.size() + 1, a + 1]))
 region.navigation_mesh = nav
 add_child(region)

func _build_player() -> void:
 super._build_player()
 player.position = Vector3(-13, 0.05, 7)

func _build_npcs() -> void:
 _guard("Elias Ward", Vector3(-7, 0.05, 0), [ScheduleEntry.new(Vector3(-6, 0, -2), "waiting", 3), ScheduleEntry.new(Vector3(4, 0, 3), "working", 4)])
 _guard("Tessa Rao", Vector3(10, 0.05, 0), [ScheduleEntry.new(Vector3(10, 0, -2), "waiting", 3), ScheduleEntry.new(Vector3(5, 0, -3), "working", 4)])

func _guard(identity: String, spawn: Vector3, route: Array[ScheduleEntry]) -> void:
 var profile := NpcProfile.new()
 profile.identity = identity
 profile.occupation = "security"
 profile.alertness = 0.7
 profile.schedule = route
 var guard := HotelNpc.new()
 guard.profile = profile
 guard.player = player
 guard.position = spawn
 add_child(guard)
 npcs.append(guard)

func _build_interactions() -> void:
 for record: Dictionary in mission.available_records:
  _add_interactable(_vector(record["position"]), record["label"], "clue", record["id"], Color(0.9, 0.72, 0.34))
 _add_interactable(Vector3(-5, 0, -2), "Disable assessment unit", "robot", "disable_assessment_unit", Color(0.38, 0.73, 0.83))
 robot = interactables.back()
 # Distinct abstract machine silhouette, separate from the human NPC meshes.
 var head := MeshInstance3D.new()
 var head_mesh := SphereMesh.new()
 head_mesh.radius = 0.26
 head_mesh.height = 0.52
 head.mesh = head_mesh
 head.position.y = 1.05
 var robot_material := StandardMaterial3D.new()
 robot_material.albedo_color = Color(0.16, 0.55, 0.65)
 robot_material.emission_enabled = true
 robot_material.emission = Color(0.08, 0.3, 0.38)
 head.material_override = robot_material
 robot.add_child(head)
 _add_interactable(Vector3(-13, 0, 7), "Complete assessment", "extract", "exit", Color(0.4, 0.8, 0.5))

func _on_interaction(object: Interactable) -> void:
 if object.kind == "robot":
  if mission.mark_action(object.identifier):
   object.used = true
   message = "Ruby: Unit offline. Collect the three records and return to the exit."
  return
 super._on_interaction(object)

func _physics_process(delta: float) -> void:
 if robot and not robot.used:
  patrol_clock += delta
  robot.position.x = -5.0 + sin(patrol_clock * 0.6) * 1.4
