extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var wo := (load("res://scenes/wo.tscn") as PackedScene).instantiate()
	world.add_child(wo)

	if wo.vitality != 100:
		push_error("Wo did not start with 100 vitality.")
		quit(1)
		return

	wo.hunger = 100
	wo._apply_vitality_tick()
	if wo.vitality != 99 or wo._get_vitality_tick_interval() != 1.0:
		push_error("Maximum hunger vitality decay is incorrect.")
		quit(1)
		return

	wo.hunger = 80
	if wo._get_vitality_tick_interval() != 2.0:
		push_error("75-99 hunger vitality interval is incorrect.")
		quit(1)
		return
	wo.hunger = 60
	if wo._get_vitality_tick_interval() != 3.0:
		push_error("50-74 hunger vitality interval is incorrect.")
		quit(1)
		return
	wo.hunger = 30
	if wo._get_vitality_tick_interval() != 4.0:
		push_error("25-49 hunger vitality interval is incorrect.")
		quit(1)
		return
	wo.hunger = 20
	if not is_inf(wo._get_vitality_tick_interval()):
		push_error("Low hunger should not reduce vitality.")
		quit(1)
		return

	wo.hunger = 0
	wo.hop_time_remaining = 1.0
	wo.hop_direction = Vector2.RIGHT
	var resting_position: Vector2 = wo.position
	wo._physics_process(0.1)
	if not wo.position.is_equal_approx(resting_position):
		push_error("Wo moved at zero hunger.")
		quit(1)
		return

	wo._apply_hunger_second()
	if wo.hunger != 1:
		push_error("Wo hunger did not rise each second.")
		quit(1)
		return

	var lew := (load("res://scenes/lew.tscn") as PackedScene).instantiate() as Lew
	world.add_child(lew)
	wo.hunger = 50
	wo.vitality = 10
	wo.eat_lew(lew)
	if wo.hunger != 25 or wo.vitality != 100:
		push_error("Eating lew did not lower hunger and restore vitality.")
		quit(1)
		return

	var starving_wo := (load("res://scenes/wo.tscn") as PackedScene).instantiate()
	world.add_child(starving_wo)
	starving_wo.hunger = 100
	starving_wo.vitality = 1
	starving_wo._apply_vitality_tick()
	await process_frame
	if is_instance_valid(starving_wo):
		push_error("Wo did not die at zero vitality.")
		quit(1)
		return

	print("Wo hunger, vitality decay, movement pause, and feeding reset verified.")
	quit()
