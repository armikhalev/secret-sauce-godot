extends Node


func _ready() -> void:
	GameState.big_wo_circle_hit_removed = true
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var big_wo := (load("res://scenes/big_wo.tscn") as PackedScene).instantiate()
	big_wo.encounter_spawn_interval = 0.05
	add_child(player)
	add_child(big_wo)
	player.global_position = Vector2(900, 0)
	await get_tree().create_timer(0.6).timeout
	var pursuers := get_tree().get_nodes_in_group("giant_wo_lew")
	assert(pursuers.size() == 10, "the encounter must spawn exactly ten eyed lew")
	assert(big_wo.encounter_spawned == 10, "all ten lew must spawn one interval apart")
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
	pursuer.global_position = big_wo.lew_mouth.global_position
	await get_tree().physics_frame
	assert(big_wo.encounter_consumed == 1, "Giant Wo's lew mouth must consume a pursuer")
	GameState.big_wo_circle_hit_removed = false
	get_tree().quit(0)
