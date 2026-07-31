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
	player.position = Vector2(75, 0)
	_feed_tasty_lew(world, saykwastes, player)

	for frame in 20:
		await physics_frame
		if player.vitality == 75:
			break

	if player.vitality != 75:
		push_error("Saykwastes did not attack when trust was below aggression.")
		quit(1)
		return

	for frame in 120:
		await physics_frame
	if player.vitality != 75:
		push_error("Trust did not reduce attack frequency.")
		quit(1)
		return

	for frame in 300:
		await physics_frame
		if player.vitality == 50:
			break

	if player.vitality != 50:
		push_error("Saykwastes never attacked again at partial trust.")
		quit(1)
		return

	_feed_tasty_lew(world, saykwastes, player)
	_feed_tasty_lew(world, saykwastes, player)
	var vitality_at_full_trust: int = player.vitality
	for frame in 180:
		await physics_frame
	if player.vitality != vitality_at_full_trust:
		push_error("Saykwastes attacked when trust met aggression.")
		quit(1)
		return

	var other_npc := Node.new()
	other_npc.add_to_group("npc")
	world.add_child(other_npc)
	saykwastes.change_trust_toward(other_npc, 90)
	saykwastes.set_aggression_toward(other_npc, 140)

	if saykwastes.get_trust_toward(player) != 75:
		push_error("Another NPC's trust changed player trust.")
		quit(1)
		return
	if saykwastes.get_trust_toward(other_npc) != 90:
		push_error("Per-NPC trust was not stored separately.")
		quit(1)
		return
	if saykwastes.get_aggression_toward(other_npc) != 140:
		push_error("Per-NPC aggression was not stored separately.")
		quit(1)
		return

	print("Per-target trust, attack delay, and pacification verified.")
	quit()


func _feed_tasty_lew(world: Node2D, saykwastes: CharacterBody2D, player: CharacterBody2D) -> void:
	var lew := (load("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
	lew.state = LewData.State.TASTY
	lew.offered_by = player
	world.add_child(lew)
	saykwastes.eat_lew(lew)
