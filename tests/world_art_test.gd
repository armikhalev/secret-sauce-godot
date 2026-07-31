extends SceneTree


func _initialize() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var world_art := game.get_node("World/WorldArt")

	var required_nodes := [
		"Background/FallbackGround",
		"Background/BaseTerrain",
		"Background/Water",
		"Background/Paths",
		"Background/TerrainDetails",
		"Background/GroundDecals",
		"Background/GroundProps",
		"Foreground/Canopy",
		"Foreground/ForegroundProps",
		"Foreground/WeatherOverlay",
		"WorldLighting",
		"ArtBounds/NorthWest",
		"ArtBounds/SouthEast",
	]

	for node_path in required_nodes:
		if not world_art.has_node(node_path):
			push_error("World art layer '%s' is missing." % node_path)
			quit(1)
			return

	if not world_art.get_node("Background/GroundProps").y_sort_enabled:
		push_error("Background ground props are not Y-sorted.")
		quit(1)
		return

	print("Sprite-ready world art layers and bounds verified.")
	quit()
