extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	world.add_child(saykwastes)
	world.add_child(player)
	player.position = Vector2(240, 0)

	for frame in 180:
		await physics_frame
		if player.vitality == 75:
			break

	if player.vitality != 75:
		push_error("Saykwastes did not approach and attack the nearby player.")
		quit(1)
		return

	var distance_after_attack: float = saykwastes.global_position.distance_to(player.global_position)
	for frame in 30:
		await physics_frame
	var distance_during_retreat: float = saykwastes.global_position.distance_to(player.global_position)
	if distance_during_retreat <= distance_after_attack:
		push_error("Saykwastes did not retreat after attacking.")
		quit(1)
		return

	for frame in 240:
		await physics_frame
		if player.vitality == 50:
			break

	if player.vitality != 50:
		push_error("Saykwastes did not attack again after retreating.")
		quit(1)
		return

	player.position = Vector2(1000, 0)
	var vitality_after_escape: int = player.vitality
	for frame in 120:
		await physics_frame

	if player.vitality != vitality_after_escape:
		push_error("Saykwastes kept attacking outside its aggression radius.")
		quit(1)
		return

	if "AGR 560" not in saykwastes.get_node("DebugStats").text:
		push_error("Debug stats do not show the aggression radius.")
		quit(1)
		return

	print("Saykwastes aggression radius, attack, retreat, and disengage verified.")
	quit()
