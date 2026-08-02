extends CharacterBody2D

signal stats_changed(bravery: int, vitality: int, energy: int, awareness: int)
signal lew_inventory_changed
signal perception_mode_changed(is_expanded: bool)

@export var move_speed: float = 260.0
@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var energy: int = 100
@export_range(0, 100) var awareness: int = 50
@export_group("Camera")
@export var zoom_speed: float = 1.1
@export var zoom_step: float = 0.1
@export var default_camera_zoom: float = 2.0
@export_group("Attack")
@export var attack_range: float = 96.0
@export var attack_damage: int = 20
@export var attack_swing_duration: float = 0.24

var lew_inventory: Array[LewData] = []
var concealment_sources := 0
var is_hidden := false
var is_expanded_perception := false
var is_dead := false
var is_attacking := false


func _ready() -> void:
	add_to_group("player")
	$Camera2D.zoom = Vector2.ONE * default_camera_zoom


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

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


func _process(delta: float) -> void:
	if is_dead:
		return

	var zoom_input := Input.get_axis("zoom_out", "zoom_in")
	if is_zero_approx(zoom_input):
		return

	_change_camera_zoom(zoom_input * zoom_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("attack"):
		_attack_with_stick()
		get_viewport().set_input_as_handled()
		return

	if not event is InputEventMouseButton and not event is InputEventKey:
		return
	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("zoom_in"):
		_change_camera_zoom(zoom_step)
	elif event.is_action_pressed("zoom_out"):
		_change_camera_zoom(-zoom_step)


func _attack_with_stick() -> void:
	if is_attacking:
		return

	is_attacking = true
	var target := _find_nearest_wo()
	if is_instance_valid(target):
		rotation = global_position.direction_to(target.global_position).angle() + PI / 2.0

	var attack_pivot := $AttackPivot as Node2D
	attack_pivot.rotation = -1.15
	attack_pivot.show()
	var tween := create_tween()
	tween.tween_property(attack_pivot, "rotation", 1.15, attack_swing_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(attack_swing_duration * 0.5).timeout
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		target.receive_attack(attack_damage)
	await tween.finished
	attack_pivot.hide()
	is_attacking = false


func _find_nearest_wo() -> CharacterBody2D:
	var nearest: CharacterBody2D
	var nearest_distance := attack_range
	for node in get_tree().get_nodes_in_group("wo"):
		if not node is CharacterBody2D:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	return nearest


func _change_camera_zoom(amount: float) -> void:
	var camera := $Camera2D as Camera2D
	var zoom_value := camera.zoom.x + amount
	zoom_value = clampf(zoom_value, get_minimum_camera_zoom(), default_camera_zoom)
	camera.zoom = Vector2.ONE * zoom_value
	_update_perception_mode()


func get_minimum_camera_zoom() -> float:
	return lerpf(default_camera_zoom, 0.5, float(awareness) / 100.0)


func change_bravery(amount: int, direction: bool) -> void:
	bravery = clampi(bravery + amount, 0, 100) if direction else clampi(bravery - amount, 0, 100)
	stats_changed.emit(bravery, vitality, energy, awareness)


func change_vitality(amount: int, direction: bool) -> void:
	if is_dead:
		return
	vitality = clampi(vitality + amount, 0, 100) if direction else clampi(vitality - amount, 0, 100)
	stats_changed.emit(bravery, vitality, energy, awareness)
	if vitality <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	set_process_unhandled_input(false)
	$DeathOverlay.show()
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


func change_energy(amount: int, direction: bool) -> void:
	energy = clampi(energy + amount, 0, 100) if direction else clampi(energy - amount, 0, 100)
	stats_changed.emit(bravery, vitality, energy, awareness)


func change_awareness(amount: int, direction: bool) -> void:
	awareness = clampi(awareness + amount, 0, 100) if direction else clampi(awareness - amount, 0, 100)
	var camera := $Camera2D as Camera2D
	var clamped_zoom := maxf(camera.zoom.x, get_minimum_camera_zoom())
	camera.zoom = Vector2.ONE * clamped_zoom
	_update_perception_mode()
	stats_changed.emit(bravery, vitality, energy, awareness)


func _update_perception_mode() -> void:
	var camera := $Camera2D as Camera2D
	var expanded := camera.zoom.x < default_camera_zoom - 0.001
	if expanded == is_expanded_perception:
		return
	is_expanded_perception = expanded
	perception_mode_changed.emit(is_expanded_perception)


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
