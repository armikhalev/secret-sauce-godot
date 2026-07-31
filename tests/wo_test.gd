extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var wo := (load("res://scenes/wo.tscn") as PackedScene).instantiate()
	var lew := (load("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
	world.add_child(wo)
	lew.position = Vector2(100, 0)
	world.add_child(lew)

	var expected_stats := {
		"bravery": 0,
		"vitality": 100,
		"hunger": 100,
		"aggression": 0,
		"trust": 0,
		"fear": 100,
	}
	for stat: String in expected_stats:
		if wo.get(stat) != expected_stats[stat]:
			push_error("Wo stat '%s' has an unexpected value." % stat)
			quit(1)
			return

	if wo.get_meta("creature_type") != "rabbit-like":
		push_error("Wo is missing rabbit-like metadata.")
		quit(1)
		return

	for frame in 180:
		await physics_frame
		if not is_instance_valid(lew):
			break

	if wo.position.x <= 0.0:
		push_error("Wo did not hop toward lew.")
		quit(1)
		return

	if is_instance_valid(lew) or wo.hunger != 75:
		push_error("Wo did not eat lew and reduce hunger.")
		quit(1)
		return

	print("Wo stats, metadata, hopping, and lew eating verified.")
	quit()
