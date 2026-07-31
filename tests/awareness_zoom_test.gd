extends SceneTree


func _initialize() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	root.add_child(player)
	var camera := player.get_node("Camera2D") as Camera2D

	if player.awareness != 50 or not is_equal_approx(player.get_minimum_camera_zoom(), 0.75):
		push_error("Default awareness zoom limit is incorrect.")
		quit(1)
		return

	Input.action_press("zoom_out")
	player._process(1.0)
	Input.action_release("zoom_out")
	if not is_equal_approx(camera.zoom.x, 0.75):
		push_error("Camera zoom exceeded the awareness limit.")
		quit(1)
		return

	player.change_awareness(50, true)
	Input.action_press("zoom_out")
	player._process(1.0)
	Input.action_release("zoom_out")
	if not is_equal_approx(camera.zoom.x, 0.5):
		push_error("Higher awareness did not unlock wider zoom.")
		quit(1)
		return

	Input.action_press("zoom_in")
	player._process(2.0)
	Input.action_release("zoom_in")
	if not is_equal_approx(camera.zoom.x, 1.0):
		push_error("Zoom-in did not stop at the default camera view.")
		quit(1)
		return

	print("Awareness-based camera zoom limits verified.")
	quit()
