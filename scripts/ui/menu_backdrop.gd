extends Control
## Original abstract title art, drawn as a single inexpensive canvas item.
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 var w := size.x
 var h := size.y
 draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.045, 0.055))
 draw_colored_polygon(PackedVector2Array([Vector2(w * 0.20, 0), Vector2(w * 0.72, 0), Vector2(w * 0.49, h), Vector2(0, h)]), Color(0.045, 0.075, 0.082))
 draw_colored_polygon(PackedVector2Array([Vector2(w * 0.58, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * 0.36, h)]), Color(0.032, 0.055, 0.063))
 for i: int in range(7):
  var x := w * (0.08 + float(i) * 0.075)
  draw_line(Vector2(x, h * 0.40), Vector2(x - h * 0.20, h), Color(0.25, 0.34, 0.33, 0.22), 1.0)
 draw_arc(Vector2(w * 0.22, h * 0.72), h * 0.19, 0, TAU, 72, Color(0.64, 0.46, 0.29, 0.20), 1.5, true)
 draw_arc(Vector2(w * 0.22, h * 0.72), h * 0.15, 0, TAU, 72, Color(0.64, 0.46, 0.29, 0.14), 1.0, true)
 draw_line(Vector2(80, h - 58), Vector2(w - 80, h - 58), Color(0.65, 0.48, 0.31, 0.35), 1.0)
