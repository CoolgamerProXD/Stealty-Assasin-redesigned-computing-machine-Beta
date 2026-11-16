extends Node3D
## Original fictional extensions attached to the shared city, one per mission.
## Local +Z points outwards. Collision, lighting and readable passages are authored.
var operation_id := ""
var mesh_cache: Dictionary = {}
var material_cache: Dictionary = {}
var intel_position := Vector3(0,3.3,57)
var beacon: OmniLight3D
var beacon_clock: float = 0.0

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
 var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
 holder.position = pos
 add_child(holder)
 var visual := MeshInstance3D.new()
 if not mesh_cache.has(size):
  var mesh := BoxMesh.new()
  mesh.size = size
  mesh_cache[size] = mesh
 visual.mesh = mesh_cache[size]
 if not material_cache.has(color):
  var material := StandardMaterial3D.new()
  material.albedo_color = color
  material.roughness = 0.8
  material_cache[color] = material
 visual.material_override = material_cache[color]
 if not solid: visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 holder.add_child(visual)
 if solid:
  var collider := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  collider.shape = shape
  holder.add_child(collider)
 return holder

func _sign(text: String, pos: Vector3, yaw: float = 0.0) -> void:
 var label := Label3D.new()
 label.text = text
 label.position = pos
 label.rotation.y = yaw
 label.font_size = 32
 label.pixel_size = 0.005
 label.modulate = Color(0.95,0.86,0.67)
 add_child(label)

func build() -> void:
 var market := operation_id == "the_streets"
 var business := operation_id == "the_district"
 var paving := Color(0.39,0.37,0.34) if market else (Color(0.36,0.40,0.40) if business else Color(0.33,0.40,0.41))
 var wall := Color(0.63,0.53,0.41) if market else (Color(0.47,0.56,0.57) if business else Color(0.55,0.54,0.48))
 var accent := Color(0.73,0.27,0.18) if market else (Color(0.24,0.48,0.49) if business else Color(0.18,0.40,0.49))
 var dark := Color(0.19,0.25,0.26)
 _box(Vector3(0,-0.2,35),Vector3(70,0.4,70),paving,true)
 # Solid boundaries and a 12m gateway back to the existing city.
 for x: float in [-35.0,35.0]: _box(Vector3(x,2,35),Vector3(0.3,4,70),dark,true)
 _box(Vector3(0,2,70),Vector3(70,4,0.3),dark,true)
 for x: float in [-20.5,20.5]: _box(Vector3(x,2,0),Vector3(29,4,0.3),dark,true)
 _box(Vector3(0,0.03,35),Vector3(9,0.05,70),paving.darkened(0.35))
 for z: float in [10.0,30.0,50.0,65.0]:
  _box(Vector3(0,0.04,z),Vector3(69,0.06,6),paving.lightened(0.10))
  for x: float in [-3.0,-1.5,0.0,1.5,3.0]: _box(Vector3(x,0.08,z),Vector3(0.7,0.02,2.8),Color(0.73,0.71,0.62))
 # Six open rooms each have front/back access and separate pedestrian alleys.
 for x: float in [-17.0,17.0]:
  for z: float in [18.0,38.0,58.0]:
   _room(x,z,wall,accent,dark)
 # Roof viewing platform with a solid low-gradient ramp and useful intel.
 var ramp := _box(Vector3(0,1.42,43),Vector3(5,0.18,10.5),paving.lightened(0.12),true)
 ramp.rotation.x = -atan(3.0/10.0)
 ramp.name = "NeighbourhoodRamp"
 _box(Vector3(0,2.85,56),Vector3(10,0.3,16),paving.lightened(0.1),true)
 for x: float in [-4.9,4.9]:
  _box(Vector3(x,3.55,56),Vector3(0.12,1.2,16),dark,true)
 _box(Vector3(0,3.55,63.9),Vector3(10,1.2,0.12),dark,true)
 _box(Vector3(-3.0,3.5,60),Vector3(1.2,1.0,0.8),accent,true)
 _sign("LOOKOUT / INTEL",Vector3(0,4.5,62.5),PI)
 # Bounded, non-shadow-casting practicals, grouped for preset control.
 for z: float in [16.0,38.0,60.0]:
  for x: float in [-7.0,7.0]:
   _box(Vector3(x,1.9,z),Vector3(0.12,3.8,0.12),dark)
   _box(Vector3(x,3.8,z),Vector3(0.7,0.1,0.55),Color(0.96,0.78,0.49))
   var light := OmniLight3D.new()
   light.position = Vector3(x,3.6,z)
   light.light_color = Color(1.0,0.77,0.53) if market else Color(0.74,0.86,1.0)
   light.light_energy = 0.3
   light.omni_range = 6.0
   light.shadow_enabled = false
   light.add_to_group("quality_practicals")
   light.visible = Campaign.settings["graphics"] != "LOW" and bool(Campaign.settings["practicals"])
   add_child(light)
 # One low-cost animated beacon gives each neighbourhood a changing light
 # without multiplying shadow maps or overlapping large light volumes.
 beacon = OmniLight3D.new()
 beacon.position = Vector3(0,4.1,8)
 beacon.light_color = accent.lightened(0.45)
 beacon.light_energy = 0.32
 beacon.omni_range = 7.0
 beacon.shadow_enabled = false
 beacon.add_to_group("quality_practicals")
 beacon.visible = Campaign.settings["graphics"] != "LOW" and bool(Campaign.settings["practicals"])
 add_child(beacon)
 # The corridor navmesh deliberately excludes the new buildings and ramp.
 var region := NavigationRegion3D.new()
 region.name = "NeighbourhoodStreetNavigation"
 var nav := NavigationMesh.new()
 nav.vertices = PackedVector3Array([Vector3(-4,0,0),Vector3(4,0,0),Vector3(4,0,37),Vector3(-4,0,37)])
 nav.add_polygon(PackedInt32Array([0,3,2,1]))
 region.navigation_mesh = nav
 add_child(region)
 # Local, short social routines remain on the obstacle-free central strip.
 var scene := get_parent()
 for i: int in range(3):
  var start := to_global(Vector3(-2.2 + float(i)*2.2,0.05,12.0 + float(i)*5.0))
  var finish := to_global(Vector3(-2.2 + float(i)*2.2,0.05,25.0 + float(i)*3.0))
  var identity := ("Market visitor " if market else ("Office worker " if business else "Quay visitor ")) + str(i+1)
  scene.call("_target", identity, "employee" if i == 1 else "civilian", start, finish)
 _sign("MARKET LANES" if market else ("COMMERCIAL QUARTER" if business else "WATERFRONT PROMENADE"),Vector3(0,4,7),PI)
 if not market and not business:
  # Distant water is an atmospheric backdrop, not explorable terrain.
  _box(Vector3(0,-0.1,77),Vector3(100,0.15,13),Color(0.15,0.32,0.40))
  for x: float in [-25.0,-15.0,-5.0,5.0,15.0,25.0]:
   _box(Vector3(x,0.9,67.5),Vector3(0.1,1.8,0.1),Color(0.68,0.72,0.67))
  _box(Vector3(0,1.65,67.5),Vector3(60,0.08,0.08),Color(0.68,0.72,0.67))

func _room(x: float, z: float, wall: Color, accent: Color, dark: Color) -> void:
 for side: float in [-1.0,1.0]:
  _box(Vector3(x,1.9,z+side*5.0),Vector3(10,3.8,0.2),wall,true)
  for other: float in [-1.0,1.0]:
   _box(Vector3(x+side*5,1.9,z+other*3.3),Vector3(0.2,3.8,3.4),wall,true)
 _box(Vector3(x,3.85,z),Vector3(10,0.2,10),wall.darkened(0.18),true)
 _box(Vector3(x,0.025,z),Vector3(9.7,0.04,9.7),wall.lightened(0.10))
 _box(Vector3(x,0.5,z-3.5),Vector3(4,1,1),dark,true)
 _box(Vector3(x,1.07,z-3.5),Vector3(3.8,0.08,0.9),accent)
 for side: float in [-1.0,1.0]:
  _box(Vector3(x+side*4.85,3.1,z),Vector3(0.1,0.5,6),accent)
  for dz: float in [-3.4,3.4]:
   _box(Vector3(x+side*5.12,2.0,z+dz),Vector3(0.06,1.4,2.0),Color(0.26,0.41,0.43))
 for dx: float in [-3.0,0.0,3.0]:
  _box(Vector3(x+dx,5.5,z),Vector3(2.2,3.0,8),wall.darkened(0.08))
  _box(Vector3(x+dx,5.6,z+4.05),Vector3(1.6,1.7,0.06),Color(0.21,0.34,0.37))
 _sign("TEA / MARKET" if operation_id == "the_streets" else ("OFFICE / RECORDS" if operation_id == "the_district" else "PIER / SERVICES"),Vector3(x,2.7,z+4.86))

func intel_world_position() -> Vector3:
 return to_global(intel_position)

func contains_world_position(point: Vector3) -> bool:
 var local := to_local(point)
 return absf(local.x) < 34.0 and local.z >= 0.0 and local.z < 69.0 and local.y > -1.0 and local.y < 8.0

func _process(delta: float) -> void:
 if beacon and beacon.visible:
  beacon_clock += delta
  beacon.light_energy = 0.30 + 0.08 * sin(beacon_clock * 1.4)
