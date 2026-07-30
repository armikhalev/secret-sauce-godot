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

var target_grass: Grass


func _ready() -> void:
	_update_debug_stats()


func _physics_process(_delta: float) -> void:
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
		GrassData.State.TASTY:
			trust = clampi(trust + 25, 0, 100)

	_update_debug_stats()
	grass.queue_free()


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
