extends CanvasLayer
## Short, skippable in-world establishing shots for the original missions.
var world: Node3D
var camera: Camera3D
var caption: Label
var elapsed: float = 0.0
var start: Vector3
var finish: Vector3
var focus: Vector3
var done: bool = false

func _ready() -> void:
 layer = 8
 var player: HotelPlayer = world.get("player")
 player.set_physics_process(false)
 player.set_process_unhandled_input(false)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 camera = Camera3D.new()
 Campaign.configure_camera(camera)
 world.add_child(camera)
 var mission_id: String = world.call("mission_id")
 if mission_id == "initiation":
  start = Vector3(-10,2.35,4.5)
  finish = Vector3(-7,1.9,1)
  focus = Vector3(-5,0.9,-2)
 else:
  var target: HotelNpc = world.get("primary_npc")
  focus = target.global_position + Vector3.UP
  start = focus + Vector3(2.5,1.1,2.4)
  finish = focus + Vector3(-1.8,0.9,2.2)
 camera.global_position = start
 camera.look_at(focus, Vector3.UP)
 camera.make_current()
 caption = Label.new()
 caption.position = Vector2(110,550)
 caption.size = Vector2(1040,120)
 caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 caption.add_theme_font_size_override("font_size", 22)
 caption.add_theme_color_override("font_shadow_color", Color.BLACK)
 caption.add_theme_constant_override("shadow_offset_x", 2)
 caption.add_theme_constant_override("shadow_offset_y", 2)
 caption.text = str(Campaign.progress.mission(mission_id).get("briefing", ""))
 add_child(caption)
 var skip := Button.new()
 skip.text = "SKIP  /  ESC"
 skip.position = Vector2(1050,660)
 skip.size = Vector2(180,42)
 skip.pressed.connect(end_intro)
 add_child(skip)

func _process(delta: float) -> void:
 if done: return
 elapsed += delta
 camera.global_position = start.lerp(finish, minf(elapsed / 6.0, 1.0))
 camera.look_at(focus, Vector3.UP)
 if elapsed >= 6.0: end_intro()

func _input(event: InputEvent) -> void:
 if not done and event.is_action_pressed("release_mouse"):
  get_viewport().set_input_as_handled()
  end_intro()

func end_intro() -> void:
 if done: return
 done = true
 var player: HotelPlayer = world.get("player")
 player.set_physics_process(true)
 player.set_process_unhandled_input(true)
 player.camera.make_current()
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 camera.queue_free()
 world.call("_finish_entry_intro")
 queue_free()
