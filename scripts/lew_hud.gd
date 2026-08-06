extends Label

@export var player_path: NodePath

var player: CharacterBody2D


func _ready() -> void:
	if player_path.is_empty():
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	else:
		player = get_node(player_path) as CharacterBody2D
	if player == null:
		push_error("LewHud could not find the player.")
		return
	player.lew_inventory_changed.connect(_update_text)
	player.wo_inventory_changed.connect(_update_text)
	_update_text()


func _update_text() -> void:
	text = "SAWSUM LI NONPESA\n[I] koyto\nlew %d\nwo %d" % [player.lew_inventory.size(), player.wo_inventory]
