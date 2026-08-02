class_name SceneExit
extends Area2D

@export_file("*.tscn", "*.scn") var destination_scene: String
var is_transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if is_transitioning or not body.is_in_group("player"):
		return
	if destination_scene.is_empty():
		return
	is_transitioning = true
	get_tree().change_scene_to_file(destination_scene)
