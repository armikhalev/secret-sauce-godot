extends Control

@export var player_path: NodePath

@onready var item_list: VBoxContainer = %ItemList
@onready var empty_label: Label = %EmptyLabel
@onready var player_stats_label: Label = %PlayerStats

var player: CharacterBody2D
var state_selectors: Array[OptionButton] = []
var selected_item_index := 0


func _ready() -> void:
	player = get_node(player_path) as CharacterBody2D
	player.lew_inventory_changed.connect(_on_inventory_changed)
	player.stats_changed.connect(_on_player_stats_changed)
	_update_player_stats()
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		set_menu_open(not visible)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("menu_cancel"):
		set_menu_open(false)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("menu_down"):
		_select_item(selected_item_index + 1)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("menu_up"):
		_select_item(selected_item_index - 1)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("menu_right"):
		_change_selected_state(1)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("menu_left"):
		_change_selected_state(-1)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("menu_accept"):
		_drop_selected_item()
		get_viewport().set_input_as_handled()


func set_menu_open(open: bool) -> void:
	visible = open

	if open:
		rebuild_item_list()
		_update_player_stats()


func rebuild_item_list() -> void:
	state_selectors.clear()
	for child in item_list.get_children():
		child.queue_free()

	empty_label.visible = player.lew_inventory.is_empty()

	for index in player.lew_inventory.size():
		var row := HBoxContainer.new()
		var item_label := Label.new()
		var state_selector := OptionButton.new()

		item_label.text = "Lew %d" % (index + 1)
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		state_selector.add_item("li kunkis", LewData.State.PLAIN)
		state_selector.add_item("li yaxatolosoy", LewData.State.POISONOUS)
		state_selector.add_item("li mewteylavi", LewData.State.TASTY)
		state_selector.select(player.lew_inventory[index].state)
		state_selector.focus_mode = Control.FOCUS_NONE
		state_selector.item_selected.connect(_on_state_selected.bind(index))

		row.add_child(item_label)
		row.add_child(state_selector)
		item_list.add_child(row)
		state_selectors.append(state_selector)

	if not state_selectors.is_empty():
		_select_item(clampi(selected_item_index, 0, state_selectors.size() - 1))


func _on_state_selected(selected_index: int, inventory_index: int) -> void:
	player.set_lew_state(inventory_index, selected_index as LewData.State)


func _on_inventory_changed() -> void:
	if visible and state_selectors.size() != player.lew_inventory.size():
		rebuild_item_list()


func _on_player_stats_changed(_bravery: int, _vitality: int, _energy: int, _awareness: int) -> void:
	_update_player_stats()


func _update_player_stats() -> void:
	player_stats_label.text = (
		"PEYSMAFU\n%d / 100\n\nMOYSEW\n%d / 100\n\nPASEW\n%d / 100\n\nMAYSAY\n%d / 100"
		% [player.bravery, player.vitality, player.energy, player.awareness]
	)


func _select_item(index: int) -> void:
	if state_selectors.is_empty():
		selected_item_index = 0
		return

	selected_item_index = posmod(index, state_selectors.size())
	for selector_index in state_selectors.size():
		state_selectors[selector_index].modulate = (
			Color(1.0, 0.9, 0.45) if selector_index == selected_item_index else Color.WHITE
		)


func _change_selected_state(direction: int) -> void:
	if state_selectors.is_empty():
		return

	var selector := state_selectors[selected_item_index]
	var state_count := selector.item_count
	var new_state := posmod(selector.selected + direction, state_count)
	selector.select(new_state)
	player.set_lew_state(selected_item_index, new_state as LewData.State)


func _drop_selected_item() -> void:
	if player.lew_inventory.is_empty():
		return

	var forward := Vector2.UP.rotated(player.rotation)
	var drop_position := player.global_position + forward * 96.0
	player.drop_lew(selected_item_index, drop_position)

	if player.lew_inventory.is_empty():
		selected_item_index = 0
	else:
		selected_item_index = mini(selected_item_index, player.lew_inventory.size() - 1)
