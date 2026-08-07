extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var wo := (load("res://scenes/wo.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(wo)
	await get_tree().process_frame
	wo.receive_circle_hit(player, 100)
	var bubbles := get_tree().get_nodes_in_group("wo_death_bubble")
	assert(bubbles.size() == 1, "a dead wo must create one moxoy bubble")
	var bubble := bubbles[0] as PanelContainer
	assert((bubble.get_child(0) as Label).text == "moxoy")
	var initial_y := bubble.global_position.y
	await get_tree().create_timer(0.8).timeout
	assert(bubble.global_position.y < initial_y, "the moxoy bubble must float upward")
	await get_tree().create_timer(0.9).timeout
	assert(get_tree().get_nodes_in_group("wo_death_bubble").is_empty(), "the moxoy bubble must fade and remove itself")
	get_tree().quit(0)
