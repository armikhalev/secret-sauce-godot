extends Label

@export var player_path: NodePath

var player: CharacterBody2D


func _ready() -> void:
	if player_path.is_empty():
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	else:
		player = get_node(player_path) as CharacterBody2D
	if player == null:
		push_error("LewHud could not find the player.")
		return
	player.lew_inventory_changed.connect(_update_text)
	player.wo_inventory_changed.connect(_update_text)
	var inventory_menu := get_node_or_null("../../InventoryMenu")
	if inventory_menu != null and inventory_menu.has_signal("menu_visibility_changed"):
		inventory_menu.menu_visibility_changed.connect(_on_menu_visibility_changed)
	_apply_background()
	_update_text()


func _update_text() -> void:
	var lines: Array[String] = ["SAWSUM LI NONPESA", "[I] koyto"]
	_append_item_count(lines, "lew", player.lew_inventory.size())
	_append_item_count(lines, "wo", player.wo_inventory)
	text = "\n".join(lines)
	var panel := get_parent() as Control
	if panel != null:
		panel.offset_top = panel.offset_bottom - (float(lines.size()) * 30.0 + 20.0)


func _append_item_count(lines: Array[String], item_name: String, count: int) -> void:
	if count > 0:
		lines.append("%s %d" % [item_name, count])


func _on_menu_visibility_changed(is_open: bool) -> void:
	get_parent().visible = not is_open


func _apply_background() -> void:
	var panel := get_parent() as PanelContainer
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.035, 0.72)
	style.border_color = Color(1.0, 0.88, 0.52, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
