extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var interface := (load("res://scenes/player_interface.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(interface)
	await get_tree().process_frame
	var title := interface.get_node("MarginContainer/Title") as Label
	assert("lew" not in title.text and "wo" not in title.text, "HUD must hide resources whose count is zero")
	var panel := interface.get_node("MarginContainer") as PanelContainer
	var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(panel_style.bg_color.a > 0.0 and panel_style.bg_color.a < 1.0, "HUD must use a semi-transparent background")
	var inventory_menu := interface.get_node("InventoryMenu")
	inventory_menu.set_menu_open(true)
	assert(not panel.visible, "HUD must hide while the inventory menu is open")
	inventory_menu.set_menu_open(false)
	assert(panel.visible, "HUD must return when the inventory menu closes")
	player.collect_lew(LewData.new())
	player.collect_wo()
	player.collect_wo()
	assert("lew 1" in title.text, "HUD must refresh the lew count")
	assert("wo 2" in title.text, "HUD must refresh the wo count")
	player.lew_inventory.clear()
	player.lew_inventory_changed.emit()
	player.wo_inventory = 0
	player.wo_inventory_changed.emit()
	assert("lew" not in title.text and "wo" not in title.text, "resource rows must disappear again at zero")
	get_tree().quit(0)
