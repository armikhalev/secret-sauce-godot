class_name Grass
extends Area2D

@export var state: GrassData.State = GrassData.State.PLAIN


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_appearance()


func set_state(new_state: GrassData.State) -> void:
	state = new_state
	_update_appearance()


func get_item_data() -> GrassData:
	var item := GrassData.new()
	item.state = state
	return item


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_grass"):
		body.collect_grass(get_item_data())
		queue_free()


func _update_appearance() -> void:
	if not is_node_ready():
		return

	var body := get_node("Body") as Polygon2D
	match state:
		GrassData.State.POISONOUS:
			body.color = Color(0.55, 0.25, 0.68, 1.0)
		GrassData.State.TASTY:
			body.color = Color(0.45, 0.82, 0.28, 1.0)
		_:
			body.color = Color(0.25, 0.65, 0.24, 1.0)
