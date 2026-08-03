extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	var wo := (load("res://scenes/wo.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(saykwastes)
	add_child(wo)
	saykwastes.set_physics_process(false)
	wo.set_physics_process(false)

	player.position = Vector2.ZERO
	wo.position = Vector2(55, 0)
	saykwastes.position = Vector2(80, 0)
	await get_tree().process_frame

	player._attack_with_stick()
	await get_tree().create_timer(0.4).timeout
	assert(saykwastes.bravery == 49, "saykwastes bravery must fall on the first hit")
	assert(saykwastes.fear == 1, "saykwastes fear must rise on the first hit")
	assert(player.bravery == 1, "player bravery must rise on the first hit")
	assert(wo.vitality == 80, "a closer wo must not prevent saykwastes from being hit")

	player._attack_with_stick()
	await get_tree().create_timer(0.4).timeout
	assert(saykwastes.bravery == 48, "saykwastes bravery must fall on every completed hit")
	assert(saykwastes.fear == 2, "saykwastes fear must rise on every completed hit")
	assert(player.bravery == 2, "player bravery must rise on every completed hit")
	get_tree().quit(0)
