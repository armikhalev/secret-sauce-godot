extends Node


func _ready() -> void:
	GameState.saykwastes_is_dead = false
	GameState.saykwastes_state.clear()
	var first_player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var first_saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	add_child(first_player)
	add_child(first_saykwastes)
	first_saykwastes.set_physics_process(false)
	await get_tree().process_frame
	for index in 3:
		_feed_tasty_lew(first_saykwastes, first_player)
	first_saykwastes.receive_circle_hit(first_player, 0)
	var poisonous := (load("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
	poisonous.state = LewData.State.POISONOUS
	add_child(poisonous)
	first_saykwastes.eat_lew(poisonous)
	assert(first_saykwastes.get_trust_toward(first_player) == 75)
	first_player.queue_free()
	first_saykwastes.queue_free()
	await get_tree().process_frame

	var second_player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var restored := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	add_child(second_player)
	add_child(restored)
	restored.set_physics_process(false)
	await get_tree().process_frame
	assert(restored.bravery == 99 and restored.fear == 1, "bravery and fear must persist")
	assert(restored.vitality == 75 and restored.is_poisoned, "vitality and poison must persist")
	assert(restored.get_trust_toward(second_player) == 75, "player trust must survive a new player instance")
	assert(restored.get_aggression_toward(second_player) == 50, "player aggression must persist")
	assert(restored.get_trust_toward(second_player) > restored.get_aggression_toward(second_player), "friendly Saykwastes must remain friendly")
	var vitality_before: int = second_player.vitality
	assert(not restored._process_player_attack(0.1), "friendly Saykwastes must not resume attacking")
	assert(second_player.vitality == vitality_before)
	GameState.saykwastes_state.clear()
	get_tree().quit(0)


func _feed_tasty_lew(saykwastes: Node, player: Node) -> void:
	var lew := (load("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
	lew.state = LewData.State.TASTY
	lew.offered_by = player
	add_child(lew)
	saykwastes.eat_lew(lew)
