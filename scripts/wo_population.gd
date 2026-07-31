extends Node

@export var npc_container_path: NodePath
@export var living_saykwastes_limit: int = 2
@export var dead_saykwastes_limit: int = 10
@export var spawn_interval: float = 5.0
@export var spawn_radius: float = 620.0

var spawn_timer: Timer
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	_update_population_state()


func _process(_delta: float) -> void:
	_update_population_state()


func _update_population_state() -> void:
	if _has_living_saykwastes():
		if not spawn_timer.is_stopped():
			spawn_timer.stop()
		_enforce_living_limit()
	elif _count_wo() < dead_saykwastes_limit and spawn_timer.is_stopped():
		spawn_timer.start()


func _enforce_living_limit() -> void:
	if get_node_or_null(npc_container_path) == null:
		return

	var wo_nodes := get_tree().get_nodes_in_group("wo")
	while wo_nodes.size() < living_saykwastes_limit:
		_spawn_wo()
		wo_nodes = get_tree().get_nodes_in_group("wo")

	while wo_nodes.size() > living_saykwastes_limit:
		var extra_wo := wo_nodes.pop_back() as Node
		extra_wo.queue_free()


func _on_spawn_timer_timeout() -> void:
	if _has_living_saykwastes():
		spawn_timer.stop()
		return

	if _count_wo() < dead_saykwastes_limit:
		_spawn_wo()

	if _count_wo() >= dead_saykwastes_limit:
		spawn_timer.stop()


func _spawn_wo() -> void:
	var container := get_node_or_null(npc_container_path)
	if container == null:
		return
	var wo := (preload("res://scenes/wo.tscn") as PackedScene).instantiate()
	var angle := random.randf_range(0.0, TAU)
	var distance := random.randf_range(spawn_radius * 0.45, spawn_radius)
	wo.position = Vector2.RIGHT.rotated(angle) * distance
	container.add_child(wo)


func _has_living_saykwastes() -> bool:
	for npc in get_tree().get_nodes_in_group("saykwastes"):
		if not npc.is_dead:
			return true
	return false


func _count_wo() -> int:
	return get_tree().get_nodes_in_group("wo").size()
