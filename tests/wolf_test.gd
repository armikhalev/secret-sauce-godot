extends SceneTree


func _initialize() -> void:
	var wolf_scene := load("res://scenes/wolf.tscn") as PackedScene
	var wolf := wolf_scene.instantiate()

	var expected_stats := {
		"bravery": 0,
		"vitality": 100,
		"hunger": 0,
		"aggression": 0,
		"trust": 0,
		"fear": 0,
	}

	for stat: String in expected_stats:
		if wolf.get(stat) != expected_stats[stat]:
			push_error("Wolf stat '%s' has an unexpected value." % stat)
			wolf.free()
			quit(1)
			return

	if wolf.get_node("Label").text != "wolf":
		push_error("Wolf label is missing.")
		wolf.free()
		quit(1)
		return

	print("Wolf scene and stats verified.")
	wolf.free()
	quit()
