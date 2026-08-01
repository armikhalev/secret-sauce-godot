extends NavigationRegion2D

@export var navigation_bounds := Rect2(-1600.0, -1000.0, 3200.0, 2000.0)
@export var agent_radius := 58.0
@export var cell_size := 8.0

var _navigation_polygon := NavigationPolygon.new()
var _source_geometry := NavigationMeshSourceGeometryData2D.new()


func _ready() -> void:
	_navigation_polygon.agent_radius = agent_radius
	_navigation_polygon.cell_size = cell_size
	_navigation_polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	_navigation_polygon.parsed_collision_mask = 1
	_navigation_polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	NavigationServer2D.parse_source_geometry_data(
		_navigation_polygon,
		_source_geometry,
		get_parent(),
		_on_source_geometry_parsed
	)


func _on_source_geometry_parsed() -> void:
	_source_geometry.add_traversable_outline(PackedVector2Array([
		navigation_bounds.position,
		Vector2(navigation_bounds.end.x, navigation_bounds.position.y),
		navigation_bounds.end,
		Vector2(navigation_bounds.position.x, navigation_bounds.end.y),
	]))
	NavigationServer2D.bake_from_source_geometry_data_async(
		_navigation_polygon,
		_source_geometry,
		_on_navigation_baked
	)


func _on_navigation_baked() -> void:
	navigation_polygon = _navigation_polygon
