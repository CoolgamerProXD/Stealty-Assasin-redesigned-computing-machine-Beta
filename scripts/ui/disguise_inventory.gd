class_name DisguiseInventory
extends CanvasLayer
## Pause-safe field wardrobe. The available role permissions are shown inline;
## outfit changes only use clothing the player has actually recovered.
signal outfit_selected(outfit_id: String)
var player: HotelPlayer
var panel: PanelContainer
var content: VBoxContainer
var opened: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.03, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = PanelContainer.new()
	panel.theme = BlacklineTheme.create()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -285)
	panel.size = Vector2(620, 570)
	panel.custom_minimum_size = Vector2(620, 570)
	shade.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	visible = false

func open_for(target: HotelPlayer) -> void:
	player = target
	opened = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()

func _refresh() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = "FIELD WARDROBE  /  RECOVERED CLOTHING"
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)
	var hint := Label.new()
	hint.text = "Select an acquired outfit. Access is role-specific; security can still question suspicious behaviour."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	if player:
		var ids: Array[String] = player.outfit_inventory.duplicate()
		ids.sort()
		for outfit_id: String in ids:
			var spec := DisguiseSystem.outfit(outfit_id)
			var button := Button.new()
			var permissions := PackedStringArray(spec["permissions"])
			var access := ", ".join(permissions)
			button.text = "%s%s\n%s  /  ACCESS: %s" % ["EQUIPPED  ·  " if player.outfit_id == outfit_id else "", spec["name"], spec["category"], access]
			button.custom_minimum_size = Vector2(0, 58)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.disabled = player.outfit_id == outfit_id
			button.pressed.connect(func() -> void: outfit_selected.emit(outfit_id); close_inventory())
			rows.add_child(button)
	var close := Button.new()
	close.text = "CLOSE  /  I"
	close.custom_minimum_size.y = 44
	close.pressed.connect(close_inventory)
	content.add_child(close)

func close_inventory() -> void:
	if not opened: return
	opened = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("disguise_inventory"):
		close_inventory()
		get_viewport().set_input_as_handled()
	elif opened and event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()
