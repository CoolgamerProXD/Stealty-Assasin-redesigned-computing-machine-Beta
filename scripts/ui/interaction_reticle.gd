extends Control
## Small original prompt reticle. Visibility is controlled by a real reachable item.
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 var c := size * 0.5
 draw_circle(c, 3.5, Color(0,0,0,0.65))
 draw_circle(c, 1.8, Color(0.95,0.84,0.60,0.95))
