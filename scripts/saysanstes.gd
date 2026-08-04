extends CharacterBody2D

@export_range(-100, 100) var respecting := 0
@export_range(0, 100) var greed := 10
@export_range(0, 100) var aggression := 75
@export var requested_lew := 5
@export var lie_aggression_increase := 25

var player: CharacterBody2D
var question_answered := false
var selected_answer := 0
var lew_remaining := 0
var chosen_saypyastes: Node
var reacted_to_saykwastes_death := false
var lew_demand_started := false
var question_index := 0

@onready var dialogue := $Dialogue
@onready var yey_label := $Dialogue/Panel/Content/Answers/Yey
@onready var no_label := $Dialogue/Panel/Content/Answers/No
@onready var demand_label := $Dialogue/Demand
@onready var question_label := $Dialogue/Panel/Content/Question


func _ready() -> void:
	$ConversationRange.body_entered.connect(_on_conversation_range_entered)
	$ConversationRange.body_exited.connect(_on_conversation_range_exited)
	_react_to_saykwastes_death()
	_update_answer_selection()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue.visible or question_answered:
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
	if lew_remaining > 0:
		dialogue.show()
		_deliver_lew()
	if GameState.saykwastes_is_dead and not question_answered:
		dialogue.show()


func _on_conversation_range_exited(body: Node2D) -> void:
	if body != player:
		return
	dialogue.hide()
	player = null


func _answer_question(answered_yey: bool) -> void:
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


func _start_lew_demand(confiscate_lew: bool, confiscate_wo: bool) -> void:
	lew_demand_started = true
	chosen_saypyastes = _choose_random_saypyastes()
	if confiscate_lew and is_instance_valid(chosen_saypyastes):
		_transfer_all_player_lew(chosen_saypyastes)
	if confiscate_wo and is_instance_valid(chosen_saypyastes):
		_transfer_all_player_wo(chosen_saypyastes)
	lew_remaining = requested_lew
	_update_demand_text()
	$Dialogue/Panel.hide()
	demand_label.show()


func _deliver_lew() -> void:
	if not is_instance_valid(player) or not is_instance_valid(chosen_saypyastes):
		return
	var delivery_count := mini(lew_remaining, player.lew_inventory.size())
	for index in delivery_count:
		var lew_data: LewData = player.lew_inventory.pop_back()
		chosen_saypyastes.receive_lew(lew_data)
	lew_remaining -= delivery_count
	if delivery_count > 0:
		player.lew_inventory_changed.emit()
	_update_demand_text()


func _transfer_all_player_lew(recipient: Node) -> void:
	while not player.lew_inventory.is_empty():
		var lew_data: LewData = player.lew_inventory.pop_back()
		recipient.receive_lew(lew_data)
	player.lew_inventory_changed.emit()


func _transfer_all_player_wo(recipient: Node) -> void:
	if player.wo_inventory <= 0:
		return
	recipient.receive_wo(player.wo_inventory)
	player.wo_inventory = 0
	player.wo_inventory_changed.emit()


func _choose_random_saypyastes() -> Node:
	var candidates := get_tree().get_nodes_in_group("saypyastes")
	if candidates.is_empty():
		return null
	return candidates.pick_random()


func _update_answer_selection() -> void:
	yey_label.modulate = Color(1.0, 0.85, 0.3) if selected_answer == 0 else Color.WHITE
	no_label.modulate = Color(1.0, 0.85, 0.3) if selected_answer == 1 else Color.WHITE


func _update_demand_text() -> void:
	demand_label.text = "mi ma e %d lew" % lew_remaining
	demand_label.visible = lew_remaining > 0
