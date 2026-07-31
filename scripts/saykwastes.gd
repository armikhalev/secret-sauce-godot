extends CharacterBody2D

@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var hunger: int = 0
@export_range(0, 100) var aggression: int = 0
@export_range(0, 100) var trust: int = 0
@export_range(0, 100) var fear: int = 0
@export_group("Movement")
@export var approach_speed: float = 65.0
@export var eating_distance: float = 42.0
@export_group("Poison")
@export var poison_tick_damage: int = 5

var target_grass: Grass
var is_poisoned := false
var is_dead := false


func _ready() -> void:
	$PoisonTimer.timeout.connect(_on_poison_tick)
	_update_debug_stats()


func _physics_process(_delta: float) -> void:
	if is_dead:
		move_and_slide()
		velocity = Vector2.ZERO
		return

	if not is_instance_valid(target_grass):
		target_grass = _find_closest_offered_grass()

	if not is_instance_valid(target_grass):
		velocity = Vector2.ZERO
		return

	var distance_to_grass := global_position.distance_to(target_grass.global_position)
	if distance_to_grass <= eating_distance:
		velocity = Vector2.ZERO
		eat_grass(target_grass)
		target_grass = null
		return

	velocity = global_position.direction_to(target_grass.global_position) * approach_speed
	move_and_slide()


func eat_grass(grass: Grass) -> void:
	match grass.state:
		GrassData.State.POISONOUS:
			vitality = clampi(vitality - 25, 0, 100)
			_start_poisoning()
		GrassData.State.TASTY:
			trust = clampi(trust + 25, 0, 100)

	if vitality <= 0:
		_die()

	_update_debug_stats()
	grass.queue_free()


func receive_push(push_velocity: Vector2) -> void:
	if is_dead:
		velocity = push_velocity


func _start_poisoning() -> void:
	if is_dead:
		return

	is_poisoned = true
	if $PoisonTimer.is_stopped():
		$PoisonTimer.start()


func _on_poison_tick() -> void:
	if is_dead or not is_poisoned:
		return

	vitality = clampi(vitality - poison_tick_damage, 0, 100)
	_update_debug_stats()

	if vitality <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return

	is_dead = true
	is_poisoned = false
	target_grass = null
	velocity = Vector2.ZERO
	$PoisonTimer.stop()
	$Body.color = Color(0.09, 0.1, 0.11, 1.0)
	$Label.text = "moxoy"
	_update_debug_stats()


func _find_closest_offered_grass() -> Grass:
	var closest: Grass
	var closest_distance := INF

	for node in get_tree().get_nodes_in_group("npc_food"):
		if not node is Grass:
			continue

		var grass := node as Grass
		var distance := global_position.distance_squared_to(grass.global_position)
		if distance < closest_distance:
			closest = grass
			closest_distance = distance

	return closest


func _update_debug_stats() -> void:
	$DebugStats.text = (
		"BRV %d  VIT %d  HNG %d\nAGR %d  TRS %d  FER %d"
		% [bravery, vitality, hunger, aggression, trust, fear]
	)
