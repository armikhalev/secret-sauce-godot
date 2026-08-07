extends CharacterBody2D

@export var chase_speed := 235.0
@export var damage := 1
@export var damage_distance := 34.0
@export var damage_interval := 1.0

var player: CharacterBody2D
var mouth: Node2D
var damage_cooldown := 0.0


func _ready() -> void:
	add_to_group("giant_wo_lew")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	mouth = get_tree().get_first_node_in_group("giant_wo_mouth") as Node2D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		return
	if is_instance_valid(mouth) and mouth.has_method("contains_lew") and mouth.contains_lew(self):
		mouth.consume_lew(self)
		return
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player <= damage_distance and damage_cooldown <= 0.0:
		player.change_vitality(damage, false)
		damage_cooldown = damage_interval
	velocity = global_position.direction_to(player.global_position) * chase_speed
	move_and_slide()
	if not velocity.is_zero_approx():
		rotation = velocity.angle() + PI / 2.0
