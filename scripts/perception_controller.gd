extends Node

@export var hostile_aggression_threshold := 25

@onready var world := get_parent()
@onready var world_art: CanvasItem = world.get_node("WorldArt")
@onready var environment: CanvasItem = world.get_node("Environment")
@onready var items: CanvasItem = world.get_node("Items")
@onready var npc_container: Node = world.get_node("Entities/NPCs")

var expanded_perception := false


func _ready() -> void:
	call_deferred("_connect_player")


func _process(_delta: float) -> void:
	if expanded_perception:
		_update_npc_visibility()


func _connect_player() -> void:
	var player := world.get_node("Entities/Player")
	player.perception_mode_changed.connect(_on_perception_mode_changed)
	_on_perception_mode_changed(player.is_expanded_perception)


func _on_perception_mode_changed(is_expanded: bool) -> void:
	expanded_perception = is_expanded
	world_art.visible = not is_expanded
	environment.visible = not is_expanded
	items.visible = not is_expanded
	_update_npc_visibility()


func _update_npc_visibility() -> void:
	for npc in npc_container.get_children():
		if not npc is CanvasItem:
			continue
		if not expanded_perception:
			npc.visible = true
			continue

		var npc_aggression = npc.get("aggression")
		var npc_trust = npc.get("trust")
		var npc_is_dead = npc.get("is_dead")
		npc.visible = (
			typeof(npc_aggression) == TYPE_INT
			and npc_aggression >= hostile_aggression_threshold
			and (typeof(npc_trust) != TYPE_INT or npc_aggression > npc_trust)
			and (typeof(npc_is_dead) != TYPE_BOOL or not npc_is_dead)
		)
