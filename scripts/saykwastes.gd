extends CharacterBody2D

@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var hunger: int = 0
@export_range(0, 100) var aggression: int = 50
@export_range(0, 1000) var trust: int = 0
@export_range(0, 100) var fear: int = 0
@export_group("Movement")
@export var approach_speed: float = 65.0
@export var eating_distance: float = 62.0
@export var lew_notice_radius: float = 560.0
@export var aggression_radius: float = 560.0
@export_group("Combat")
@export var attack_speed: float = 110.0
@export var retreat_speed: float = 95.0
@export var attack_distance: float = 82.0
@export var attack_damage: int = 25
@export var retreat_duration: float = 1.0
@export var maximum_attack_delay: float = 6.0
@export_group("Poison")
@export var poison_tick_damage: int = 5

var target_lew: Lew
var is_poisoned := false
var is_dead := false
var retreat_time_remaining := 0.0
var attack_cooldown_remaining := 0.0
var trust_by_target: Dictionary[int, int] = {}
var aggression_by_target: Dictionary[int, int] = {}


func _ready() -> void:
	add_to_group("saykwastes")
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
	_ensure_relationship(player)
	var player_trust := get_trust_toward(player)
	var player_aggression := get_aggression_toward(player)
	trust = player_trust
	aggression = player_aggression
	_update_debug_stats()

	if player_trust > player_aggression:
		retreat_time_remaining = 0.0
		attack_cooldown_remaining = 0.0
		return false

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player > aggression_radius:
		retreat_time_remaining = 0.0
		attack_cooldown_remaining = 0.0
		return false

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)

	if retreat_time_remaining > 0.0:
		retreat_time_remaining = maxf(retreat_time_remaining - delta, 0.0)
		velocity = player.global_position.direction_to(global_position) * retreat_speed
		move_and_slide()
		return true

	if attack_cooldown_remaining > 0.0:
		velocity = Vector2.ZERO
		return true

	if distance_to_player <= attack_distance:
		player.change_vitality(attack_damage, false)
		retreat_time_remaining = retreat_duration
		var trust_ratio := clampf(float(player_trust) / float(player_aggression), 0.0, 1.0)
		attack_cooldown_remaining = lerpf(retreat_duration, maximum_attack_delay, trust_ratio)
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
			if is_instance_valid(lew.offered_by):
				change_trust_toward(lew.offered_by, 25)
			else:
				trust = clampi(trust + 25, 0, 1000)

	if vitality <= 0:
		_die()

	_update_debug_stats()
	lew.queue_free()


func get_trust_toward(target: Node) -> int:
	_ensure_relationship(target)
	return trust_by_target[target.get_instance_id()]


func get_aggression_toward(target: Node) -> int:
	_ensure_relationship(target)
	return aggression_by_target[target.get_instance_id()]


func change_trust_toward(target: Node, amount: int) -> void:
	_ensure_relationship(target)
	var target_id := target.get_instance_id()
	trust_by_target[target_id] = maxi(trust_by_target[target_id] + amount, 0)
	if target.is_in_group("player"):
		trust = trust_by_target[target_id]
		_update_debug_stats()


func set_aggression_toward(target: Node, amount: int) -> void:
	_ensure_relationship(target)
	var target_id := target.get_instance_id()
	aggression_by_target[target_id] = maxi(amount, 0)
	if target.is_in_group("player"):
		aggression = aggression_by_target[target_id]
		_update_debug_stats()


func _ensure_relationship(target: Node) -> void:
	var target_id := target.get_instance_id()
	if not trust_by_target.has(target_id):
		trust_by_target[target_id] = trust if target.is_in_group("player") else 0
	if not aggression_by_target.has(target_id):
		aggression_by_target[target_id] = aggression if target.is_in_group("player") else 0


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
		"BRV %d  VIT %d  HNG %d\nAGR %d  TRS %d  FER %d  RAD %d"
		% [bravery, vitality, hunger, aggression, trust, fear, roundi(aggression_radius)]
	)
