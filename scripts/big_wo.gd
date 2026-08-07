extends Area2D

var player: CharacterBody2D
var selected_answer := 0
var circle_hit_removed := false

@onready var dialogue := $Dialogue
@onready var moy_label := $Dialogue/Panel/Answers/Moy
@onready var moxoy_label := $Dialogue/Panel/Answers/Moxoy
@onready var embedded_circle := $EmbeddedCircle


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	circle_hit_removed = GameState.big_wo_circle_hit_removed
	if circle_hit_removed:
		_apply_relieved_state()
	_update_selection()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue.visible or circle_hit_removed:
		return
	if event.is_action_pressed("menu_left") or event.is_action_pressed("menu_right"):
		selected_answer = 1 - selected_answer
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_accept"):
		if selected_answer == 0:
			_remove_circle_hit()
		else:
			dialogue.hide()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if circle_hit_removed or not body.is_in_group("player"):
		return
	player = body as CharacterBody2D
	dialogue.show()


func _on_body_exited(body: Node2D) -> void:
	if body != player:
		return
	dialogue.hide()
	player = null


func _update_selection() -> void:
	moy_label.modulate = Color(1.0, 0.88, 0.3) if selected_answer == 0 else Color.WHITE
	moxoy_label.modulate = Color(1.0, 0.88, 0.3) if selected_answer == 1 else Color.WHITE


func _remove_circle_hit() -> void:
	if circle_hit_removed or not is_instance_valid(player):
		return
	circle_hit_removed = true
	GameState.big_wo_circle_hit_removed = true
	if not player.has_charm(player.CIRCLE_HIT_CHARM):
		player.unlock_circle_hit()
	player.grant_charm(player.MAGNET_BACK_CHARM)
	dialogue.hide()
	$LeftTear.hide()
	$RightTear.hide()
	$Mouth.hide()
	embedded_circle.reparent(get_tree().current_scene, true)
	var tween := embedded_circle.create_tween()
	tween.tween_property(embedded_circle, "global_position", player.global_position, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(embedded_circle, "scale", Vector2.ONE * 0.35, 0.65)
	tween.parallel().tween_property(embedded_circle, "modulate", Color(1, 1, 1, 0), 0.65)
	tween.tween_callback(embedded_circle.queue_free)


func _apply_relieved_state() -> void:
	embedded_circle.hide()
	$LeftTear.hide()
	$RightTear.hide()
	$Mouth.hide()
