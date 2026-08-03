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
	assert(saykwastes.bravery == 99, "saykwastes bravery must fall on the first hit")
	assert(saykwastes.fear == 1, "saykwastes fear must rise on the first hit")
	assert(player.bravery == 1, "player bravery must rise on the first hit")
	assert(wo.vitality == 80, "a closer wo must not prevent saykwastes from being hit")
	assert(saykwastes.get_roaming_radius() == 2090.0, "fear must reduce the roaming radius linearly")

	player._attack_with_stick()
	await get_tree().create_timer(0.4).timeout
	assert(saykwastes.bravery == 98, "saykwastes bravery must fall on every completed hit")
	assert(saykwastes.fear == 2, "saykwastes fear must rise on every completed hit")
	assert(player.bravery == 2, "player bravery must rise on every completed hit")
	for expected_delay in [[100, 1.0], [75, 2.0], [50, 3.0], [25, 4.0], [0, 5.0]]:
		saykwastes.bravery = expected_delay[0]
		assert(is_equal_approx(saykwastes.get_bravery_attack_delay(), expected_delay[1]), "bravery must map to the expected attack interval")
	saykwastes.fear = 0
	assert(is_inf(saykwastes.get_roaming_radius()), "zero fear must have no roaming limit")
	for expected_radius in [[10, 2000.0], [20, 1900.0], [30, 1800.0], [100, 1100.0]]:
		saykwastes.fear = expected_radius[0]
		assert(is_equal_approx(saykwastes.get_roaming_radius(), expected_radius[1]), "fear must map to the expected roaming radius")
	get_tree().quit(0)
