extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	await physics_frame

	var obstacles = game.get_node("World/Environment/Obstacles")
	for obstacle_name in ["WallNorth", "WallEast", "WallSouthWest", "BushNorthWest", "BushSouth", "BushEast"]:
		var obstacle = obstacles.get_node(obstacle_name)
		if obstacle.get_node("CollisionShape2D").shape == null:
			push_error("Obstacle '%s' has no collision shape." % obstacle_name)
			quit(1)
			return

	var player = game.get_node("World/Entities/Player")
	var saykwastes = game.get_node("World/Entities/NPCs/Saykwastes")
	player.enter_concealment()
	var attacked_while_hidden: bool = saykwastes._process_player_attack(0.1)
	if attacked_while_hidden or saykwastes.aggression != 0:
		push_error("Concealment did not suppress saykwastes aggression.")
		quit(1)
		return

	player.exit_concealment()
	saykwastes._process_player_attack(0.1)
	if saykwastes.aggression != saykwastes.get_aggression_toward(player):
		push_error("Saykwastes aggression did not return after concealment.")
		quit(1)
		return

	var hiding_bush = obstacles.get_node("HidingBush")
	if hiding_bush.get_meta("concealment_range_in_bush_widths") != 5:
		push_error("Hiding bush range metadata is incorrect.")
		quit(1)
		return

	print("Solid obstacles and hiding-bush aggression suppression verified.")
	quit()
