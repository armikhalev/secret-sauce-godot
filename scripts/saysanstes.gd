extends CharacterBody2D

@export_range(-100, 100) var respecting := 0
@export_range(0, 100) var greed := 10
@export_range(0, 100) var aggression := 75
@export var requested_lew := 5
@export var lie_aggression_increase := 25
@export var next_area_door_path: NodePath
@export var persistent_state := false

var player: CharacterBody2D
var question_answered := false
var selected_answer := 0
var lew_remaining := 0
var wo_remaining := 0
var chosen_saypyastes: Node
var reacted_to_saykwastes_death := false
var lew_demand_started := false
var question_index := 0
var demand_completed := false
var ability_announcement_active := false

@onready var dialogue := $Dialogue
@onready var yey_label := $Dialogue/Panel/Content/Answers/Yey
@onready var no_label := $Dialogue/Panel/Content/Answers/No
@onready var demand_label := $Dialogue/Demand
@onready var give_hint := $Dialogue/GiveHint
@onready var question_label := $Dialogue/Panel/Content/Question


func _ready() -> void:
	$ConversationRange.body_entered.connect(_on_conversation_range_entered)
	$ConversationRange.body_exited.connect(_on_conversation_range_exited)
	var restored := _restore_persistent_state()
	if not restored:
		_react_to_saykwastes_death()
		if not GameState.saykwastes_is_dead:
			question_label.text = "wo aw mew e lew?"
	_update_answer_selection()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue.visible:
		return
	if question_answered:
		if ability_announcement_active:
			return
		if (
			(lew_remaining > 0 or wo_remaining > 0)
			and event.is_action_pressed("menu_accept")
		):
			_deliver_requested_items()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_left") or event.is_action_pressed("menu_right"):
		selected_answer = 1 - selected_answer
		_update_answer_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_accept"):
		_answer_question(selected_answer == 0)
		get_viewport().set_input_as_handled()


func _on_conversation_range_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player = body as CharacterBody2D
	_react_to_saykwastes_death()
	if question_answered:
		_try_start_lew_demand()
	if lew_remaining > 0 or wo_remaining > 0:
		dialogue.show()
	if not question_answered:
		dialogue.show()


func _on_conversation_range_exited(body: Node2D) -> void:
	if body != player:
		return
	dialogue.hide()
	player = null


func _answer_question(answered_yey: bool) -> void:
	if not GameState.saykwastes_is_dead:
		question_answered = true
		if answered_yey:
			_start_lew_demand(false, false, 0, 5)
		else:
			_finish_living_saykwastes_wrong_answer()
		_save_persistent_state()
		return

	if question_index == 0:
		if answered_yey and GameState.saykwastes_is_dead:
			question_answered = true
			respecting = clampi(respecting + 1, -100, 100)
			_try_start_lew_demand()
			if lew_remaining <= 0:
				dialogue.hide()
		elif GameState.saykwastes_is_dead:
			aggression = clampi(aggression + lie_aggression_increase, 0, 100)
			respecting = -10
			question_index = 1
			selected_answer = 0
			question_label.text = "saykwastes awgo ty paxasay?"
			_update_answer_selection()
			_save_persistent_state()
	else:
		question_answered = true
		_finish_second_question(answered_yey)


func _finish_second_question(answered_yey: bool) -> void:
	if answered_yey:
		question_label.text = "hahahaha"
		$Dialogue/Panel/Content/Answers.hide()
		await get_tree().create_timer(1.0).timeout
		_start_lew_demand(true, true)
	else:
		_start_lew_demand(false, false)


func _finish_living_saykwastes_wrong_answer() -> void:
	question_label.text = "hahaha"
	$Dialogue/Panel/Content/Answers.hide()
	await get_tree().create_timer(1.0).timeout
	_start_lew_demand(true, true, 5, 3)


func _react_to_saykwastes_death() -> void:
	if reacted_to_saykwastes_death or not GameState.saykwastes_is_dead:
		return
	reacted_to_saykwastes_death = true
	greed = clampi(greed + 20, 0, 100)


func _try_start_lew_demand() -> void:
	if lew_demand_started:
		return
	if greed > 20 and aggression > 50:
		_start_lew_demand(true, false)


func _start_lew_demand(
	confiscate_lew: bool,
	confiscate_wo: bool,
	new_lew_remaining: int = -1,
	new_wo_remaining: int = 0
) -> void:
	lew_demand_started = true
	chosen_saypyastes = _choose_random_saypyastes()
	if confiscate_lew and is_instance_valid(chosen_saypyastes):
		_transfer_all_player_lew(chosen_saypyastes)
	if confiscate_wo and is_instance_valid(chosen_saypyastes):
		_transfer_all_player_wo(chosen_saypyastes)
	lew_remaining = requested_lew if new_lew_remaining < 0 else new_lew_remaining
	wo_remaining = new_wo_remaining
	_update_demand_text()
	$Dialogue/Panel.hide()
	demand_label.show()
	_save_persistent_state()
	if wo_remaining > 0 and is_instance_valid(player) and not player.circle_hit_unlocked:
		_grant_circle_hit_ability()


func _grant_circle_hit_ability() -> void:
	ability_announcement_active = true
	player.unlock_circle_hit()
	question_label.text = "tomoxoy!"
	$Dialogue/Panel/Content/Answers.hide()
	$Dialogue/Panel.show()
	demand_label.hide()
	give_hint.hide()
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	ability_announcement_active = false
	$Dialogue/Panel.hide()
	_update_demand_text()


func _deliver_requested_items() -> void:
	if not is_instance_valid(player) or not is_instance_valid(chosen_saypyastes):
		return
	var delivery_count := mini(lew_remaining, player.lew_inventory.size())
	var delivered_lew_states: Array[int] = []
	for index in delivery_count:
		var lew_data: LewData = player.lew_inventory.pop_back()
		delivered_lew_states.append(lew_data.state)
		chosen_saypyastes.receive_lew(lew_data)
	lew_remaining -= delivery_count
	if delivery_count > 0:
		player.lew_inventory_changed.emit()
	var wo_delivery_count := mini(wo_remaining, player.wo_inventory)
	if wo_delivery_count > 0:
		player.wo_inventory -= wo_delivery_count
		chosen_saypyastes.receive_wo(wo_delivery_count)
		wo_remaining -= wo_delivery_count
		player.wo_inventory_changed.emit()
	_animate_goods_transfer(delivered_lew_states, wo_delivery_count, chosen_saypyastes)
	_update_demand_text()
	if lew_remaining <= 0 and wo_remaining <= 0:
		_complete_demand()
	else:
		_save_persistent_state()


func _complete_demand() -> void:
	if demand_completed:
		return
	demand_completed = true
	respecting = clampi(respecting + 10, -100, 100)
	greed = clampi(greed + 10, 0, 100)
	aggression = clampi(aggression - 10, 0, 100)
	_save_persistent_state()
	var next_area_door := get_node_or_null(next_area_door_path)
	if next_area_door != null and next_area_door.has_method("set_exit_enabled"):
		next_area_door.set_exit_enabled(true)
		if next_area_door is Node2D:
			_announce_open_door(next_area_door as Node2D)


func _announce_open_door(door: Node2D) -> void:
	question_label.text = "cepapyen"
	$Dialogue/Panel/Content/Answers.hide()
	demand_label.hide()
	give_hint.hide()
	$Dialogue/Panel.show()
	dialogue.show()
	var target_rotation: float = global_position.direction_to(door.global_position).angle() + PI / 2.0
	var turn_tween := create_tween()
	turn_tween.tween_property(self, "rotation", target_rotation, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		$Dialogue/Panel.hide()


func _save_persistent_state() -> void:
	if not persistent_state:
		return
	GameState.saysanstes_state = {
		"respecting": respecting,
		"greed": greed,
		"aggression": aggression,
		"question_answered": question_answered,
		"question_index": question_index,
		"lew_demand_started": lew_demand_started,
		"lew_remaining": lew_remaining,
		"wo_remaining": wo_remaining,
		"reacted_to_saykwastes_death": reacted_to_saykwastes_death,
		"demand_completed": demand_completed,
	}


func _restore_persistent_state() -> bool:
	if not persistent_state or GameState.saysanstes_state.is_empty():
		return false
	var state := GameState.saysanstes_state
	respecting = state.get("respecting", respecting)
	greed = state.get("greed", greed)
	aggression = state.get("aggression", aggression)
	question_answered = state.get("question_answered", false)
	question_index = state.get("question_index", 0)
	lew_demand_started = state.get("lew_demand_started", false)
	lew_remaining = state.get("lew_remaining", 0)
	wo_remaining = state.get("wo_remaining", 0)
	reacted_to_saykwastes_death = state.get("reacted_to_saykwastes_death", false)
	demand_completed = state.get("demand_completed", false)
	if lew_demand_started:
		chosen_saypyastes = _choose_random_saypyastes()
		$Dialogue/Panel.hide()
		_update_demand_text()
	elif question_index == 1 and not question_answered:
		question_label.text = "saykwastes awgo ty paxasay?"
	if demand_completed:
		call_deferred("_restore_completed_door")
	return true


func _restore_completed_door() -> void:
	var next_area_door := get_node_or_null(next_area_door_path)
	if next_area_door != null and next_area_door.has_method("set_exit_enabled"):
		next_area_door.set_exit_enabled(true)


func _transfer_all_player_lew(recipient: Node) -> void:
	var transferred_states: Array[int] = []
	while not player.lew_inventory.is_empty():
		var lew_data: LewData = player.lew_inventory.pop_back()
		transferred_states.append(lew_data.state)
		recipient.receive_lew(lew_data)
	player.lew_inventory_changed.emit()
	_animate_goods_transfer(transferred_states, 0, recipient)


func _transfer_all_player_wo(recipient: Node) -> void:
	if player.wo_inventory <= 0:
		return
	var transferred_wo: int = player.wo_inventory
	recipient.receive_wo(transferred_wo)
	player.wo_inventory = 0
	player.wo_inventory_changed.emit()
	_animate_goods_transfer([], transferred_wo, recipient)


func _animate_goods_transfer(lew_states: Array[int], wo_count: int, recipient: Node) -> void:
	if not is_instance_valid(player) or not recipient is Node2D:
		return
	var recipient_2d := recipient as Node2D
	var token_index := 0
	for state in lew_states:
		_launch_goods_token(_create_lew_token(state), recipient_2d.global_position, token_index)
		token_index += 1
	for index in wo_count:
		_launch_goods_token(_create_wo_token(), recipient_2d.global_position, token_index)
		token_index += 1


func _launch_goods_token(token: Polygon2D, destination: Vector2, token_index: int) -> void:
	get_tree().current_scene.add_child(token)
	token.add_to_group("goods_transfer_animation")
	var offset_angle := float(token_index) * 2.4
	token.global_position = player.global_position + Vector2.RIGHT.rotated(offset_angle) * 12.0
	token.z_index = 200
	var tween := token.create_tween()
	tween.tween_interval(float(token_index) * 0.045)
	tween.tween_property(token, "global_position", destination, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(token, "scale", Vector2.ONE * 0.25, 0.55)
	tween.parallel().tween_property(token, "modulate", Color(1, 1, 1, 0.15), 0.55)
	tween.tween_callback(token.queue_free)


func _create_lew_token(state: int) -> Polygon2D:
	var token := Polygon2D.new()
	token.polygon = PackedVector2Array([
		Vector2(-10, 8),
		Vector2(-7, -7),
		Vector2(-3, 3),
		Vector2(0, -10),
		Vector2(3, 3),
		Vector2(8, -7),
		Vector2(10, 8),
	])
	match state:
		LewData.State.POISONOUS:
			token.color = Color(0.55, 0.25, 0.68, 1.0)
		LewData.State.TASTY:
			token.color = Color(0.45, 0.82, 0.28, 1.0)
		_:
			token.color = Color(0.25, 0.65, 0.24, 1.0)
	return token


func _create_wo_token() -> Polygon2D:
	var token := Polygon2D.new()
	var points := PackedVector2Array()
	for point_index in 16:
		points.append(Vector2.RIGHT.rotated(TAU * float(point_index) / 16.0) * 11.0)
	token.polygon = points
	token.color = Color(0.77, 0.72, 0.63, 1.0)
	return token


func _choose_random_saypyastes() -> Node:
	var candidates := get_tree().get_nodes_in_group("saypyastes")
	if candidates.is_empty():
		return null
	return candidates.pick_random()


func _update_answer_selection() -> void:
	yey_label.modulate = Color(1.0, 0.85, 0.3) if selected_answer == 0 else Color.WHITE
	no_label.modulate = Color(1.0, 0.85, 0.3) if selected_answer == 1 else Color.WHITE


func _update_demand_text() -> void:
	if lew_remaining == 5 and wo_remaining == 3:
		demand_label.text = "mi ma e pya (5) lew i san (3) wo"
	elif lew_remaining == 0 and wo_remaining == 5:
		demand_label.text = "mi ma e pya (5) wo"
	elif lew_remaining > 0 and wo_remaining > 0:
		demand_label.text = "mi ma e (%d) lew i (%d) wo" % [lew_remaining, wo_remaining]
	elif lew_remaining > 0:
		demand_label.text = "mi ma e (%d) lew" % lew_remaining
	elif wo_remaining > 0:
		demand_label.text = "mi ma e (%d) wo" % wo_remaining
	demand_label.visible = lew_remaining > 0 or wo_remaining > 0
	give_hint.visible = demand_label.visible
