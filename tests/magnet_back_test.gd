extends Node


func _ready() -> void:
	GameState.circle_hit_unlocked = false
	GameState.owned_charms.clear()
	GameState.equipped_charms.clear()
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(wall)
	player.position = Vector2.ZERO
	player.rotation = 0.0
	wall.position = Vector2(0, 300)
	await get_tree().physics_frame
	player.grant_charm(player.MAGNET_BACK_CHARM)
	player.toggle_charm(player.MAGNET_BACK_CHARM)
	var attack := InputEventAction.new()
	attack.action = "attack"
	attack.pressed = true
	player._unhandled_input(attack)
	assert(player.is_magnetizing_back, "the equipped magnet-back charm must activate on attack")
	for frame in 90:
		await get_tree().physics_frame
		if not player.is_magnetizing_back:
			break
	assert(player.position.y > 200.0, "magnet-back must pull the triangle along its rear axis")
	assert(player.position.y < wall.position.y, "magnet-back must stop against the first obstacle")
	assert(not player.is_magnetizing_back and player.velocity == Vector2.ZERO)
	GameState.owned_charms.clear()
	GameState.equipped_charms.clear()
	get_tree().quit(0)
