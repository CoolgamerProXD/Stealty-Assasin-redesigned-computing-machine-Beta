extends Control
## Compact mission intelligence tracker. Tab minimizes; O toggles optional
## objectives. Notifications expire independently of the persistent tracker.
var panel: PanelContainer
var heading: Label
var stage: Label
var objective: Label
var status: Label
var optional: Label
var hint: Label
var notice: Label
var collapsed := false
var show_optional := false
var last_notice := ""
var notice_remaining := 0.0

func _ready() -> void:
 size = Vector2(450, 285)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel = PanelContainer.new()
 panel.position = Vector2.ZERO
 panel.size = Vector2(430, 0)
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.025,0.055,0.065,0.90)
 style.border_color = Color(0.34,0.58,0.57,0.9)
 style.border_width_left = 3
 style.content_margin_left = 12
 style.content_margin_right = 12
 style.content_margin_top = 8
 style.content_margin_bottom = 8
 panel.add_theme_stylebox_override("panel",style)
 add_child(panel)
 var stack := VBoxContainer.new()
 stack.custom_minimum_size.x = 402
 stack.add_theme_constant_override("separation", 3)
 panel.add_child(stack)
 heading = _label(stack, 15, Color(0.66,0.82,0.78))
 stage = _label(stack, 13, Color(0.84,0.72,0.48))
 objective = _label(stack, 19, Color(0.96,0.96,0.91))
 objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 status = _label(stack, 14, Color(0.75,0.83,0.80))
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 optional = _label(stack, 13, Color(0.68,0.76,0.73))
 optional.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 hint = _label(stack, 12, Color(0.60,0.70,0.67))
 notice = Label.new()
 notice.position = Vector2(10,235)
 notice.size = Vector2(430,45)
 notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 notice.add_theme_font_size_override("font_size", 15)
 notice.add_theme_color_override("font_color", Color(0.98,0.90,0.69))
 notice.add_theme_color_override("font_shadow_color", Color.BLACK)
 notice.add_theme_constant_override("shadow_offset_x", 2)
 notice.add_theme_constant_override("shadow_offset_y", 2)
 add_child(notice)

func _label(parent: Node, font_size: int, color: Color) -> Label:
 var label := Label.new()
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 parent.add_child(label)
 return label

func _unhandled_input(event: InputEvent) -> void:
 if not is_visible_in_tree(): return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_TAB:
   collapsed = not collapsed
   _visibility()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_O:
   show_optional = not show_optional
   _visibility()
   get_viewport().set_input_as_handled()

func _visibility() -> void:
 stage.visible = not collapsed
 objective.visible = not collapsed
 status.visible = not collapsed
 optional.visible = not collapsed and show_optional
 hint.text = "TAB  /  RESTORE TRACKER" if collapsed else ("TAB  /  MINIMISE     ·     O  /  HIDE OPTIONAL" if show_optional else "TAB  /  MINIMISE     ·     O  /  SHOW OPTIONAL")
 # Container sizes can grow when optional text is shown; shrink them again.
 panel.size.y = 0

func set_state(title: String, stage_text: String, objective_text: String, status_text: String, optional_text: String, message: String) -> void:
 heading.text = "FIELD INTELLIGENCE   /   " + title.to_upper()
 stage.text = stage_text
 objective.text = objective_text
 status.text = status_text
 optional.text = optional_text
 if message != last_notice:
  last_notice = message
  if not message.is_empty():
   notice.text = message
   notice_remaining = 5.0
 _visibility()

func _process(delta: float) -> void:
 notice_remaining = maxf(0.0,notice_remaining-delta)
 notice.visible = notice_remaining > 0.0 and not collapsed
 notice.modulate.a = minf(1.0,notice_remaining)
 notice.position.x = 10.0 + maxf(0.0, 5.0-notice_remaining) * 2.0 if notice_remaining > 4.5 else 10.0
