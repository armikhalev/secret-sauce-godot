extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var saykwastes := (load("res://scenes/saykwastes.tscn") as PackedScene).instantiate()
	var poison := (load("res://scenes/grass.tscn") as PackedScene).instantiate() as Grass
	world.add_child(saykwastes)
	poison.state = GrassData.State.POISONOUS
	world.add_child(poison)
	saykwastes.eat_grass(poison)

	if saykwastes.vitality != 75 or not saykwastes.is_poisoned:
		push_error("Poisoning did not start correctly.")
		quit(1)
		return

	for tick in 15:
		saykwastes._on_poison_tick()

	if not saykwastes.is_dead or saykwastes.vitality != 0:
		push_error("Saykwastes did not die gradually from poison.")
		quit(1)
		return

	if saykwastes.get_node("Label").text != "moxoy":
		push_error("Dead saykwastes was not labeled moxoy.")
		quit(1)
		return

	if saykwastes.get_node("CollisionShape2D").disabled:
		push_error("Dead saykwastes lost its collision shape.")
		quit(1)
		return

	saykwastes.receive_push(Vector2(12, 0))
	if saykwastes.position.x <= 0.0:
		push_error("Moxoy could not be pushed.")
		quit(1)
		return

	var stopped_position: Vector2 = saykwastes.position
	for frame in 10:
		await physics_frame
	if not saykwastes.position.is_equal_approx(stopped_position):
		push_error("Moxoy kept sliding after the push ended.")
		quit(1)
		return

	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	world.add_child(player)
	player.position = Vector2.ZERO
	saykwastes.position = Vector2(55, 0)
	var corpse_start_x: float = saykwastes.position.x
	Input.action_press("move_right")
	for frame in 20:
		await physics_frame
	Input.action_release("move_right")

	if saykwastes.position.x <= corpse_start_x:
		push_error(
			"Player contact did not push moxoy: player_x=%.2f corpse_x=%.2f collisions=%d"
			% [player.position.x, saykwastes.position.x, player.get_slide_collision_count()]
		)
		quit(1)
		return

	print("Gradual poisoning, moxoy state, collision, and pushing verified.")
	quit()
