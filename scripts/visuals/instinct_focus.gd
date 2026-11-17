extends Node
class_name InstinctFocus
## Smoothly grades the rendered world while Instinct is held. Eligibility and
## object overlays remain owned by the mission scripts; this layer reveals none.

const FOCUS_SHADER: Shader = preload("res://scripts/visuals/instinct_focus.gdshader")
const RESPONSE_RATE: float = 7.0

var player: HotelPlayer
var focus_amount: float = 0.0
var focus_rect: ColorRect
var focus_material: ShaderMaterial

func _ready() -> void:
 var layer := CanvasLayer.new()
 layer.name = "InstinctWorldGrade"
 # Draw after the 3D world and before the default HUD CanvasLayer.
 layer.layer = -1
 add_child(layer)
 focus_rect = ColorRect.new()
 focus_rect.name = "FocusGrade"
 focus_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 focus_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_material = ShaderMaterial.new()
 focus_material.shader = FOCUS_SHADER
 focus_material.set_shader_parameter("focus_amount", 0.0)
 focus_rect.material = focus_material
 layer.add_child(focus_rect)

func _process(delta: float) -> void:
 update_focus(delta, is_instance_valid(player) and player.instinct_active)

# Kept explicit and deterministic for tests; no world object is inspected here.
func update_focus(delta: float, active: bool) -> void:
 var target := 1.0 if active else 0.0
 var blend := 1.0 - exp(-maxf(delta, 0.0) * RESPONSE_RATE)
 focus_amount = lerpf(focus_amount, target, blend)
 if focus_material:
  focus_material.set_shader_parameter("focus_amount", focus_amount)
