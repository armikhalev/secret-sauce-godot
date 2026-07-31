extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	var grass := (load("res://scenes/grass.tscn") as PackedScene).instantiate() as Grass
	world.add_child(saykwastes)
	grass.position = Vector2(600, 0)
	grass.state = GrassData.State.TASTY
	world.add_child(grass)
	grass.offer_to_npcs()
	await physics_frame
	await physics_frame

	if not saykwastes.position.is_equal_approx(Vector2.ZERO):
		push_error("Saykwastes noticed grass outside its detection radius.")
		quit(1)
		return

	grass.position = Vector2(550, 0)

	for frame in 540:
		await physics_frame
		if not is_instance_valid(grass):
			break

	if saykwastes.position.x <= 0.0:
		push_error("Saykwastes did not approach dropped grass.")
		quit(1)
		return

	if is_instance_valid(grass) or saykwastes.trust != 25:
		push_error("Saykwastes did not eat tasty grass after approaching it.")
		quit(1)
		return

	if "TRS 25" not in saykwastes.get_node("DebugStats").text:
		push_error("Saykwastes debug stats did not update.")
		quit(1)
		return

	print("Saykwastes approach, eating, and debug stats verified.")
	quit()
