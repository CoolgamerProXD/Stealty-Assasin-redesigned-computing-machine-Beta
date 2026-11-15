extends SceneTree
## Accelerated, physical multi-cycle route exercise. This is not a crowd or
## human playtest: it samples authored station and Meridian floor-local routes.
var failures := 0
var checks := 0

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, message: String) -> void:
 checks += 1
 if value: print("SOAK PASS: ", message)
 else:
  failures += 1
  printerr("SOAK FAIL: ", message)

func exercise(scene_path: String, selected: Array[int], label: String) -> void:
 var world: Node3D = load(scene_path).instantiate()
 root.add_child(world)
 var player: HotelPlayer = world.get("player")
 player.set_physics_process(false)
 player.collision_layer = 0
 var people: Array[HotelNpc] = world.get("npcs")
 var observed: Array[Dictionary] = []
 for index: int in selected:
  var person: HotelNpc = people[index]
  observed.append({"second": false, "returned": false, "greatest": 0.0, "origin": person.global_position})
 # 800 frames at 4x time cover ~53 simulation seconds: long enough for the
 # longest hotel route, its dwell time and the return leg, without a blind wait.
 for frame: int in range(800):
  await physics_frame
  for i: int in range(selected.size()):
   var person: HotelNpc = people[selected[i]]
   var observation: Dictionary = observed[i]
   observation["greatest"] = maxf(float(observation["greatest"]), person.global_position.distance_to(observation["origin"]))
   if person.schedule_index == 1: observation["second"] = true
   if bool(observation["second"]) and person.schedule_index == 1 and person.state in ["idle", "waiting", "working", "conversing"] and person.global_position.distance_to(person.profile.schedule[1].destination) < 0.8:
    observation["returned"] = true
 for i: int in range(selected.size()):
  var person: HotelNpc = people[selected[i]]
  var observation: Dictionary = observed[i]
  print("SOAK_DIAG: ", label, " ", person.profile.identity, " max=", observation["greatest"], " second=", observation["second"], " returned=", observation["returned"], " pos=", person.global_position, " state=", person.state)
  check(bool(observation["second"]) and bool(observation["returned"]), label + " " + person.profile.identity + " reaches both route endpoints")
 world.queue_free()
 await process_frame

func run() -> void:
 Engine.time_scale = 4.0
 var hotel_indices: Array[int] = [4,5,6]
 await exercise("res://scenes/hotel.tscn", hotel_indices, "Meridian")
 var station_indices: Array[int] = []
 for i: int in range(16): station_indices.append(i)
 await exercise("res://scenes/tung_chung_preview.tscn", station_indices, "Station")
 Engine.time_scale = 1.0
 print("SOAK RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
