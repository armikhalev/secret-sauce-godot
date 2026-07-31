extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game

	var player := game.get_node("World/Entities/Player")
	var saykwastes := game.get_node("World/Entities/NPCs/Saykwastes")
	var grass := game.get_node("World/Items/Lew") as Grass
	if grass.get_node("Label").text != "lew":
		push_error("Lew label is missing.")
		quit(1)
		return

	grass._on_body_entered(player)
	await process_frame

	if player.grass_inventory.size() != 1:
		push_error("Grass was not collected.")
		quit(1)
		return

	player.set_grass_state(0, GrassData.State.TASTY)
	var tasty_grass: Grass = player.drop_grass(0, saykwastes.global_position)
	saykwastes.eat_grass(tasty_grass)
	await process_frame

	if saykwastes.trust != 25:
		push_error("Tasty grass did not increase saykwastes trust.")
		quit(1)
		return

	var poisonous_grass := (load("res://scenes/grass.tscn") as PackedScene).instantiate() as Grass
	poisonous_grass.state = GrassData.State.POISONOUS
	game.add_child(poisonous_grass)
	saykwastes.eat_grass(poisonous_grass)
	await process_frame

	if saykwastes.vitality != 75:
		push_error("Poisonous grass did not reduce saykwastes vitality.")
		quit(1)
		return

	print("Grass collection, state changes, dropping, and saykwastes effects verified.")
	quit()
