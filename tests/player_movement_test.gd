extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate() as CharacterBody2D
	root.add_child(player)

	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")

	if player.position.x <= 0.0:
		push_error("Player did not move right.")
		quit(1)
		return

	print("Player movement verified: ", player.position)
	quit()
