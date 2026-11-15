extends Control
## Simple original silhouettes; decorative only, never inventory authority.
var item: String = ""

func _ready() -> void:
 custom_minimum_size = Vector2(48,40)
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_item(id: String) -> void:
 if item == id: return
 item = id
 queue_redraw()

func _draw() -> void:
 var ink := Color(0.91,0.87,0.75,0.9)
 if item == "quiet_line":
  draw_arc(Vector2(24,20), 13, 0.3, TAU - 0.3, 24, ink, 2, true)
  draw_line(Vector2(12,12), Vector2(8,8), ink, 3, true)
  draw_line(Vector2(36,12), Vector2(40,8), ink, 3, true)
 else:
  draw_rect(Rect2(5,12,36,7), ink)
  draw_colored_polygon(PackedVector2Array([Vector2(16,19),Vector2(24,19),Vector2(21,32),Vector2(14,32)]), ink)
