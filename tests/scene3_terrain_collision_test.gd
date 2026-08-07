extends Node


func _ready() -> void:
	var terrain_scene := (load("res://scenes/scene-3-terrain_details.tscn") as PackedScene).instantiate()
	add_child(terrain_scene)
	var atlas := terrain_scene.tile_set.get_source(0) as TileSetAtlasSource
	assert(atlas != null, "TerrainDetails must have an atlas source")
	for tile_index in atlas.get_tiles_count():
		var coordinates := atlas.get_tile_id(tile_index)
		var tile_data := atlas.get_tile_data(coordinates, 0)
		assert(
			tile_data.get_collision_polygons_count(0) > 0,
			"TerrainDetails atlas tile %s must be solid" % coordinates
		)
	get_tree().quit(0)
