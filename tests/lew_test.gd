extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game

	var player := game.get_node("World/Entities/Player")
	var saykwastes := game.get_node("World/Entities/NPCs/Saykwastes")
	var lew := game.get_node("World/Items/Lew") as Lew
	if lew.get_node("Label").text != "lew":
		push_error("Lew label is missing.")
		quit(1)
		return

	lew._on_body_entered(player)
	await process_frame

	if player.lew_inventory.size() != 1:
		push_error("Lew was not collected.")
		quit(1)
		return

	player.set_lew_state(0, LewData.State.TASTY)
	var tasty_lew: Lew = player.drop_lew(0, saykwastes.global_position)
	saykwastes.eat_lew(tasty_lew)
	await process_frame

	if saykwastes.trust != 25:
		push_error("Tasty lew did not increase saykwastes trust.")
		quit(1)
		return

	var poisonous_lew := (load("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
	poisonous_lew.state = LewData.State.POISONOUS
	game.add_child(poisonous_lew)
	saykwastes.eat_lew(poisonous_lew)
	await process_frame

	if saykwastes.vitality != 75:
		push_error("Poisonous lew did not reduce saykwastes vitality.")
		quit(1)
		return

	print("Lew collection, state changes, dropping, and saykwastes effects verified.")
	quit()
