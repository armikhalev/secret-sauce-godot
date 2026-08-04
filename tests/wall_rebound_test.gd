extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var struck_wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	var stopping_wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(struck_wall)
	add_child(stopping_wall)
	player.position = Vector2.ZERO
	player.rotation = 0.0
	struck_wall.position = Vector2(0, -70)
	stopping_wall.position = Vector2(0, 180)
	await get_tree().physics_frame

	player._attack_with_stick()
	await get_tree().create_timer(0.16).timeout
	assert(player.is_rebounding, "hitting a wall with the stick must begin the rebound")
	var starting_position: Vector2 = player.position
	Input.action_press("move_up")
	for frame in 90:
		await get_tree().physics_frame
		if not player.is_rebounding:
			break
	Input.action_release("move_up")
	assert(player.position.y > starting_position.y, "the wall must throw the player away from the impact")
	assert(not player.is_rebounding, "the rebound must stop at the next solid object")
	assert(player.velocity == Vector2.ZERO, "the player must stop after the rebound collision")
	get_tree().quit(0)
