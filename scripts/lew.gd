class_name Lew
extends Area2D

@export var state: LewData.State = LewData.State.PLAIN
var offered_to_npcs := false
var offered_by: Node


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_appearance()


func set_state(new_state: LewData.State) -> void:
	state = new_state
	_update_appearance()


func get_item_data() -> LewData:
	var item := LewData.new()
	item.state = state
	return item


func offer_to_npcs() -> void:
	offered_to_npcs = true
	add_to_group("npc_food")


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_lew"):
		body.collect_lew(get_item_data())
		queue_free()


func _update_appearance() -> void:
	if not is_node_ready():
		return

	var body := get_node("Body") as Polygon2D
	match state:
		LewData.State.POISONOUS:
			body.color = Color(0.55, 0.25, 0.68, 1.0)
		LewData.State.TASTY:
			body.color = Color(0.45, 0.82, 0.28, 1.0)
		_:
			body.color = Color(0.25, 0.65, 0.24, 1.0)
