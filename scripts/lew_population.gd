extends Node

@export var item_container_path: NodePath
@export var spawn_points_path: NodePath
@export var population_limit: int = 4
@export var spawn_interval: float = 30.0

var spawn_timer: Timer


func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_initialize_population")


func _initialize_population() -> void:
	for lew in _get_area_lew():
		_connect_lew(lew)
	_update_timer()


func _on_node_added(node: Node) -> void:
	if node is Lew and _belongs_to_this_area(node as Lew):
		_connect_lew(node as Lew)


func _connect_lew(lew: Lew) -> void:
	if not lew.removed.is_connected(_on_lew_removed):
		lew.removed.connect(_on_lew_removed)


func _on_lew_removed() -> void:
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	_spawn_first_empty_slot()
	_update_timer()


func _spawn_first_empty_slot() -> void:
	var item_container := get_node_or_null(item_container_path) as Node2D
	var spawn_points := get_node_or_null(spawn_points_path)
	if item_container == null or spawn_points == null:
		return

	var occupied_slots: Dictionary[int, bool] = {}
	for lew in _get_area_lew():
		if lew.spawn_slot_id >= 0:
			occupied_slots[lew.spawn_slot_id] = true

	var available_slots := mini(population_limit, spawn_points.get_child_count())
	for slot_id in available_slots:
		if occupied_slots.has(slot_id):
			continue

		var marker := spawn_points.get_child(slot_id) as Node2D
		var lew := (preload("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
		lew.spawn_slot_id = slot_id
		lew.position = item_container.to_local(marker.global_position)
		item_container.add_child(lew)
		return


func _update_timer() -> void:
	if _get_area_lew().size() >= population_limit:
		spawn_timer.stop()
	elif spawn_timer.is_stopped():
		spawn_timer.start()


func _get_area_lew() -> Array[Lew]:
	var result: Array[Lew] = []
	var container := get_node_or_null(item_container_path)
	if container == null:
		return result

	for child in container.get_children():
		if child is Lew:
			result.append(child as Lew)
	return result


func _belongs_to_this_area(lew: Lew) -> bool:
	var container := get_node_or_null(item_container_path)
	return container != null and lew.get_parent() == container
