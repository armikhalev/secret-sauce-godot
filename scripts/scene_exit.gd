class_name SceneExit
extends Area2D

@export_file("*.tscn", "*.scn") var destination_scene: String
@export var enabled_on_start := true
@export_group("Arrival")
@export var override_arrival_position := false
@export var arrival_position := Vector2.ZERO
var is_transitioning := false


func _ready() -> void:
	add_to_group("scene_exit")
	body_entered.connect(_on_body_entered)
	set_exit_enabled(enabled_on_start)


func set_exit_enabled(enabled: bool) -> void:
	visible = enabled
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)


func _on_body_entered(body: Node2D) -> void:
	if is_transitioning or not body.is_in_group("player"):
		return
	if destination_scene.is_empty():
		return
	is_transitioning = true
	GameState.capture_player_inventory(body)
	if override_arrival_position:
		GameState.set_arrival_position(arrival_position)
	get_tree().change_scene_to_file(destination_scene)
