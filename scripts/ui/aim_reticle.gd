extends Control
## Draw around the exact viewport-ray origin rather than font baseline metrics.
func _draw() -> void:
 var center := size * 0.5
 for segment: Array in [[Vector2(-10, 0), Vector2(-3, 0)], [Vector2(3, 0), Vector2(10, 0)], [Vector2(0, -10), Vector2(0, -3)], [Vector2(0, 3), Vector2(0, 10)]]:
  draw_line(center + segment[0], center + segment[1], Color(0, 0, 0, 0.9), 4.0, true)
  draw_line(center + segment[0], center + segment[1], Color(1, 1, 1), 1.5, true)
