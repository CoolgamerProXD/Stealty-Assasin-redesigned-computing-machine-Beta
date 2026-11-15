extends Node3D
## In-engine, deterministic timeline. Completion was persisted before entering this scene.
var time: float = 0.0
var actor: StylizedPerson
var ruby: StylizedPerson
var left_door: Node3D
var right_door: Node3D
var camera: Camera3D
var subtitles: Label
var finished: bool = false
var ambience: AudioStreamPlayer
var effects: AudioStreamPlayer
var door_played: bool = false
var last_step: int = -1

func _ready() -> void:
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 ambience = AudioStreamPlayer.new()
 ambience.stream = ProceduralSound.tone(55.0, 1.0, 0.06, true)
 add_child(ambience)
 ambience.play()
 effects = AudioStreamPlayer.new()
 add_child(effects)
 var environment := WorldEnvironment.new()
 var atmosphere := Environment.new()
 atmosphere.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 var sky_material := ProceduralSkyMaterial.new()
 sky_material.sky_top_color = Color(0.18, 0.32, 0.45)
 sky_material.sky_horizon_color = Color(0.64, 0.70, 0.69)
 sky_material.ground_bottom_color = Color(0.19, 0.22, 0.22)
 sky.sky_material = sky_material
 atmosphere.sky = sky
 atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 atmosphere.ambient_light_color = Color(0.72, 0.77, 0.78)
 atmosphere.ambient_light_energy = 0.8
 environment.environment = atmosphere
 add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-45, 35, 0)
 light.light_energy = 1.0
 light.shadow_enabled = true
 add_child(light)
 _box(Vector3(0, -0.15, 3), Vector3(12, 0.3, 8), Color(0.30, 0.33, 0.34))
 _box(Vector3(0, -0.15, -5), Vector3(20, 0.3, 10), Color(0.33, 0.34, 0.31))
 _box(Vector3(-4, 1.8, 3), Vector3(0.3, 3.6, 8), Color(0.35, 0.39, 0.40))
 _box(Vector3(4, 1.8, 3), Vector3(0.3, 3.6, 8), Color(0.35, 0.39, 0.40))
 _box(Vector3(-3, 1.8, 0), Vector3(2, 3.6, 0.3), Color(0.43, 0.46, 0.44))
 _box(Vector3(3, 1.8, 0), Vector3(2, 3.6, 0.3), Color(0.43, 0.46, 0.44))
 _box(Vector3(0, 3.35, 0), Vector3(4, 0.5, 0.3), Color(0.43, 0.46, 0.44))
 # Two panels slide into their recesses while the player walks through the opening.
 left_door = _box(Vector3(-1, 1.5, 0), Vector3(1.9, 3, 0.18), Color(0.24, 0.30, 0.33))
 right_door = _box(Vector3(1, 1.5, 0), Vector3(1.9, 3, 0.18), Color(0.24, 0.30, 0.33))
 _box(Vector3(-4.8, 0.5, -4), Vector3(2, 1, 2), Color(0.22, 0.30, 0.22))
 _box(Vector3(4.8, 0.5, -4), Vector3(2, 1, 2), Color(0.22, 0.30, 0.22))
 _build_exterior()
 actor = StylizedPerson.new()
 actor.role = "visitor"
 add_child(actor)
 ruby = StylizedPerson.new()
 ruby.role = "ruby"
 ruby.position = Vector3(1.35, 0, -4.4)
 ruby.rotation.y = PI
 add_child(ruby)
 camera = Camera3D.new()
 add_child(camera)
 camera.current = true
 var canvas := CanvasLayer.new()
 add_child(canvas)
 subtitles = Label.new()
 subtitles.position = Vector2(110, 570)
 subtitles.custom_minimum_size = Vector2(1000, 80)
 subtitles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 subtitles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 subtitles.add_theme_font_size_override("font_size", 24)
 subtitles.add_theme_color_override("font_outline_color", Color.BLACK)
 subtitles.add_theme_constant_override("outline_size", 5)
 canvas.add_child(subtitles)
 var skip := Button.new()
 skip.text = "SKIP  /  ESC"
 skip.position = Vector2(1080, 20)
 skip.pressed.connect(_finish)
 canvas.add_child(skip)
 _apply_timeline(0.0, 0.0)

func _build_exterior() -> void:
 # Continuous grade at y=0; the door threshold and both actors share this plane.
 var ground := _box(Vector3(0, -0.20, -19), Vector3(60, 0.38, 38), Color(0.28, 0.31, 0.29))
 ground.name = "ExteriorGround"
 _box(Vector3(0, -0.01, -11.5), Vector3(60, 0.02, 5), Color(0.19, 0.22, 0.23))
 _box(Vector3(0, 0.005, -8.6), Vector3(60, 0.03, 0.25), Color(0.52, 0.53, 0.47))
 _box(Vector3(0, 0.005, -14.4), Vector3(60, 0.03, 0.25), Color(0.52, 0.53, 0.47))
 # Contextual facade around the exit and distant city buildings beyond the road.
 for x: float in [-7.0, 7.0]:
  _box(Vector3(x, 2.1, 0.1), Vector3(6, 4.2, 0.5), Color(0.36, 0.40, 0.40))
  _box(Vector3(x, 2.2, -0.18), Vector3(3.2, 1.5, 0.07), Color(0.18, 0.31, 0.35))
 for i: int in range(5):
  var x := -20.0 + float(i) * 10.0
  var height := 6.0 + float(i % 3) * 2.0
  var building := _box(Vector3(x, height * 0.5, -24), Vector3(8.5, height, 7), Color(0.34 + float(i % 2) * 0.05, 0.38, 0.39))
  building.name = "BackgroundBuilding%d" % i
  for floor_index: int in range(1, 4):
   _box(Vector3(x, float(floor_index) * 1.5, -20.45), Vector3(6.2, 0.75, 0.05), Color(0.20, 0.31, 0.35))
 for x: float in [-8.5, 8.5]:
  _box(Vector3(x, 1.8, -7.2), Vector3(0.12, 3.6, 0.12), Color(0.22, 0.24, 0.23))
  _box(Vector3(x, 3.6, -7.2), Vector3(0.65, 0.12, 0.30), Color(0.92, 0.80, 0.58))
  _box(Vector3(x, 0.25, -4), Vector3(1.4, 0.5, 1.4), Color(0.34, 0.33, 0.29))
  _box(Vector3(x, 0.95, -4), Vector3(1.1, 1.0, 1.1), Color(0.24, 0.35, 0.25))

func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var mesh := BoxMesh.new()
 mesh.size = size
 var visual := MeshInstance3D.new()
 visual.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.85
 visual.material_override = material
 visual.position = pos
 add_child(visual)
 return visual

func _process(delta: float) -> void:
 if finished: return
 time += delta
 _apply_timeline(time, delta)
 if time >= 1.0 and not door_played:
  door_played = true
  effects.stream = ProceduralSound.tone(120.0, 0.55, 0.10)
  effects.play()
 var step := int((time - 1.6) * 1.5)
 if time > 1.6 and time < 8.0 and step != last_step:
  last_step = step
  effects.stream = ProceduralSound.tone(75.0, 0.08, 0.08)
  effects.play()
 if time >= 22.0: _finish()

func _apply_timeline(t: float, delta: float) -> void:
 var doors := clampf((t - 1.0) / 2.0, 0.0, 1.0)
 left_door.position.x = -1.0 - doors * 1.9
 right_door.position.x = 1.0 + doors * 1.9
 var walk := clampf((t - 1.0) / 7.0, 0.0, 1.0)
 actor.position = Vector3(0, 0, lerpf(4.5, -3.1, walk))
 actor.animate_motion(delta, 1.1 if t > 1.0 and t < 8.0 else 0.0)
 ruby.animate_motion(delta, 0.0)
 if t < 7.0:
  camera.position = Vector3(-2.4, 2.8, actor.position.z + 6.0)
  camera.look_at(Vector3(0, 1.25, actor.position.z - 1.5), Vector3.UP)
 else:
  camera.position = Vector3(5.0, 2.4, -1.2)
  camera.look_at(Vector3(0.7, 1.2, -3.8), Vector3.UP)
 if t < 8.0: subtitles.text = "ASSESSMENT COMPLETE  /  CIVIC EVALUATION ANNEX"
 elif t < 12.0: subtitles.text = "RUBY: You noticed the missing piece. Most people only count the locks."
 elif t < 15.0: subtitles.text = "RUBY: I'm Ruby. From now on, I handle your assignments for Blackline."
 elif t < 18.0: subtitles.text = "AGENT: And the name in the dispatch? The Covenant?"
 else: subtitles.text = "RUBY: A question worth keeping. First, the Meridian. Let's find that archive."

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("release_mouse"): _finish()

func _finish() -> void:
 if finished: return
 finished = true
 get_tree().change_scene_to_file("res://scenes/ending.tscn")
