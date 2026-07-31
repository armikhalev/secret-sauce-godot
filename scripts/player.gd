extends CharacterBody2D

signal stats_changed(bravery: int, vitality: int, energy: int)
signal lew_inventory_changed

@export var move_speed: float = 260.0
@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var energy: int = 100

var lew_inventory: Array[LewData] = []
var concealment_sources := 0
var is_hidden := false


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed

	if direction != Vector2.ZERO:
		rotation = direction.angle() + PI / 2.0

	var intended_motion := velocity * delta
	move_and_slide()

	for collision_index in get_slide_collision_count():
		var collider := get_slide_collision(collision_index).get_collider()
		if collider.has_method("receive_push"):
			collider.receive_push(intended_motion)


func change_bravery(amount: int, direction: bool) -> void:
	bravery = clampi(bravery + amount, 0, 100) if direction else clampi(bravery - amount, 0, 100)
	stats_changed.emit(bravery, vitality, energy)


func change_vitality(amount: int, direction: bool) -> void:
	vitality = clampi(vitality + amount, 0, 100) if direction else clampi(vitality - amount, 0, 100)
	stats_changed.emit(bravery, vitality, energy)


func change_energy(amount: int, direction: bool) -> void:
	energy = clampi(energy + amount, 0, 100) if direction else clampi(energy - amount, 0, 100)
	stats_changed.emit(bravery, vitality, energy)


func collect_lew(item: LewData) -> void:
	lew_inventory.append(item)
	lew_inventory_changed.emit()


func set_lew_state(inventory_index: int, state: LewData.State) -> bool:
	if inventory_index < 0 or inventory_index >= lew_inventory.size():
		return false

	lew_inventory[inventory_index].state = state
	lew_inventory_changed.emit()
	return true


func drop_lew(inventory_index: int, drop_position: Vector2) -> Lew:
	if inventory_index < 0 or inventory_index >= lew_inventory.size():
		return null

	var item: LewData = lew_inventory.pop_at(inventory_index)
	lew_inventory_changed.emit()
	var lew := preload("res://scenes/lew.tscn").instantiate() as Lew
	lew.state = item.state
	lew.offered_by = self
	lew.global_position = drop_position
	get_tree().current_scene.add_child(lew)
	lew.offer_to_npcs()
	return lew


func enter_concealment() -> void:
	concealment_sources += 1
	is_hidden = true
	$Body.modulate.a = 0.45
	$FacingMarker.modulate.a = 0.45


func exit_concealment() -> void:
	concealment_sources = maxi(concealment_sources - 1, 0)
	is_hidden = concealment_sources > 0
	if not is_hidden:
		$Body.modulate.a = 1.0
		$FacingMarker.modulate.a = 1.0
