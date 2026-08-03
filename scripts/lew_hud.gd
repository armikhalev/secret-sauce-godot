extends Label

@export var player_path: NodePath

@onready var player := get_node(player_path)


func _ready() -> void:
	player.lew_inventory_changed.connect(_update_text)
	_update_text()


func _update_text() -> void:
	text = "SAWSUM LI NONPESA\n[I] koyto\nlew %d" % player.lew_inventory.size()
