extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame

	for npc in get_nodes_in_group("wo"):
		npc.process_mode = Node.PROCESS_MODE_DISABLED
	for npc in get_nodes_in_group("saykwastes"):
		npc.process_mode = Node.PROCESS_MODE_DISABLED

	var population = game.get_node("LewPopulation")
	var item_container = game.get_node("World/Items")
	if population._get_area_lew().size() != 4:
		push_error("This area did not start with exactly 4 lew.")
		quit(1)
		return

	var removed_lew := item_container.get_node("Lew") as Lew
	var removed_slot: int = removed_lew.spawn_slot_id
	var removed_position: Vector2 = removed_lew.position
	population.spawn_timer.wait_time = 0.2
	removed_lew.remove_from_world()
	await process_frame

	if population.spawn_timer.is_stopped() or population.spawn_timer.time_left < 0.05:
		push_error(
			"Lew removal did not restart the full countdown: time_left=%.3f"
			% population.spawn_timer.time_left
		)
		quit(1)
		return

	population.spawn_timer.wait_time = 0.03
	population.spawn_timer.start()
	for frame in 60:
		await process_frame
		if population._get_area_lew().size() == 4:
			break

	if population._get_area_lew().size() != 4:
		push_error("Removed lew did not respawn.")
		quit(1)
		return

	var respawned_lew: Lew
	for lew in population._get_area_lew():
		if lew.spawn_slot_id == removed_slot:
			respawned_lew = lew
			break

	if not is_instance_valid(respawned_lew):
		push_error("Lew did not return to its original slot.")
		quit(1)
		return

	if not respawned_lew.position.is_equal_approx(removed_position):
		push_error("Lew respawned at a different position.")
		quit(1)
		return

	await process_frame
	await process_frame
	if population._get_area_lew().size() != 4:
		push_error("This area's lew population exceeded 4.")
		quit(1)
		return

	print("Area-local fixed lew slots, countdown reset, and cap verified.")
	quit()
