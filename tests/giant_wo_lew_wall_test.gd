extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var pursuer := (load("res://scenes/giant_wo_lew.tscn") as PackedScene).instantiate()
	var wall := (load("res://scenes/wall.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(pursuer)
	add_child(wall)
	player.position = Vector2(180, 0)
	pursuer.position = Vector2(-100, 0)
	pursuer.activated = true
	wall.position = Vector2.ZERO
	wall.rotation = PI / 2.0
	for frame in 90:
		await get_tree().physics_frame
	assert(pursuer.position.x < -30.0, "hostile lew must not pass through a wall")
	assert(pursuer.position.x > -100.0, "hostile lew must still chase toward the wall")
	get_tree().quit(0)
