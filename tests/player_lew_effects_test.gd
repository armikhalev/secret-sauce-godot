extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	add_child(player)
	await get_tree().process_frame

	player.vitality = 90
	_add_lew(player, LewData.State.PLAIN)
	assert(player.eat_lew(0))
	assert(player.vitality == 95, "plain lew must restore exactly 5 vitality")

	_add_lew(player, LewData.State.POISONOUS)
	assert(player.eat_lew(0))
	assert(player.is_poisoned, "poisonous lew must start poisoning")
	_add_lew(player, LewData.State.POISONOUS)
	assert(player.eat_lew(0))
	assert(player.poison_stacks == 2, "additional poisonous lew must add poison stacks")
	await get_tree().create_timer(1.1).timeout
	assert(player.vitality == 93, "two poison stacks must remove 2 vitality per second")

	_add_lew(player, LewData.State.TASTY)
	assert(player.eat_lew(0))
	assert(player.is_poisoned, "one tasty lew must leave the second poison stack active")
	assert(player.poison_stacks == 1, "one tasty lew must cure exactly one poison stack")
	assert(player.vitality == 93, "tasty lew must not restore vitality")
	await get_tree().create_timer(1.1).timeout
	assert(player.vitality == 92, "one remaining poison stack must remove 1 vitality per second")

	_add_lew(player, LewData.State.TASTY)
	assert(player.eat_lew(0))
	assert(not player.is_poisoned, "the final tasty lew must stop poisoning")
	assert(player.poison_stacks == 0, "the final poison stack must be removed")
	await get_tree().create_timer(1.1).timeout
	assert(player.vitality == 92, "no poison damage may occur after every stack is cured")
	get_tree().quit(0)


func _add_lew(player: Node, state: LewData.State) -> void:
	var lew_data := LewData.new()
	lew_data.state = state
	player.lew_inventory.append(lew_data)
