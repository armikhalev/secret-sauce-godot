extends Node

@export var npc_container_path: NodePath
@export var living_saykwastes_limit: int = 2
@export var dead_saykwastes_limit: int = 10
@export var spawn_interval: float = 5.0
@export var killed_respawn_delay: float = 15.0
@export var spawn_radius: float = 620.0

var spawn_timer: Timer
var random := RandomNumberGenerator.new()
var saykwastes_was_alive := false
var post_death_spawns_remaining := 0


func _ready() -> void:
	random.randomize()
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	_update_population_state()


func _process(_delta: float) -> void:
	_register_wo_signals()
	_update_population_state()


func _register_wo_signals() -> void:
	for node in get_tree().get_nodes_in_group("wo"):
		if not node.killed_by_player.is_connected(_on_wo_killed_by_player):
			node.killed_by_player.connect(_on_wo_killed_by_player)


func _on_wo_killed_by_player(respawn_position: Vector2) -> void:
	_respawn_killed_wo(respawn_position)


func _respawn_killed_wo(respawn_position: Vector2) -> void:
	await get_tree().create_timer(killed_respawn_delay).timeout
	var population_limit := living_saykwastes_limit if _has_living_saykwastes() else dead_saykwastes_limit
	if _count_wo() < population_limit:
		_spawn_wo(respawn_position)


func _update_population_state() -> void:
	if _has_living_saykwastes():
		saykwastes_was_alive = true
		post_death_spawns_remaining = 0
		if not spawn_timer.is_stopped():
			spawn_timer.stop()
		_enforce_population_limit(living_saykwastes_limit)
	else:
		_enforce_population_limit(dead_saykwastes_limit)
		if saykwastes_was_alive:
			saykwastes_was_alive = false
			post_death_spawns_remaining = maxi(dead_saykwastes_limit - _count_wo(), 0)
		if post_death_spawns_remaining > 0 and spawn_timer.is_stopped():
			spawn_timer.start()


func _enforce_population_limit(population_limit: int) -> void:
	if get_node_or_null(npc_container_path) == null:
		return

	var wo_nodes := get_tree().get_nodes_in_group("wo")
	while wo_nodes.size() > population_limit:
		var extra_wo := wo_nodes.pop_back() as Node
		extra_wo.queue_free()


func _on_spawn_timer_timeout() -> void:
	if _has_living_saykwastes():
		spawn_timer.stop()
		return

	if post_death_spawns_remaining > 0:
		if _count_wo() < dead_saykwastes_limit:
			_spawn_wo()
		post_death_spawns_remaining -= 1

	if post_death_spawns_remaining <= 0:
		spawn_timer.stop()


func _spawn_wo(respawn_position := Vector2(INF, INF)) -> void:
	var container := get_node_or_null(npc_container_path)
	if container == null:
		return
	var wo := (preload("res://scenes/wo.tscn") as PackedScene).instantiate()
	container.add_child(wo)
	if is_finite(respawn_position.x) and is_finite(respawn_position.y):
		wo.global_position = respawn_position
	else:
		var angle := random.randf_range(0.0, TAU)
		var distance := random.randf_range(spawn_radius * 0.45, spawn_radius)
		wo.position = Vector2.RIGHT.rotated(angle) * distance


func _has_living_saykwastes() -> bool:
	for npc in get_tree().get_nodes_in_group("saykwastes"):
		if not npc.is_dead:
			return true
	return false


func _count_wo() -> int:
	return get_tree().get_nodes_in_group("wo").size()
