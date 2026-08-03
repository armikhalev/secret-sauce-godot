extends Node

var saykwastes_is_dead := false
var carried_lew_states: Array[int] = []
var has_carried_inventory := false


func capture_player_inventory(player: Node) -> void:
	carried_lew_states.clear()
	for lew_data in player.lew_inventory:
		carried_lew_states.append(lew_data.state)
	has_carried_inventory = true


func restore_player_inventory(player: Node) -> void:
	if not has_carried_inventory:
		return
	player.lew_inventory.clear()
	for state in carried_lew_states:
		var lew_data := LewData.new()
		lew_data.state = state as LewData.State
		player.lew_inventory.append(lew_data)
	has_carried_inventory = false
	player.lew_inventory_changed.emit()
