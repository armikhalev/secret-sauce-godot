extends Node


func _ready() -> void:
	var scene3 := (load("res://scenes/scene-3.tscn") as PackedScene).instantiate()
	add_child(scene3)
	await get_tree().process_frame
	var to_scene2 := scene3.get_node("DoorToScene2")
	var to_scene1 := scene3.get_node("DoorToScene1")
	assert(to_scene2.position == Vector2(-540, 0), "the scene-2 door must be on scene 3's left side")
	assert(to_scene1.position == Vector2(540, 0), "the scene-1 door must be on the opposite side")
	assert(to_scene2.destination_scene == "res://scenes/scene-2.tscn")
	assert(to_scene2.arrival_position == Vector2(460, 0), "returning must place the player beside scene 2's scene-3 door")
	assert(to_scene1.destination_scene == "res://scenes/game.tscn")
	assert(to_scene1.arrival_position == Vector2(1360, 0), "scene 1 arrival must be beside its scene-2 exit")

	var scene2 := (load("res://scenes/scene-2.tscn") as PackedScene).instantiate()
	add_child(scene2)
	await get_tree().process_frame
	var to_scene3 := scene2.get_node("DoorToScene3")
	assert(to_scene3.arrival_position == Vector2(-460, 0), "entering scene 3 must place the player beside its scene-2 door")
	get_tree().quit(0)
