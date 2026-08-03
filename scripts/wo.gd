extends CharacterBody2D

signal killed_by_player(respawn_position: Vector2)

@export_group("Identity")
@export_multiline var creature_note := "A small, rabbit-like creature."
@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var hunger: int = 100
@export_range(0, 100) var aggression: int = 0
@export_range(0, 100) var trust: int = 0
@export_range(0, 100) var fear: int = 100
@export_group("Hopping")
@export var hop_speed: float = 105.0
@export var hop_duration: float = 0.24
@export var rest_duration: float = 0.65
@export var lew_notice_radius: float = 420.0
@export var eating_distance: float = 60.0

var target_lew: Lew
var hop_time_remaining := 0.0
var rest_time_remaining := 0.0
var hop_direction := Vector2.ZERO
var random := RandomNumberGenerator.new()
var hunger_second_elapsed := 0.0
var vitality_tick_elapsed := 0.0
var is_dead := false


func _ready() -> void:
	add_to_group("wo")
	random.randomize()
	rest_time_remaining = random.randf_range(0.1, rest_duration)
	_update_debug_stats()


func _physics_process(delta: float) -> void:
	_process_metabolism(delta)
	if is_dead:
		return

	if hunger <= 0:
		velocity = Vector2.ZERO
		return

	if not is_instance_valid(target_lew):
		target_lew = _find_closest_lew()

	if is_instance_valid(target_lew):
		if global_position.distance_to(target_lew.global_position) <= eating_distance:
			eat_lew(target_lew)
			target_lew = null
			velocity = Vector2.ZERO
			return

	if hop_time_remaining > 0.0:
		hop_time_remaining = maxf(hop_time_remaining - delta, 0.0)
		velocity = hop_direction * hop_speed
		move_and_slide()
		return

	velocity = Vector2.ZERO
	rest_time_remaining = maxf(rest_time_remaining - delta, 0.0)
	if rest_time_remaining <= 0.0:
		_start_hop()


func eat_lew(lew: Lew) -> void:
	hunger = clampi(hunger - 25, 0, 100)
	vitality = 100
	vitality_tick_elapsed = 0.0
	if lew.state == LewData.State.POISONOUS:
		vitality = clampi(vitality - 25, 0, 100)
	elif lew.state == LewData.State.TASTY and is_instance_valid(lew.offered_by):
		trust = clampi(trust + 25, 0, 100)

	_update_debug_stats()
	lew.remove_from_world()


func _process_metabolism(delta: float) -> void:
	hunger_second_elapsed += delta
	while hunger_second_elapsed >= 1.0:
		hunger_second_elapsed -= 1.0
		_apply_hunger_second()

	var vitality_interval := _get_vitality_tick_interval()
	if is_inf(vitality_interval):
		vitality_tick_elapsed = 0.0
		return

	vitality_tick_elapsed += delta
	while vitality_tick_elapsed >= vitality_interval:
		vitality_tick_elapsed -= vitality_interval
		_apply_vitality_tick()
		if is_dead:
			return


func _apply_hunger_second() -> void:
	if is_dead:
		return
	hunger = clampi(hunger + 1, 0, 100)
	_update_debug_stats()


func _apply_vitality_tick() -> void:
	if is_dead:
		return
	vitality = clampi(vitality - 1, 0, 100)
	_update_debug_stats()
	if vitality <= 0:
		_die(false)


func _get_vitality_tick_interval() -> float:
	if hunger >= 100:
		return 1.0
	if hunger >= 75:
		return 2.0
	if hunger >= 50:
		return 3.0
	if hunger >= 25:
		return 4.0
	return INF


func _die(was_killed_by_player: bool) -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	remove_from_group("wo")
	if was_killed_by_player:
		killed_by_player.emit(global_position)
	queue_free()


func receive_attack(damage: int) -> void:
	if is_dead:
		return
	vitality = clampi(vitality - damage, 0, 100)
	_update_debug_stats()
	if vitality <= 0:
		_die(true)


func receive_stick_hit(_attacker: Node, damage: int) -> void:
	receive_attack(damage)


func _start_hop() -> void:
	if is_instance_valid(target_lew):
		hop_direction = global_position.direction_to(target_lew.global_position)
	else:
		hop_direction = Vector2.RIGHT.rotated(random.randf_range(0.0, TAU))

	hop_time_remaining = hop_duration
	rest_time_remaining = rest_duration


func _find_closest_lew() -> Lew:
	var closest: Lew
	var closest_distance_squared := lew_notice_radius * lew_notice_radius

	for node in get_tree().get_nodes_in_group("lew"):
		if not node is Lew:
			continue

		var lew := node as Lew
		var distance_squared := global_position.distance_squared_to(lew.global_position)
		if distance_squared <= closest_distance_squared:
			closest = lew
			closest_distance_squared = distance_squared

	return closest


func _update_debug_stats() -> void:
	$DebugStats.text = (
		"peysmafu %d  moysew %d\nmamew %d  datmuy %d\nsagawtaw %d  mafu %d"
		% [bravery, vitality, hunger, aggression, trust, fear]
	)
