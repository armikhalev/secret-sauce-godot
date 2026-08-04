extends CharacterBody2D

var stored_lew: Array[LewData] = []
var stored_wo := 0


func _ready() -> void:
	add_to_group("saypyastes")


func receive_lew(lew_data: LewData) -> void:
	stored_lew.append(lew_data)


func receive_wo(amount: int) -> void:
	stored_wo += amount
