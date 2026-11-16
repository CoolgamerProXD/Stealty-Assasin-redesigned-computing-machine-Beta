extends CanvasLayer
var world: Node3D
var root: Control
var panel: VBoxContainer
var state: String = "main"

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 layer = 10
 root = Control.new()
 root.theme = BlacklineTheme.create()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.visible = false
 add_child(root)
 var shade := ColorRect.new()
 shade.color = Color(0.015, 0.025, 0.03, 0.94)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(shade)
 panel = VBoxContainer.new()
 panel.position = Vector2(400, 110)
 panel.custom_minimum_size = Vector2(480, 0)
 panel.add_theme_constant_override("separation", 12)
 root.add_child(panel)

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("release_mouse") and not event.is_echo():
  if not root.visible: _open()
  elif state == "main": _resume()
  else: _main()
  get_viewport().set_input_as_handled()

func _open() -> void:
 if world and world.player:
  world.player.aiming = false
  world.player.instinct_active = false
 get_tree().paused = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 root.visible = true
 _main()

func _resume() -> void:
 root.visible = false
 get_tree().paused = false
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _clear() -> void:
 panel.position.y = 110
 for child: Node in panel.get_children():
  panel.remove_child(child)
  child.queue_free()

func _label(text: String) -> void:
 var label := Label.new()
 label.text = text
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", 24)
 panel.add_child(label)

func _button(text: String, callback: Callable) -> Button:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size.y = 44
 panel.add_child(button)
 button.pressed.connect(callback)
 return button

func _main() -> void:
 if world and world.player: world.player.mouse_sensitivity = float(Campaign.settings["sensitivity"])
 state = "main"
 _clear()
 _label("PAUSED")
 _label(world.message)
 _button("RESUME", _resume).grab_focus()
 _button("SAVE CHECKPOINT", func() -> void: world.save_game(); _main())
 _button("LOAD CHECKPOINT", func() -> void: world.load_game(); _main())
 _button("SETTINGS", _settings)
 _button("RETURN TO MENU", _confirm)

func _settings() -> void:
 state = "settings"
 _clear()
 panel.position.y = 40
 var settings := SettingsPanel.new()
 panel.add_child(settings)
 settings.back_requested.connect(func() -> void:
  world.player.mouse_sensitivity = float(Campaign.settings["sensitivity"])
  _main())

func _confirm() -> void:
 state = "confirm"
 _clear()
 _label("Return to menu? Unsaved progress will be lost.")
 _button("CANCEL", _main).grab_focus()
 _button("RETURN TO MENU", func() -> void:
  get_tree().paused = false
  Campaign.active_mission = ""
  get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
