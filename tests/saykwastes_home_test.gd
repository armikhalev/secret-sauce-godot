extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	world.add_child(saykwastes)
	world.add_child(player)
	await physics_frame

	saykwastes.global_position = Vector2(200, 0)
	player.global_position = Vector2(230, 0)
	player.enter_concealment()
	var distance_before_hiding_return: float = saykwastes.global_position.distance_to(saykwastes.home_position)
	for frame in 60:
		await physics_frame
	var distance_after_hiding_return: float = saykwastes.global_position.distance_to(saykwastes.home_position)

	if distance_after_hiding_return >= distance_before_hiding_return:
		push_error("Saykwastes did not return home when the player hid.")
		quit(1)
		return

	player.exit_concealment()
	player.global_position = Vector2(1000, 0)
	saykwastes.global_position = Vector2(180, 0)
	for frame in 240:
		await physics_frame
		if saykwastes.global_position.is_equal_approx(saykwastes.home_position):
			break

	if not saykwastes.global_position.is_equal_approx(saykwastes.home_position):
		push_error("Saykwastes did not return to its exact home position while idle.")
		quit(1)
		return

	print("Saykwastes hiding disengagement and home return verified.")
	quit()
