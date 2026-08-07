extends Node


func _ready() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	var saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	add_child(player)
	add_child(saykwastes)
	saykwastes.set_physics_process(false)
	player.position = Vector2.ZERO
	saykwastes.position = Vector2(70, 0)
	await get_tree().process_frame
	player.grant_charm(player.CIRCLE_HIT_CHARM)
	player.toggle_charm(player.CIRCLE_HIT_CHARM)

	var press := InputEventAction.new()
	press.action = "circle_hit"
	press.pressed = true
	player._unhandled_input(press)
	await get_tree().create_timer(0.85).timeout
	assert(saykwastes.fear >= 3, "holding attack must produce consecutive circle strikes")

	var release := InputEventAction.new()
	release.action = "circle_hit"
	release.pressed = false
	player._unhandled_input(release)
	await get_tree().create_timer(0.3).timeout
	var fear_after_release: int = saykwastes.fear
	await get_tree().create_timer(0.5).timeout
	assert(saykwastes.fear == fear_after_release, "releasing attack must stop consecutive strikes")
	get_tree().quit(0)
