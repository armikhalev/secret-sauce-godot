extends SceneTree


func _initialize() -> void:
	var menu_actions := ["menu_up", "menu_down", "menu_left", "menu_right"]
	for action in menu_actions:
		var has_dpad_button := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				push_error("Menu action '%s' incorrectly uses a stick axis." % action)
				quit(1)
				return
			if event is InputEventJoypadButton:
				has_dpad_button = true
		if not has_dpad_button:
			push_error("Menu action '%s' is missing its D-pad button." % action)
			quit(1)
			return

	var cross_confirms := false
	for event in InputMap.action_get_events("menu_accept"):
		if event is InputEventJoypadButton and event.button_index == 0:
			cross_confirms = true
	if not cross_confirms:
		push_error("PS5 Cross is not mapped to menu confirm/drop.")
		quit(1)
		return

	var circle_uses_circle := false
	for event in InputMap.action_get_events("circle_hit"):
		if event is InputEventJoypadButton and event.button_index == 1:
			circle_uses_circle = true
	if not circle_uses_circle:
		push_error("Circle-hit is not mapped to PS5 Circle.")
		quit(1)
		return

	var magnet_uses_square := false
	for event in InputMap.action_get_events("magnet_back"):
		if event is InputEventJoypadButton and event.button_index == 2:
			magnet_uses_square = true
	if not magnet_uses_square:
		push_error("Magnet-back is not mapped to PS5 Square.")
		quit(1)
		return

	for action in ["zoom_in", "zoom_out"]:
		var has_right_y_axis := false
		var has_mouse_wheel := false
		var has_keyboard_key := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion and event.axis == 3:
				has_right_y_axis = true
			elif event is InputEventMouseButton:
				has_mouse_wheel = true
			elif event is InputEventKey:
				has_keyboard_key = true
		if not has_right_y_axis:
			push_error("Zoom action '%s' is missing right-stick Y." % action)
			quit(1)
			return
		if not has_mouse_wheel or not has_keyboard_key:
			push_error("Zoom action '%s' lacks desktop controls." % action)
			quit(1)
			return

	print("Controller and desktop menu/zoom mappings verified.")
	quit()
