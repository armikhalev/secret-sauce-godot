extends Node

var saykwastes_is_dead := false
var carried_lew_states: Array[int] = []
var carried_wo_count := 0
var has_carried_inventory := false
var arrival_position := Vector2.ZERO
var has_arrival_position := false
var saysanstes_state: Dictionary = {}
var carried_bravery_by_npc_class: Dictionary = {}
var circle_hit_unlocked := false
var big_wo_circle_hit_removed := false
var saykwastes_state: Dictionary = {}


func capture_player_inventory(player: Node) -> void:
	carried_lew_states.clear()
	for lew_data in player.lew_inventory:
		carried_lew_states.append(lew_data.state)
	carried_wo_count = player.wo_inventory
	carried_bravery_by_npc_class = player.bravery_by_npc_class.duplicate()
	has_carried_inventory = true


func restore_player_inventory(player: Node) -> void:
	if not has_carried_inventory:
		return
	player.lew_inventory.clear()
	for state in carried_lew_states:
		var lew_data := LewData.new()
		lew_data.state = state as LewData.State
		player.lew_inventory.append(lew_data)
	player.wo_inventory = carried_wo_count
	player.bravery_by_npc_class = carried_bravery_by_npc_class.duplicate()
	has_carried_inventory = false
	player.lew_inventory_changed.emit()
	player.wo_inventory_changed.emit()


func set_arrival_position(position: Vector2) -> void:
	arrival_position = position
	has_arrival_position = true


func restore_player_position(player: Node2D) -> void:
	if not has_arrival_position:
		return
	player.global_position = arrival_position
	has_arrival_position = false
