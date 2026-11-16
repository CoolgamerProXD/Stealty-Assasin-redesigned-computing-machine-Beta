extends Control
## Story transition deliberately leaves the file's contents unrevealed.
var elapsed: float = 0.0
var status: Label
var indicator: ProgressBar
var done: bool = false

func _ready() -> void:
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 theme = BlacklineTheme.create()
 var background := ColorRect.new()
 background.color = Color(0.025,0.045,0.055)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var layout := VBoxContainer.new()
 layout.position = Vector2(180,175)
 layout.custom_minimum_size = Vector2(920,0)
 layout.add_theme_constant_override("separation", 20)
 add_child(layout)
 for line: String in ["BLACKLINE  /  SECURE CHANNEL", "USB DECRYPTION", "RUBY: Five keys accepted. The file is accessible; its contents still need analysis."]:
  var label := Label.new()
  label.text = line
  label.add_theme_font_size_override("font_size", 30 if line == "USB DECRYPTION" else 22)
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  layout.add_child(label)
 indicator = ProgressBar.new()
 indicator.custom_minimum_size = Vector2(850,24)
 indicator.show_percentage = false
 layout.add_child(indicator)
 status = Label.new()
 status.text = "SECURE SESSION OPENING"
 layout.add_child(status)
 var button := Button.new()
 button.text = "CONTINUE  /  SKIP"
 button.custom_minimum_size = Vector2(300,44)
 button.pressed.connect(_finish)
 layout.add_child(button)
 button.grab_focus()

func _process(delta: float) -> void:
 elapsed += delta
 indicator.value = minf(elapsed / 5.0 * 100.0, 100.0)
 if elapsed >= 5.0: status.text = "KEYS VERIFIED  /  ANALYSIS PENDING"

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("release_mouse"): _finish()

func _finish() -> void:
 if done: return
 if not Campaign.acknowledge_usb_decryption():
  status.text = "Unable to save secure-channel progress. Try again."
  return
 done = true
 get_tree().change_scene_to_file("res://scenes/ending.tscn")
