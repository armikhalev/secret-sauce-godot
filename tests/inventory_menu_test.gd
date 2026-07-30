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
	var item := GrassData.new()
	player.collect_grass(item)
	menu.set_menu_open(true)

	if not menu.visible:
		push_error("Inventory menu did not open correctly.")
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

	menu.set_menu_open(false)
	if menu.visible:
		push_error("Inventory menu did not close correctly.")
		quit(1)
		return

	print("Grass inventory menu verified.")
	quit()
