extends Node


func _ready() -> void:
	GameState.big_wo_circle_hit_removed = false
	GameState.circle_hit_unlocked = false
	GameState.owned_charms.clear()
	GameState.equipped_charms.clear()
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var big_wo := (load("res://scenes/big_wo.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(big_wo)
	player.position = Vector2(0, 300)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(big_wo.has_node("LeftEye") and big_wo.has_node("RightEye"), "big wo must have two eyes")
	assert(big_wo.has_node("Nose"), "big wo must have a rabbit nose")
	assert(big_wo.has_node("LeftTear") and big_wo.has_node("RightTear"), "big wo must visibly suffer")
	assert(big_wo.dialogue.visible, "approaching big wo must show the moy/moxoy choice")
	assert(big_wo.moy_label.text == "moy" and big_wo.moxoy_label.text == "moxoy")

	var right := InputEventAction.new()
	right.action = "menu_right"
	right.pressed = true
	big_wo._unhandled_input(right)
	assert(big_wo.selected_answer == 1, "right must select moxoy")
	var accept := InputEventAction.new()
	accept.action = "menu_accept"
	accept.pressed = true
	big_wo._unhandled_input(accept)
	assert(not big_wo.circle_hit_removed, "confirming moxoy must leave the circle-hit embedded")
	assert(big_wo.get_node("LeftTear").visible, "moxoy must leave big wo suffering")
	big_wo._on_body_exited(player)
	big_wo._on_body_entered(player)
	var left := InputEventAction.new()
	left.action = "menu_left"
	left.pressed = true
	big_wo._unhandled_input(left)
	assert(big_wo.selected_answer == 0, "left must select moy")
	big_wo._unhandled_input(accept)
	assert(big_wo.circle_hit_removed, "confirming moy must remove the embedded circle-hit")
	assert(GameState.big_wo_circle_hit_removed, "removing the circle-hit must persist")
	assert(player.has_charm(player.CIRCLE_HIT_CHARM), "moy must grant the base circle-hit charm")
	assert(player.has_charm(player.CIRCLE_HIT_UPGRADE_CHARM), "moy must grant the circle-hit upgrade charm")
	assert(player.get_used_charm_notches() == 1, "only one charm notch may be occupied")
	assert(player.is_charm_equipped(player.CIRCLE_HIT_CHARM), "the newly granted base charm must be installed")
	assert(player.owned_charms.count(player.CIRCLE_HIT_CHARM) == 1, "the base charm must never duplicate")
	await get_tree().create_timer(0.75).timeout
	assert(not is_instance_valid(big_wo.embedded_circle), "the removed circle-hit must animate into the player and disappear")
	GameState.big_wo_circle_hit_removed = false
	GameState.circle_hit_unlocked = false
	GameState.owned_charms.clear()
	GameState.equipped_charms.clear()
	get_tree().quit(0)
