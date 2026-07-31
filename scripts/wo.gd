extends CharacterBody2D

@export_group("Identity")
@export_multiline var creature_note := "A small, rabbit-like creature."
@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 1
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


func _ready() -> void:
	add_to_group("wo")
	random.randomize()
	rest_time_remaining = random.randf_range(0.1, rest_duration)
	_update_debug_stats()


func _physics_process(delta: float) -> void:
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
	if lew.state == LewData.State.POISONOUS:
		vitality = clampi(vitality - 25, 0, 100)
	elif lew.state == LewData.State.TASTY and is_instance_valid(lew.offered_by):
		trust = clampi(trust + 25, 0, 100)

	_update_debug_stats()
	lew.queue_free()


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
		"BRV %d  VIT %d  HNG %d\nAGR %d  TRS %d  FER %d"
		% [bravery, vitality, hunger, aggression, trust, fear]
	)
