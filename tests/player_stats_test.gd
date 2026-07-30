extends SceneTree


func _initialize() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate()

	player.change_bravery(175, true)
	player.change_vitality(30, false)
	player.change_energy(150, false)

	if player.bravery != 100 or player.vitality != 70 or player.energy != 0:
		push_error("Player stats did not change or clamp correctly.")
		quit(1)
		return

	print(
		"Player stats verified: bravery=%d vitality=%d energy=%d"
		% [player.bravery, player.vitality, player.energy]
	)
	player.free()
	quit()
