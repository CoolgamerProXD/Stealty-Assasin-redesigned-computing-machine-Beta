extends SceneTree
## Automated virtual-display test. This does not simulate an interactive playtest.
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, description: String) -> void:
 checks += 1
 if condition:
  print("CAMERA PASS: ", description)
 else:
  failures += 1
  printerr("CAMERA FAIL: ", description)

func run() -> void:
 var scene: PackedScene = load("res://scenes/hotel.tscn")
 var world: Node = scene.instantiate()
 root.add_child(world)
 await process_frame
 print("DISPLAY_STARTUP: engine clock to first process frame = %.3f ms" % (float(Time.get_ticks_usec()) / 1000.0))
 await physics_frame
 var player: HotelPlayer = world.get("player")
 check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse captured at startup")
 var yaw := player.rotation.y
 var pitch := player.pivot.rotation.x
 var motion := InputEventMouseMotion.new()
 motion.relative = Vector2(100, -50)
 player._unhandled_input(motion)
 check(player.rotation.y < yaw and player.pivot.rotation.x > pitch, "mouse motion rotates yaw and pitch")
 motion.relative = Vector2(0, -10000)
 player._unhandled_input(motion)
 check(is_equal_approx(player.pivot.rotation.x, 0.55), "camera pitch is clamped")
 var release := InputEventAction.new()
 release.action = "release_mouse"
 release.pressed = true
 player._unhandled_input(release)
 check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "release action frees mouse")
 # The wall behind the player must shorten the existing spring arm.
 player.rotation.y = 0.0
 player.pivot.rotation.x = -0.22
 player.global_position = Vector3(-10, 0.05, 7.0)
 player.velocity = Vector3.ZERO
 for i: int in range(12): await physics_frame
 var arm: SpringArm3D = player.pivot.get_child(0)
 check(arm.get_hit_length() < arm.spring_length - 0.2, "camera spring arm detects wall behind player")
 # Sample actual process-frame intervals on this virtual software display.
 for i: int in range(30): await process_frame
 var samples: Array[float] = []
 var previous: int = Time.get_ticks_usec()
 for i: int in range(120):
  await process_frame
  var now: int = Time.get_ticks_usec()
  samples.append(float(now - previous) / 1000.0)
  previous = now
 var total: float = 0.0
 for value: float in samples: total += value
 samples.sort()
 var mean: float = total / samples.size()
 print("DISPLAY_METRIC: frames=%d mean_ms=%.3f p95_ms=%.3f p99_ms=%.3f mean_fps=%.2f" % [samples.size(), mean, samples[113], samples[118], 1000.0 / maxf(mean, 0.001)])
 world.queue_free()
 await process_frame
 print("CAMERA RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
