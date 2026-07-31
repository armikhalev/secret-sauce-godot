extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame

	if get_nodes_in_group("wo").size() != 2:
		push_error("Living saykwastes did not limit wo population to 2.")
		quit(1)
		return

	var saykwastes = game.get_node("World/Entities/NPCs/Saykwastes")
	if saykwastes.get_meta("creature_type") != "square wolf":
		push_error("Saykwastes is missing square wolf metadata.")
		quit(1)
		return

	var population = game.get_node("WoPopulation")
	population.spawn_timer.wait_time = 0.03
	saykwastes._die()

	for frame in 120:
		await process_frame
		if get_nodes_in_group("wo").size() == 10:
			break

	if get_nodes_in_group("wo").size() != 10:
		push_error("Wo population did not grow to 10 after saykwastes died.")
		quit(1)
		return

	await process_frame
	await process_frame
	if get_nodes_in_group("wo").size() != 10:
		push_error("Wo population exceeded its limit of 10.")
		quit(1)
		return

	print("Wo living/dead saykwastes population limits verified.")
	quit()
