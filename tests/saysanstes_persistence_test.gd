extends Node


func _ready() -> void:
	GameState.saykwastes_is_dead = false
	GameState.saysanstes_state.clear()
	var first := await _create_setup()
	first.saysanstes._on_conversation_range_entered(first.player)
	first.saysanstes._answer_question(true)
	first.player.wo_inventory = 2
	first.saysanstes._deliver_requested_items()
	assert(first.saysanstes.wo_remaining == 3)
	first.root.queue_free()
	await get_tree().process_frame

	var restored := await _create_setup()
	assert(restored.saysanstes.question_answered, "the answered question must stay answered after returning")
	assert(restored.saysanstes.lew_demand_started, "the demand must remain active after returning")
	assert(restored.saysanstes.wo_remaining == 3, "partial demand progress must persist")
	restored.saysanstes._on_conversation_range_entered(restored.player)
	assert(not restored.saysanstes.get_node("Dialogue/Panel").visible, "returning must not show the question again")
	assert(restored.saysanstes.demand_label.visible, "returning must show the outstanding demand")
	restored.root.queue_free()
	GameState.saysanstes_state.clear()
	get_tree().quit(0)


func _create_setup() -> Dictionary:
	var setup_root := Node.new()
	add_child(setup_root)
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var saypyastes := (load("res://scenes/saypyastes.tscn") as PackedScene).instantiate()
	var saysanstes := (load("res://scenes/saysanstes.tscn") as PackedScene).instantiate()
	saysanstes.persistent_state = true
	setup_root.add_child(player)
	setup_root.add_child(saypyastes)
	setup_root.add_child(saysanstes)
	await get_tree().process_frame
	return {"root": setup_root, "player": player, "saysanstes": saysanstes}
