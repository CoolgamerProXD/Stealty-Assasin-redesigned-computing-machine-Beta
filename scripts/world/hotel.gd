extends Node3D
## Original greybox: The Meridian Hotel, after a missing archive incident.
var save_path: String = "user://meridian_save.json"
var player: HotelPlayer
var mission: Mission = Mission.new()
var interactables: Array[Interactable] = []
var npcs: Array[HotelNpc] = []
var hud: Label
var prompt: Label
var message: String = ""

func _ready() -> void:
 var mission_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/meridian_mission.json"))
 if not mission.configure(mission_data):
  push_error("Invalid or missing Meridian mission configuration")
 _build_environment()
 _build_player()
 if mission.configured and mission.required_records > player.inventory.capacity:
  push_error("Mission requires more records than the inventory can hold")
  mission.configure(null)
 if mission.configured:
  for record: Dictionary in mission.available_records:
   if not HotelLayout.is_safe_player_position(_vector(record["position"])):
    push_error("Mission record is outside the playable floor or inside a partition")
    mission.configure(null)
    break
 _build_npcs()
 _build_interactions()
 _build_ui()

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
 var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
 holder.position = pos
 add_child(holder)
 var mesh := BoxMesh.new()
 mesh.size = size
 var visual := MeshInstance3D.new()
 visual.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.85
 visual.material_override = material
 holder.add_child(visual)
 if solid:
  var collider := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  collider.shape = shape
  holder.add_child(collider)

func _build_environment() -> void:
 var environment := WorldEnvironment.new()
 var sky := Environment.new()
 sky.background_mode = Environment.BG_COLOR
 sky.background_color = Color(0.10, 0.13, 0.16)
 sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 sky.ambient_light_color = Color(0.73, 0.76, 0.78)
 sky.ambient_light_energy = 0.8
 environment.environment = sky
 add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55, -30, 0)
 light.light_energy = 0.8
 light.shadow_enabled = false
 add_child(light)
 _box(Vector3(0, -0.15, 0), Vector3(24, 0.3, 16), Color(0.34, 0.32, 0.29))
 _box(Vector3(-12, 1.5, 0), Vector3(0.25, 3, 16), Color(0.52, 0.49, 0.43))
 _box(Vector3(12, 1.5, 0), Vector3(0.25, 3, 16), Color(0.48, 0.46, 0.41))
 _box(Vector3(0, 1.5, -8), Vector3(24, 3, 0.25), Color(0.49, 0.47, 0.42))
 _box(Vector3(0, 1.5, 8), Vector3(24, 3, 0.25), Color(0.49, 0.47, 0.42))
 # The two openings in each partition provide alternate routes. Furniture remains non-solid.
 _box(Vector3(4.5, 0.01, 0), Vector3(5, 0.02, 15.5), Color(0.26, 0.29, 0.29), false)
 _box(Vector3(9.45, 0.02, 0), Vector3(4.8, 0.03, 15.5), Color(0.24, 0.25, 0.27), false)
 _box(Vector3(-5, 0.5, -4.8), Vector3(4, 1, 1), Color(0.28, 0.18, 0.13), false)
 _box(Vector3(-5, 0.35, 3.5), Vector3(2.4, 0.7, 1), Color(0.33, 0.22, 0.18), false)
 _box(Vector3(4.5, 0.45, -5), Vector3(2.2, 0.9, 1), Color(0.32, 0.27, 0.22), false)
 _box(Vector3(9.5, 0.5, -5), Vector3(2.5, 1, 1), Color(0.28, 0.27, 0.24), false)
 for boundary: float in [2.0, 7.0]:
  for z: float in [-6.0, 0.0, 6.0]:
   _box(Vector3(boundary, 1.5, z), Vector3(0.2, 3.0, 4.0), Color(0.42, 0.40, 0.36))
 var region := NavigationRegion3D.new()
 region.navigation_mesh = HotelLayout.navigation_mesh()
 add_child(region)

func _build_player() -> void:
 player = HotelPlayer.new()
 player.position = Vector3(-9, 0.05, 5)
 add_child(player)
 player.interaction_requested.connect(_interact_nearest)

func _vector(data: Array) -> Vector3:
 return Vector3(float(data[0]), float(data[1]), float(data[2]))

func _build_npcs() -> void:
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/hotel_population.json"))
 if not data is Array:
  push_error("Invalid hotel population data")
  return
 for record: Dictionary in data:
  var profile := NpcProfile.new()
  profile.identity = str(record["identity"])
  profile.occupation = str(record["occupation"])
  profile.alertness = float(record["alertness"])
  for entry: Dictionary in record["schedule"]:
   profile.schedule.append(ScheduleEntry.new(_vector(entry["destination"]), str(entry["activity"]), float(entry["duration"])))
  var npc := HotelNpc.new()
  npc.profile = profile
  npc.player = player
  npc.position = _vector(record["start"])
  add_child(npc)
  npcs.append(npc)

func _add_interactable(pos: Vector3, title: String, kind: String, id: String, color: Color) -> void:
 var object := Interactable.new()
 object.position = pos
 object.label = title
 object.kind = kind
 object.identifier = id
 add_child(object)
 var visual := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = Vector3(0.55, 0.55, 0.55)
 visual.mesh = mesh
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.emission_enabled = true
 mat.emission = color * 0.3
 visual.material_override = mat
 visual.position.y = 0.4
 object.add_child(visual)
 object.activated.connect(_on_interaction)
 interactables.append(object)

func _build_interactions() -> void:
 for record: Dictionary in mission.available_records:
  _add_interactable(_vector(record["position"]), record["label"], "clue", record["id"], Color(0.9, 0.72, 0.34))
 _add_interactable(Vector3(-1, 0, 5.5), "Change into staff uniform", "disguise", "staff", Color(0.3, 0.6, 0.85))
 _add_interactable(Vector3(-10, 0, 5.5), "Leave hotel", "extract", "exit", Color(0.4, 0.8, 0.5))

func _build_ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 hud = Label.new()
 hud.position = Vector2(24, 20)
 hud.add_theme_font_size_override("font_size", 20)
 canvas.add_child(hud)
 prompt = Label.new()
 prompt.position = Vector2(24, 620)
 prompt.add_theme_font_size_override("font_size", 21)
 canvas.add_child(prompt)

func _nearest() -> Interactable:
 var best: Interactable = null
 var distance := 1.8
 for object: Interactable in interactables:
  var d := player.global_position.distance_to(object.global_position)
  if d < distance and object.available(player.role):
   var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, object.global_position + Vector3.UP * 0.4)
   query.exclude = [player.get_rid()]
   if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
    best = object
    distance = d
 return best

func _interact_nearest() -> void:
 var object := _nearest()
 if object: object.interact(player.role)

func _on_interaction(object: Interactable) -> void:
 match object.kind:
  "clue":
   if not mission.has_record(object.identifier) or mission.clues.has(object.identifier): return
   if not player.inventory.has_item(object.identifier) and not player.inventory.add(object.identifier):
    message = "Inventory full. The record was not collected."
    return
   if not mission.record_clue(object.identifier): return
   object.used = true
   object.visible = false
   for record: Dictionary in mission.available_records:
    if record["id"] == object.identifier:
     message = record["message"]
     break
  "disguise":
   player.set_disguise("staff")
   object.used = true
   object.visible = false
   message = "Staff uniform acquired. Staff area access granted; secure area remains restricted."
  "extract":
   if mission.extracted: message = "Investigation already complete."
   elif mission.extract(): message = "INVESTIGATION COMPLETE — you left with the evidence."
   else: message = mission.objective_text()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("save_game"):
  if SaveStore.write(save_path, SessionSnapshot.capture(player, mission)):
   message = "Progress saved."
  else:
   message = "Save failed. Check storage permissions."
 elif event.is_action_pressed("load_game"):
  var data := SaveStore.read(save_path)
  if data.is_empty():
   message = "No valid compatible save found."
  else:
   SessionSnapshot.restore(data, player, mission, interactables)
   message = "Progress loaded. NPCs continue their current routines."


func _process(_delta: float) -> void:
 if player == null or hud == null: return
 var area := AccessRules.area_at(player.global_position)
 var access := "AUTHORIZED" if AccessRules.can_enter(player.role, area) else "RESTRICTED"
 var highest := 0.0
 for npc: HotelNpc in npcs: highest = maxf(highest, npc.suspicion)
 hud.text = "THE MERIDIAN  /  MISSING ARCHIVE\n%s  ·  %s (%s)  ·  Awareness %.0f%%\n%s\n%s\n%s" % [player.role.to_upper(), area.to_upper(), access, highest, mission.progress_text(), mission.objective_text(), message]
 var nearest := _nearest()
 prompt.text = ("E  " + nearest.label + "\n" if nearest else "") + "WASD move  ·  mouse look  ·  Shift run  ·  C crouch  ·  F5 save  ·  F9 load  ·  Esc release mouse"
