extends Area2D

@export var concealment_radius: float = 450.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_concealment"):
		body.enter_concealment()


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_concealment"):
		body.exit_concealment()
