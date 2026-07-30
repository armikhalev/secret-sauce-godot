extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var wolf := (load("res://scenes/wolf.tscn") as PackedScene).instantiate()
	var grass := (load("res://scenes/grass.tscn") as PackedScene).instantiate() as Grass
	world.add_child(wolf)
	grass.position = Vector2(200, 0)
	grass.state = GrassData.State.TASTY
	world.add_child(grass)
	grass.offer_to_npcs()

	for frame in 240:
		await physics_frame
		if not is_instance_valid(grass):
			break

	if wolf.position.x <= 0.0:
		push_error("Wolf did not approach dropped grass.")
		quit(1)
		return

	if is_instance_valid(grass) or wolf.trust != 25:
		push_error("Wolf did not eat tasty grass after approaching it.")
		quit(1)
		return

	if "TRS 25" not in wolf.get_node("DebugStats").text:
		push_error("Wolf debug stats did not update.")
		quit(1)
		return

	print("Wolf approach, eating, and debug stats verified.")
	quit()
