class_name SettingsPanel
extends VBoxContainer
signal back_requested
var status: Label

func _ready() -> void:
 add_theme_constant_override("separation", 2)
 var heading := Label.new()
 heading.text = "SETTINGS"
 heading.add_theme_font_size_override("font_size", 30)
 add_child(heading)
 var resolution := OptionButton.new()
 resolution.add_item("1280 × 720", 0)
 resolution.add_item("1600 × 900", 1)
 resolution.select(1 if Campaign.settings["resolution"] == "1600x900" else 0)
 resolution.item_selected.connect(func(index: int) -> void:
  Campaign.settings["resolution"] = "1600x900" if index == 1 else "1280x720"
  _save())
 _add_row("WINDOW SIZE", resolution)
 var fullscreen := CheckButton.new()
 fullscreen.button_pressed = Campaign.settings["fullscreen"]
 fullscreen.toggled.connect(func(value: bool) -> void:
  Campaign.settings["fullscreen"] = value
  _save())
 _add_row("FULLSCREEN", fullscreen)
 var quality := OptionButton.new()
 for label: String in ["LOW", "MEDIUM", "HIGH"]: quality.add_item(label)
 quality.select(["LOW", "MEDIUM", "HIGH"].find(Campaign.settings["graphics"]))
 quality.item_selected.connect(func(index: int) -> void:
  Campaign.settings["graphics"] = ["LOW", "MEDIUM", "HIGH"][index]
  _save())
 _add_row("GRAPHICS", quality)
 var fps := CheckButton.new()
 fps.button_pressed = Campaign.settings["show_fps"]
 fps.toggled.connect(func(value: bool) -> void:
  Campaign.settings["show_fps"] = value
  _save())
 _add_row("SHOW FPS", fps)
 var sensitivity := HSlider.new()
 sensitivity.min_value = 0.001
 sensitivity.max_value = 0.006
 sensitivity.step = 0.0001
 sensitivity.value = Campaign.settings["sensitivity"]
 sensitivity.value_changed.connect(func(value: float) -> void:
  Campaign.settings["sensitivity"] = value
  _save())
 _add_row("MOUSE SENSITIVITY", sensitivity)
 var volume := HSlider.new()
 volume.min_value = 0.0
 volume.max_value = 1.0
 volume.step = 0.05
 volume.value = Campaign.settings["volume"]
 volume.value_changed.connect(func(value: float) -> void:
  Campaign.settings["volume"] = value
  _save())
 _add_row("MASTER VOLUME", volume)
 status = Label.new()
 status.text = "Changes apply immediately."
 add_child(status)
 var back := Button.new()
 back.text = "BACK"
 back.pressed.connect(func() -> void: back_requested.emit())
 add_child(back)

func _add_row(text: String, control: Control) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 25)
 var label := Label.new()
 label.text = text
 label.custom_minimum_size.x = 220
 row.add_child(label)
 control.custom_minimum_size.x = 250
 row.add_child(control)
 add_child(row)

func _save() -> void:
 if status:
  status.text = "Settings saved." if Campaign.save_settings() else "Could not save settings."
 else:
  Campaign.save_settings()
