extends Node


func _ready() -> void:
	GameState.big_wo_circle_hit_removed = true
	GameState.big_wo_lew_encounter_completed = false
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var big_wo := (load("res://scenes/big_wo.tscn") as PackedScene).instantiate()
	var left_exit := (load("res://scenes/scene_exit.tscn") as PackedScene).instantiate()
	var right_exit := (load("res://scenes/scene_exit.tscn") as PackedScene).instantiate()
	big_wo.encounter_spawn_interval = 0.001
	add_child(player)
	add_child(left_exit)
	add_child(right_exit)
	add_child(big_wo)
	player.global_position = Vector2(900, 0)
	for frame in 120:
		await get_tree().process_frame
		if big_wo.encounter_spawned == 100:
			break
	var pursuers := get_tree().get_nodes_in_group("giant_wo_lew")
	assert(pursuers.size() == 100, "the encounter must spawn exactly one hundred eyed lew")
	assert(big_wo.encounter_spawned == 100, "all one hundred lew must spawn one interval apart")
	await get_tree().physics_frame
	assert(not left_exit.visible and not left_exit.monitoring, "the left door must lock during the encounter")
	assert(not right_exit.visible and not right_exit.monitoring, "the right door must lock during the encounter")
	var pursuer := pursuers[0] as Node2D
	for other_pursuer in pursuers:
		if other_pursuer != pursuer:
			other_pursuer.set("chase_speed", 0.0)
			other_pursuer.set("damage", 0)
	pursuer.global_position = Vector2(400, 0)
	var position_before_chase := pursuer.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(pursuer.global_position.distance_to(player.global_position) < position_before_chase.distance_to(player.global_position), "eyed lew must chase the player")
	pursuer.global_position = player.global_position
	await get_tree().physics_frame
	assert(player.vitality == 99, "an eyed lew contact must deal exactly one vitality damage")
	big_wo.encounter_consumed = 99
	pursuer.global_position = big_wo.lew_mouth.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(big_wo.encounter_consumed == 100, "Giant Wo's lew mouth must consume the final pursuer")
	assert(left_exit.visible and left_exit.monitoring, "the left door must return after all lew are consumed")
	assert(right_exit.visible and right_exit.monitoring, "the right door must return after all lew are consumed")
	assert(GameState.big_wo_lew_encounter_completed, "encounter completion must persist")
	GameState.big_wo_circle_hit_removed = false
	GameState.big_wo_lew_encounter_completed = false
	get_tree().quit(0)
