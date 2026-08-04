extends Node


func _ready() -> void:
	GameState.saykwastes_is_dead = false
	await _test_correct_answer()
	await _test_wrong_answer()
	get_tree().quit(0)


func _test_correct_answer() -> void:
	var setup := await _create_setup()
	var player: Node = setup.player
	var saysanstes: Node = setup.saysanstes
	player.wo_inventory = 2
	saysanstes._on_conversation_range_entered(player)
	assert(saysanstes.question_label.text == "wo aw mew e lew?", "living wolf must use the wo question")
	saysanstes._answer_question(true)
	assert(player.wo_inventory == 2, "correct answer must not confiscate existing wo")
	assert(saysanstes.lew_remaining == 0 and saysanstes.wo_remaining == 5, "correct answer must request five wo")
	assert(saysanstes.demand_label.text == "mi ma e pya (5) wo")
	setup.root.queue_free()
	await get_tree().process_frame


func _test_wrong_answer() -> void:
	var setup := await _create_setup()
	var player: Node = setup.player
	var saysanstes: Node = setup.saysanstes
	player.lew_inventory.append(LewData.new())
	player.lew_inventory.append(LewData.new())
	player.wo_inventory = 2
	saysanstes._on_conversation_range_entered(player)
	saysanstes._answer_question(false)
	assert(saysanstes.question_label.text == "hahaha", "wrong answer must receive hahaha")
	await get_tree().create_timer(1.1).timeout
	assert(player.lew_inventory.is_empty() and player.wo_inventory == 0, "wrong answer must confiscate everything")
	assert(saysanstes.lew_remaining == 5 and saysanstes.wo_remaining == 3, "wrong answer must request five lew and three wo")
	assert(saysanstes.demand_label.text == "mi ma e pya (5) lew i san (3) wo")
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
