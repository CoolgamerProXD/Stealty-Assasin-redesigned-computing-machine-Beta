class_name BlacklineTheme
extends RefCounted
## Shared, original UI palette; controls retain native keyboard focus behavior.
static func create() -> Theme:
 var theme := Theme.new()
 theme.default_font_size = 18
 theme.set_color("font_color", "Label", Color(0.89, 0.90, 0.86))
 theme.set_color("font_color", "Button", Color(0.88, 0.90, 0.87))
 theme.set_color("font_hover_color", "Button", Color(1.0, 0.94, 0.78))
 theme.set_color("font_focus_color", "Button", Color(1.0, 0.94, 0.78))
 theme.set_color("font_disabled_color", "Button", Color(0.46, 0.49, 0.48))
 theme.set_stylebox("normal", "Button", _style(Color(0.055, 0.09, 0.105, 0.95), Color(0.25, 0.32, 0.32), 1))
 theme.set_stylebox("hover", "Button", _style(Color(0.10, 0.16, 0.17, 1), Color(0.76, 0.57, 0.34), 2))
 theme.set_stylebox("pressed", "Button", _style(Color(0.20, 0.20, 0.17, 1), Color(0.85, 0.65, 0.38), 2))
 theme.set_stylebox("disabled", "Button", _style(Color(0.045, 0.055, 0.06, 0.7), Color(0.12, 0.16, 0.17), 1))
 theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), Color(0.86, 0.65, 0.38), 2))
 return theme

static func _style(bg: Color, border: Color, thickness: int) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = bg
 style.border_color = border
 style.set_border_width_all(thickness)
 style.content_margin_left = 15
 style.content_margin_right = 15
 style.content_margin_top = 7
 style.content_margin_bottom = 7
 return style
