extends SceneTree


func _initialize() -> void:
	var expected_menu_axes := {
		"menu_up": 3,
		"menu_down": 3,
		"menu_left": 2,
		"menu_right": 2,
	}

	for action: String in expected_menu_axes:
		var found_right_stick_axis := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton:
				push_error("Menu action '%s' still uses the D-pad." % action)
				quit(1)
				return
			if event is InputEventJoypadMotion and event.axis == expected_menu_axes[action]:
				found_right_stick_axis = true
		if not found_right_stick_axis:
			push_error("Menu action '%s' is missing its right-stick axis." % action)
			quit(1)
			return

	for action in ["move_left", "move_right", "move_up", "move_down"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion and event.axis > 1:
				push_error("Movement action '%s' incorrectly uses the right stick." % action)
				quit(1)
				return

	print("Left-stick movement and right-stick menu controls are isolated.")
	quit()
