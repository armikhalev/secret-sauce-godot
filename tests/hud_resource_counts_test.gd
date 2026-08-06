extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var interface := (load("res://scenes/player_interface.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(interface)
	await get_tree().process_frame
	var title := interface.get_node("MarginContainer/Title") as Label
	assert("lew 0" in title.text and "wo 0" in title.text, "HUD must initially show both resource counts")
	player.collect_lew(LewData.new())
	player.collect_wo()
	player.collect_wo()
	assert("lew 1" in title.text, "HUD must refresh the lew count")
	assert("wo 2" in title.text, "HUD must refresh the wo count")
	get_tree().quit(0)
