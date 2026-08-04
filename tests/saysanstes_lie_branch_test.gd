extends Node


func _ready() -> void:
	GameState.saykwastes_is_dead = true
	await _test_second_yey_branch()
	await _test_second_no_branch()
	get_tree().quit(0)


func _test_second_yey_branch() -> void:
	var setup := await _create_setup()
	var player: Node = setup.player
	var saysanstes: Node = setup.saysanstes
	_add_lew(player)
	_add_lew(player)
	player.wo_inventory = 3
	saysanstes._on_conversation_range_entered(player)
	saysanstes._answer_question(false)
	assert(saysanstes.aggression == 100, "lying about the dead wolf must increase aggression by 25")
	assert(saysanstes.respecting == -10, "lying about the dead wolf must set respecting to -10")
	assert(saysanstes.question_index == 1, "the lie must open the second question")
	assert(player.lew_inventory.size() == 2 and player.wo_inventory == 3, "the first no must not confiscate inventory yet")
	saysanstes._answer_question(true)
	assert(saysanstes.question_label.text == "hahahaha", "the second yey must receive the hahahaha response")
	await get_tree().create_timer(1.1).timeout
	assert(player.lew_inventory.is_empty() and player.wo_inventory == 0, "the second yey must confiscate all lew and wo")
	assert(setup.saypyastes_a.stored_wo + setup.saypyastes_b.stored_wo == 3, "all confiscated wo must go to one saypyastes")
	assert(saysanstes.lew_remaining == 5, "the second yey must request five lew")
	setup.root.queue_free()
	await get_tree().process_frame


func _test_second_no_branch() -> void:
	var setup := await _create_setup()
	var player: Node = setup.player
	var saysanstes: Node = setup.saysanstes
	_add_lew(player)
	player.wo_inventory = 2
	saysanstes._on_conversation_range_entered(player)
	saysanstes._answer_question(false)
	saysanstes._answer_question(false)
	assert(player.lew_inventory.size() == 1 and player.wo_inventory == 2, "the second no must preserve all inventory")
	assert(saysanstes.lew_remaining == 5, "the second no must still request five lew")
	setup.root.queue_free()
	await get_tree().process_frame


func _create_setup() -> Dictionary:
	var setup_root := Node.new()
	add_child(setup_root)
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var saysanstes := (load("res://scenes/saysanstes.tscn") as PackedScene).instantiate()
	var saypyastes_a := (load("res://scenes/saypyastes.tscn") as PackedScene).instantiate()
	var saypyastes_b := (load("res://scenes/saypyastes.tscn") as PackedScene).instantiate()
	setup_root.add_child(player)
	setup_root.add_child(saypyastes_a)
	setup_root.add_child(saypyastes_b)
	setup_root.add_child(saysanstes)
	await get_tree().process_frame
	return {
		"root": setup_root,
		"player": player,
		"saysanstes": saysanstes,
		"saypyastes_a": saypyastes_a,
		"saypyastes_b": saypyastes_b,
	}


func _add_lew(player: Node) -> void:
	player.lew_inventory.append(LewData.new())
