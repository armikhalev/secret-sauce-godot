extends Node


func _ready() -> void:
	GameState.saykwastes_is_dead = true
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var saysanstes := (load("res://scenes/saysanstes.tscn") as PackedScene).instantiate()
	var saypyastes_a := (load("res://scenes/saypyastes.tscn") as PackedScene).instantiate()
	var saypyastes_b := (load("res://scenes/saypyastes.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(saypyastes_a)
	add_child(saypyastes_b)
	add_child(saysanstes)
	await get_tree().process_frame

	_add_lew(player)
	_add_lew(player)
	assert(saysanstes.greed == 30, "wolf death must push initial greed above 20")
	saysanstes._on_conversation_range_entered(player)
	assert(not saysanstes.lew_demand_started, "confiscation must wait until the question is answered")
	saysanstes._answer_question(true)
	assert(saysanstes.respecting == 1, "a truthful answer must increase respecting")
	assert(saysanstes.lew_demand_started, "greed 30 and aggression 75 must start confiscation")
	assert(player.lew_inventory.is_empty(), "all carried lew must be confiscated")
	assert(saysanstes.lew_remaining == 5, "the follow-up demand must request five new lew")
	assert(saypyastes_a.stored_lew.size() + saypyastes_b.stored_lew.size() == 2, "one randomly chosen saypyastes must receive every confiscated lew")
	get_tree().quit(0)


func _add_lew(player: Node) -> void:
	var lew_data := LewData.new()
	player.lew_inventory.append(lew_data)
