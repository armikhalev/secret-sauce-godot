extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	var player = game.get_node("World/Entities/Player")
	var menu = game.get_node("UI/InventoryMenu")
	game.get_node("World/Entities/NPCs/Wo").queue_free()
	game.get_node("World/Items/Lew").queue_free()
	var item := LewData.new()
	player.collect_lew(item)
	player.collect_lew(LewData.new())
	menu.set_menu_open(true)

	if not menu.visible:
		push_error("Inventory menu did not open correctly.")
		quit(1)
		return

	var down_arrow := InputEventKey.new()
	down_arrow.physical_keycode = KEY_DOWN
	down_arrow.pressed = true
	Input.parse_input_event(down_arrow)
	await process_frame
	if menu.selected_item_index != 1:
		push_error("Keyboard Down arrow did not select the next inventory item.")
		quit(1)
		return
	menu._select_item(0)

	player.change_vitality(25, false)
	if "75 / 100" not in menu.player_stats_label.text:
		push_error("Player stats panel did not update.")
		quit(1)
		return

	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	if player.position.x <= 0.0:
		push_error("Player could not move while the inventory menu was open.")
		quit(1)
		return

	menu._change_selected_state(-1)
	if player.lew_inventory[0].state != LewData.State.TASTY:
		push_error("Inventory navigation did not change the lew state.")
		quit(1)
		return

	player.lew_inventory.remove_at(1)
	player.lew_inventory_changed.emit()

	var saykwastes = game.get_node("World/Entities/NPCs/Saykwastes")
	saykwastes.global_position = Vector2(260, 0)
	player.global_position = Vector2(150, 0)
	player.rotation = PI / 2.0
	menu._drop_selected_item()
	await physics_frame
	await physics_frame

	if not player.lew_inventory.is_empty() or saykwastes.trust != 25:
		push_error(
			"Dropped tasty lew failed: inventory=%d trust=%d"
			% [player.lew_inventory.size(), saykwastes.trust]
		)
		quit(1)
		return

	player.grant_charm(player.CIRCLE_HIT_CHARM)
	player.toggle_charm(player.CIRCLE_HIT_CHARM)
	player.grant_charm(player.MAGNET_BACK_CHARM)
	menu.rebuild_item_list()
	if player.get_used_charm_notches() != 1 or menu.selectable_kinds.count("charm") != 2:
		push_error("The menu did not show both charms and the single occupied notch.")
		quit(1)
		return
	menu._select_item(menu.selectable_kinds.find("charm"))
	menu._drop_selected_item()
	if player.is_charm_equipped(player.CIRCLE_HIT_CHARM):
		push_error("Selecting an installed charm did not remove it from the notch.")
		quit(1)
		return
	menu._select_item(menu.selectable_data.find(player.MAGNET_BACK_CHARM))
	menu._drop_selected_item()
	if not player.is_charm_equipped(player.MAGNET_BACK_CHARM) or player.get_used_charm_notches() != 1:
		push_error("The magnet-back charm could not be installed into the one notch.")
		quit(1)
		return

	menu.set_menu_open(false)
	if menu.visible:
		push_error("Inventory menu did not close correctly.")
		quit(1)
		return

	print("Lew inventory and charm menu verified.")
	quit()
