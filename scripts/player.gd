extends CharacterBody2D

@export var move_speed: float = 260.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed

	if direction != Vector2.ZERO:
		rotation = direction.angle() + PI / 2.0

	move_and_slide()
