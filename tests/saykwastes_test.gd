extends SceneTree


func _initialize() -> void:
	var saykwastes_scene := load("res://scenes/saykwastes.tscn") as PackedScene
	var saykwastes := saykwastes_scene.instantiate()

	var expected_stats := {
		"bravery": 0,
		"vitality": 100,
		"hunger": 0,
		"aggression": 0,
		"trust": 0,
		"fear": 0,
	}

	for stat: String in expected_stats:
		if saykwastes.get(stat) != expected_stats[stat]:
			push_error("Saykwastes stat '%s' has an unexpected value." % stat)
			saykwastes.free()
			quit(1)
			return

	if saykwastes.get_node("Label").text != "saykwastes":
		push_error("Saykwastes label is missing.")
		saykwastes.free()
		quit(1)
		return

	print("Saykwastes scene and stats verified.")
	saykwastes.free()
	quit()
