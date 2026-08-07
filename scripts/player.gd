extends CharacterBody2D

signal stats_changed(bravery: int, vitality: int, energy: int, awareness: int)
signal lew_inventory_changed
signal wo_inventory_changed
signal charms_changed
signal perception_mode_changed(is_expanded: bool)

const CIRCLE_HIT_CHARM := "circle-hit"
const MAGNET_BACK_CHARM := "magnet-back"

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
@export var attack_damage: int = 20
@export var attack_swing_duration: float = 0.24
@export var wall_rebound_speed: float = 720.0
@export var magnet_back_speed: float = 900.0
@export var magnet_search_distance: float = 4000.0
@export var charm_notches := 1

var lew_inventory: Array[LewData] = []
var wo_inventory := 0
var concealment_sources := 0
var is_hidden := false
var is_expanded_perception := false
var is_dead := false
var is_attacking := false
var attack_button_held := false
var circle_hit_unlocked := false
var owned_charms: Array[String] = []
var equipped_charms: Array[String] = []
var is_poisoned := false
var poison_stacks := 0
var is_rebounding := false
var rebound_direction := Vector2.ZERO
var is_magnetizing_back := false
var magnet_back_direction := Vector2.ZERO
var magnet_back_distance_left := 0.0
var bravery_by_npc_class: Dictionary = {
	"predator": 0,
	"herbivor": 0,
	"gopnik": 0,
}


func _ready() -> void:
	add_to_group("player")
	$Camera2D.zoom = Vector2.ONE * default_camera_zoom
	$PoisonTimer.timeout.connect(_on_poison_timer_timeout)
	GameState.restore_player_inventory(self)
	GameState.restore_player_position(self)
	owned_charms.assign(GameState.owned_charms)
	equipped_charms.assign(GameState.equipped_charms)
	# Migrate the old persistent ability flag into the charm system.
	var migrated_circle_hit := false
	if GameState.circle_hit_unlocked and not has_charm(CIRCLE_HIT_CHARM):
		owned_charms.append(CIRCLE_HIT_CHARM)
		migrated_circle_hit = true
	if migrated_circle_hit and equipped_charms.is_empty():
		equipped_charms.append(CIRCLE_HIT_CHARM)
	circle_hit_unlocked = has_charm(CIRCLE_HIT_CHARM)
	_save_charms()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	if is_magnetizing_back:
		var magnet_motion := magnet_back_direction * minf(magnet_back_speed * delta, magnet_back_distance_left)
		var magnet_collision := move_and_collide(magnet_motion)
		magnet_back_distance_left -= magnet_motion.length()
		if magnet_collision != null or magnet_back_distance_left <= 0.0:
			_stop_magnet_back()
		return
	if is_rebounding:
		velocity = rebound_direction * wall_rebound_speed
		var rebound_collision := move_and_collide(velocity * delta)
		if rebound_collision != null:
			is_rebounding = false
			rebound_direction = Vector2.ZERO
			velocity = Vector2.ZERO
			if attack_button_held:
				call_deferred("_attack_with_circle")
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
	if event.is_action_released("attack"):
		attack_button_held = false
		return
	if is_dead or is_rebounding or is_magnetizing_back:
		return
	if event.is_action_pressed("attack"):
		if not is_charm_equipped(CIRCLE_HIT_CHARM) and not is_charm_equipped(MAGNET_BACK_CHARM):
			return
		if is_charm_equipped(CIRCLE_HIT_CHARM):
			attack_button_held = true
			_attack_with_circle()
		else:
			_start_magnet_back()
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


func _attack_with_circle() -> void:
	if is_attacking or not is_charm_equipped(CIRCLE_HIT_CHARM):
		return

	is_attacking = true

	var attack_pivot := $AttackPivot as Node2D
	var attack_circle := $AttackPivot/Circle as Line2D
	attack_circle.scale = Vector2.ONE * 0.72
	attack_pivot.show()
	var tween := create_tween()
	tween.tween_property(attack_circle, "scale", Vector2.ONE, attack_swing_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(attack_swing_duration * 0.5).timeout
	var hit_targets := _find_attack_hitbox_targets()
	for hit_target in hit_targets:
		hit_target.receive_circle_hit(self, attack_damage)
	_try_start_wall_rebound()
	await tween.finished
	attack_pivot.hide()
	is_attacking = false
	if is_charm_equipped(MAGNET_BACK_CHARM):
		_start_magnet_back()
	if attack_button_held and not is_dead and not is_rebounding and not is_magnetizing_back:
		call_deferred("_attack_with_circle")


func _start_magnet_back() -> void:
	if is_dead or is_magnetizing_back or is_rebounding:
		return
	var backward := Vector2.DOWN.rotated(rotation).normalized()
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + backward * magnet_search_distance
	)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	magnet_back_direction = backward
	magnet_back_distance_left = global_position.distance_to(hit.position)
	is_magnetizing_back = true
	velocity = magnet_back_direction * magnet_back_speed


func _stop_magnet_back() -> void:
	is_magnetizing_back = false
	magnet_back_direction = Vector2.ZERO
	magnet_back_distance_left = 0.0
	velocity = Vector2.ZERO


func unlock_circle_hit() -> void:
	if not grant_charm(CIRCLE_HIT_CHARM):
		return
	if get_used_charm_notches() < charm_notches:
		equipped_charms.append(CIRCLE_HIT_CHARM)
		_save_charms()
		charms_changed.emit()
	var attack_pivot := $AttackPivot as Node2D
	var attack_circle := $AttackPivot/Circle as Line2D
	attack_circle.scale = Vector2.ONE * 0.72
	attack_pivot.show()
	var preview_tween := create_tween()
	preview_tween.tween_property(attack_circle, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	preview_tween.tween_interval(0.5)
	await preview_tween.finished
	if not is_attacking:
		attack_pivot.hide()


func grant_charm(charm_id: String) -> bool:
	if has_charm(charm_id):
		return false
	owned_charms.append(charm_id)
	if charm_id == CIRCLE_HIT_CHARM:
		circle_hit_unlocked = true
		GameState.circle_hit_unlocked = true
	_save_charms()
	charms_changed.emit()
	return true


func has_charm(charm_id: String) -> bool:
	return charm_id in owned_charms


func is_charm_equipped(charm_id: String) -> bool:
	return charm_id in equipped_charms


func toggle_charm(charm_id: String) -> bool:
	if not has_charm(charm_id):
		return false
	if is_charm_equipped(charm_id):
		equipped_charms.erase(charm_id)
	else:
		if get_used_charm_notches() >= charm_notches:
			return false
		equipped_charms.append(charm_id)
	_save_charms()
	charms_changed.emit()
	return true


func get_used_charm_notches() -> int:
	return equipped_charms.size()


func _save_charms() -> void:
	GameState.owned_charms.assign(owned_charms)
	GameState.equipped_charms.assign(equipped_charms)


func _find_attack_hitbox_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	for node in $AttackPivot/Hitbox.get_overlapping_bodies():
		if not node is Node2D or not node.has_method("receive_circle_hit"):
			continue
		if node.get("is_dead") == true:
			continue
		targets.append(node)
	return targets


func _try_start_wall_rebound() -> void:
	var space_state := get_world_2d().direct_space_state
	var closest_contact_distance := INF
	var rebound_from_contact := Vector2.ZERO
	for ray_index in 32:
		var ray_direction := Vector2.RIGHT.rotated(TAU * float(ray_index) / 32.0)
		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + ray_direction * 38.0
		)
		query.exclude = [get_rid()]
		query.collision_mask = collision_mask
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit := space_state.intersect_ray(query)
		if hit.is_empty() or not _is_rebound_surface(hit.get("collider")):
			continue
		var contact_position: Vector2 = hit.get("position")
		var contact_distance := global_position.distance_to(contact_position)
		if contact_distance >= closest_contact_distance:
			continue
		closest_contact_distance = contact_distance
		rebound_from_contact = contact_position.direction_to(global_position)
	if rebound_from_contact.is_zero_approx():
		return
	is_rebounding = true
	rebound_direction = rebound_from_contact


func _is_rebound_surface(collider: Object) -> bool:
	if collider is TileMapLayer:
		return true
	return (
		collider is CollisionObject2D
		and collider.has_meta("obstacle_type")
		and collider.get_meta("obstacle_type") in ["wall", "solid bush"]
	)


func _change_camera_zoom(amount: float) -> void:
	var camera := $Camera2D as Camera2D
	var zoom_value := camera.zoom.x + amount
	zoom_value = clampf(zoom_value, get_minimum_camera_zoom(), default_camera_zoom)
	camera.zoom = Vector2.ONE * zoom_value
	_update_perception_mode()


func get_minimum_camera_zoom() -> float:
	return lerpf(default_camera_zoom, 0.5, float(awareness) / 100.0)


func change_bravery(amount: int, direction: bool) -> void:
	var previous_bravery := bravery
	bravery = clampi(bravery + amount, 0, 100) if direction else clampi(bravery - amount, 0, 100)
	_show_stat_loss(previous_bravery - bravery, "peysmafu")
	stats_changed.emit(bravery, vitality, energy, awareness)


func change_bravery_for_npc_class(npc_class: StringName, amount: int, direction: bool) -> void:
	if not bravery_by_npc_class.has(npc_class):
		bravery_by_npc_class[npc_class] = 0
	var current_value: int = bravery_by_npc_class[npc_class]
	bravery_by_npc_class[npc_class] = (
		clampi(current_value + amount, 0, 100)
		if direction
		else clampi(current_value - amount, 0, 100)
	)
	# Keep the existing general bravery stat for current UI and older mechanics.
	change_bravery(amount, direction)


func get_bravery_for_npc_class(npc_class: StringName) -> int:
	return bravery_by_npc_class.get(npc_class, 0)


func change_vitality(amount: int, direction: bool) -> void:
	if is_dead:
		return
	var previous_vitality := vitality
	vitality = clampi(vitality + amount, 0, 100) if direction else clampi(vitality - amount, 0, 100)
	_show_stat_loss(previous_vitality - vitality, "moy")
	stats_changed.emit(bravery, vitality, energy, awareness)
	if vitality <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	_clear_poisoning()
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	set_process_unhandled_input(false)
	$DeathOverlay.show()
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


func change_energy(amount: int, direction: bool) -> void:
	var previous_energy := energy
	energy = clampi(energy + amount, 0, 100) if direction else clampi(energy - amount, 0, 100)
	_show_stat_loss(previous_energy - energy, "pasew")
	stats_changed.emit(bravery, vitality, energy, awareness)


func change_awareness(amount: int, direction: bool) -> void:
	var previous_awareness := awareness
	awareness = clampi(awareness + amount, 0, 100) if direction else clampi(awareness - amount, 0, 100)
	_show_stat_loss(previous_awareness - awareness, "maysay")
	var camera := $Camera2D as Camera2D
	var clamped_zoom := maxf(camera.zoom.x, get_minimum_camera_zoom())
	camera.zoom = Vector2.ONE * clamped_zoom
	_update_perception_mode()
	stats_changed.emit(bravery, vitality, energy, awareness)


func _show_stat_loss(amount_lost: int, stat_name: String) -> void:
	if amount_lost <= 0 or not is_inside_tree():
		return
	var bubble := PanelContainer.new()
	bubble.add_to_group("stat_loss_bubble")
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.z_index = 250
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.06, 0.9)
	style.border_color = Color(1.0, 0.88, 0.48, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	bubble.add_theme_stylebox_override("panel", style)
	var message := Label.new()
	message.text = "-%d %s" % [amount_lost, stat_name]
	message.add_theme_color_override("font_color", Color(1.0, 0.94, 0.7, 1.0))
	message.add_theme_font_size_override("font_size", 20)
	bubble.add_child(message)
	var animation_root := get_tree().current_scene
	if animation_root == null:
		animation_root = get_tree().root
	animation_root.add_child(bubble)
	bubble.reset_size()
	var start_position := global_position + Vector2(-bubble.size.x * 0.5, -58.0)
	bubble.global_position = start_position
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "global_position", start_position + Vector2(0, -82), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bubble, "modulate", Color(1, 1, 1, 0), 1.0).set_delay(0.6)
	tween.tween_callback(bubble.queue_free)


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


func collect_wo() -> void:
	wo_inventory += 1
	wo_inventory_changed.emit()


func set_lew_state(inventory_index: int, state: LewData.State) -> bool:
	if inventory_index < 0 or inventory_index >= lew_inventory.size():
		return false

	lew_inventory[inventory_index].state = state
	lew_inventory_changed.emit()
	return true


func eat_lew(inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= lew_inventory.size() or is_dead:
		return false
	var lew_data: LewData = lew_inventory.pop_at(inventory_index)
	match lew_data.state:
		LewData.State.PLAIN:
			change_vitality(5, true)
		LewData.State.POISONOUS:
			_start_poisoning()
		LewData.State.TASTY:
			_cure_one_poison_stack()
	lew_inventory_changed.emit()
	return true


func _start_poisoning() -> void:
	if is_dead:
		return
	poison_stacks += 1
	is_poisoned = true
	if $PoisonTimer.is_stopped():
		$PoisonTimer.start()


func _cure_one_poison_stack() -> void:
	poison_stacks = maxi(poison_stacks - 1, 0)
	is_poisoned = poison_stacks > 0
	if not is_poisoned:
		$PoisonTimer.stop()


func _clear_poisoning() -> void:
	poison_stacks = 0
	is_poisoned = false
	$PoisonTimer.stop()


func _on_poison_timer_timeout() -> void:
	if is_dead or poison_stacks <= 0:
		return
	change_vitality(poison_stacks, false)


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
