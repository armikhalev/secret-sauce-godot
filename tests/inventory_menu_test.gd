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
	game.get_node("World/Items/Grass").queue_free()
	var item := GrassData.new()
	player.collect_grass(item)
	menu.set_menu_open(true)

	if not menu.visible:
		push_error("Inventory menu did not open correctly.")
		quit(1)
		return

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
	if player.grass_inventory[0].state != GrassData.State.TASTY:
		push_error("Inventory navigation did not change the grass state.")
		quit(1)
		return

	var wolf = game.get_node("World/Entities/NPCs/Wolf")
	player.global_position = Vector2(150, 0)
	player.rotation = PI / 2.0
	menu._drop_selected_item()
	await physics_frame
	await physics_frame

	if not player.grass_inventory.is_empty() or wolf.trust != 25:
		push_error(
			"Dropped tasty grass failed: inventory=%d trust=%d"
			% [player.grass_inventory.size(), wolf.trust]
		)
		quit(1)
		return

	menu.set_menu_open(false)
	if menu.visible:
		push_error("Inventory menu did not close correctly.")
		quit(1)
		return

	print("Grass inventory menu verified.")
	quit()
