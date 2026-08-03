extends CharacterBody2D

@export_range(0, 5) var respecting := 0
@export_range(0, 100) var greed := 0
@export_range(0, 100) var aggression := 75
@export var requested_lew := 5

var player: CharacterBody2D
var question_answered := false
var selected_answer := 0
var lew_remaining := 0
var chosen_saypyastes: Node
var reacted_to_saykwastes_death := false
var lew_demand_started := false

@onready var dialogue := $Dialogue
@onready var yey_label := $Dialogue/Panel/Content/Answers/Yey
@onready var no_label := $Dialogue/Panel/Content/Answers/No
@onready var demand_label := $Dialogue/Demand


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
	question_answered = true
	if answered_yey and GameState.saykwastes_is_dead:
		respecting = clampi(respecting + 1, 0, 5)
	_try_start_lew_demand()
	if lew_remaining <= 0:
		dialogue.hide()


func _react_to_saykwastes_death() -> void:
	if reacted_to_saykwastes_death or not GameState.saykwastes_is_dead:
		return
	reacted_to_saykwastes_death = true
	greed = clampi(greed + 20, 0, 100)


func _try_start_lew_demand() -> void:
	if lew_demand_started:
		return
	if greed > 20 and aggression > 50:
		_start_lew_demand()


func _start_lew_demand() -> void:
	lew_demand_started = true
	chosen_saypyastes = _choose_random_saypyastes()
	if is_instance_valid(chosen_saypyastes):
		_transfer_all_player_lew(chosen_saypyastes)
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
