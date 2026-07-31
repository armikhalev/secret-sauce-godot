extends CharacterBody2D

@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var hunger: int = 0
@export_range(0, 1000) var aggression: int = 560
@export_range(0, 100) var trust: int = 0
@export_range(0, 100) var fear: int = 0
@export_group("Movement")
@export var approach_speed: float = 65.0
@export var eating_distance: float = 62.0
@export var lew_notice_radius: float = 560.0
@export_group("Combat")
@export var attack_speed: float = 110.0
@export var retreat_speed: float = 95.0
@export var attack_distance: float = 82.0
@export var attack_damage: int = 25
@export var retreat_duration: float = 1.0
@export_group("Poison")
@export var poison_tick_damage: int = 5

var target_lew: Lew
var is_poisoned := false
var is_dead := false
var retreat_time_remaining := 0.0


func _ready() -> void:
	$PoisonTimer.timeout.connect(_on_poison_tick)
	_update_debug_stats()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	if not is_instance_valid(target_lew):
		target_lew = _find_closest_offered_lew()

	if not is_instance_valid(target_lew):
		if _process_player_attack(delta):
			return
		velocity = Vector2.ZERO
		return

	var distance_to_lew := global_position.distance_to(target_lew.global_position)
	if distance_to_lew <= eating_distance:
		velocity = Vector2.ZERO
		eat_lew(target_lew)
		target_lew = null
		return

	velocity = global_position.direction_to(target_lew.global_position) * approach_speed
	move_and_slide()


func _process_player_attack(delta: float) -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		retreat_time_remaining = 0.0
		return false

	var player := players[0] as CharacterBody2D
	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player > float(aggression):
		retreat_time_remaining = 0.0
		return false

	if retreat_time_remaining > 0.0:
		retreat_time_remaining = maxf(retreat_time_remaining - delta, 0.0)
		velocity = player.global_position.direction_to(global_position) * retreat_speed
		move_and_slide()
		return true

	if distance_to_player <= attack_distance:
		player.change_vitality(attack_damage, false)
		retreat_time_remaining = retreat_duration
		velocity = player.global_position.direction_to(global_position) * retreat_speed
	else:
		velocity = global_position.direction_to(player.global_position) * attack_speed

	move_and_slide()
	return true


func eat_lew(lew: Lew) -> void:
	match lew.state:
		LewData.State.POISONOUS:
			vitality = clampi(vitality - 25, 0, 100)
			_start_poisoning()
		LewData.State.TASTY:
			trust = clampi(trust + 25, 0, 100)

	if vitality <= 0:
		_die()

	_update_debug_stats()
	lew.queue_free()


func receive_push(push_motion: Vector2) -> void:
	if is_dead:
		global_position += push_motion


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
	target_lew = null
	velocity = Vector2.ZERO
	$PoisonTimer.stop()
	$Body.color = Color(0.09, 0.1, 0.11, 1.0)
	$Label.text = "moxoy"
	_update_debug_stats()


func _find_closest_offered_lew() -> Lew:
	var closest: Lew
	var closest_distance_squared := lew_notice_radius * lew_notice_radius

	for node in get_tree().get_nodes_in_group("npc_food"):
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
		"BRV %d  VIT %d  HNG %d\nAGR %d  TRS %d  FER %d"
		% [bravery, vitality, hunger, aggression, trust, fear]
	)
