extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	add_child(player)
	await get_tree().process_frame
	player.change_vitality(25, false)
	var bubbles := get_tree().get_nodes_in_group("stat_loss_bubble")
	assert(bubbles.size() == 1, "losing a stat must create one feedback bubble")
	var bubble := bubbles[0] as PanelContainer
	var message := bubble.get_child(0) as Label
	assert(message.text == "-25 moy", "the bubble must show the actual loss and full Mela stat name")
	var initial_y := bubble.global_position.y
	await get_tree().create_timer(0.8).timeout
	assert(bubble.global_position.y < initial_y, "the stat-loss bubble must float upward")
	await get_tree().create_timer(0.9).timeout
	assert(get_tree().get_nodes_in_group("stat_loss_bubble").is_empty(), "the stat-loss bubble must fade and remove itself")
	get_tree().quit(0)
