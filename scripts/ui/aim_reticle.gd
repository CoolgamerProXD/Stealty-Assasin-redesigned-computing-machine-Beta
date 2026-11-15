extends Control
## Draw around the exact viewport-ray origin rather than font baseline metrics.
var hit_timer: float = 0.0

func confirm_hit() -> void:
 hit_timer = 0.5
 queue_redraw()

func _process(delta: float) -> void:
 if hit_timer > 0.0:
  hit_timer = maxf(0.0, hit_timer - delta)
  if hit_timer == 0.0: queue_redraw()

func _draw() -> void:
 var center := size * 0.5
 for segment: Array in [[Vector2(-10, 0), Vector2(-3, 0)], [Vector2(3, 0), Vector2(10, 0)], [Vector2(0, -10), Vector2(0, -3)], [Vector2(0, 3), Vector2(0, 10)]]:
  draw_line(center + segment[0], center + segment[1], Color(0, 0, 0, 0.9), 4.0, true)
  draw_line(center + segment[0], center + segment[1], Color(1, 1, 1), 1.5, true)
 if hit_timer > 0.0:
  for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
   draw_line(center + corner * 5.0, center + corner * 11.0, Color(1.0, 0.73, 0.32), 2.0, true)
