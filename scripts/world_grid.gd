extends Node2D

@export var world_size := Vector2(3200.0, 2000.0)
@export var cell_size := 64.0
@export var line_color := Color(0.24, 0.38, 0.31, 0.65)


func _draw() -> void:
	var half_size := world_size / 2.0

	var x := -half_size.x
	while x <= half_size.x:
		draw_line(Vector2(x, -half_size.y), Vector2(x, half_size.y), line_color, 2.0)
		x += cell_size

	var y := -half_size.y
	while y <= half_size.y:
		draw_line(Vector2(-half_size.x, y), Vector2(half_size.x, y), line_color, 2.0)
		y += cell_size
