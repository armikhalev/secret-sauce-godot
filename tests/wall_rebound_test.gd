extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var struck_wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	var stopping_wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	var struck_bush := (load("res://scenes/bush.tscn") as PackedScene).instantiate()
	var bush_stopping_wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(struck_wall)
	add_child(stopping_wall)
	add_child(struck_bush)
	add_child(bush_stopping_wall)
	struck_wall.position = Vector2(-200, -50)
	stopping_wall.position = Vector2(-200, 180)
	struck_bush.position = Vector2(200, -70)
	bush_stopping_wall.position = Vector2(200, 180)
	await get_tree().physics_frame
	player.circle_hit_unlocked = true
	await _verify_rebound(player, Vector2(-200, 0), "wall")
	await get_tree().create_timer(0.15).timeout
	await _verify_rebound(player, Vector2(200, 0), "solid bush")
	get_tree().quit(0)


func _verify_rebound(player: CharacterBody2D, start: Vector2, surface_name: String) -> void:
	player.position = start
	player.rotation = 0.0
	player._attack_with_circle()
	await get_tree().create_timer(0.16).timeout
	assert(player.is_rebounding, "hitting a %s with the attack circle must begin the rebound" % surface_name)
	var starting_position: Vector2 = player.position
	Input.action_press("move_up")
	for frame in 90:
		await get_tree().physics_frame
		if not player.is_rebounding:
			break
	Input.action_release("move_up")
	assert(player.position.y > starting_position.y, "the %s must throw the player away from the impact" % surface_name)
	assert(not player.is_rebounding, "the rebound must stop at the next solid object")
	assert(player.velocity == Vector2.ZERO, "the player must stop after the rebound collision")
