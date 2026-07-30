extends CharacterBody2D

@export_group("Stats")
@export_range(0, 100) var bravery: int = 0
@export_range(0, 100) var vitality: int = 100
@export_range(0, 100) var hunger: int = 0
@export_range(0, 100) var aggression: int = 0
@export_range(0, 100) var trust: int = 0
@export_range(0, 100) var fear: int = 0


func _ready() -> void:
	$GrassDetection.area_entered.connect(_on_grass_entered)


func eat_grass(grass: Grass) -> void:
	match grass.state:
		GrassData.State.POISONOUS:
			vitality = clampi(vitality - 25, 0, 100)
		GrassData.State.TASTY:
			trust = clampi(trust + 25, 0, 100)

	grass.queue_free()


func _on_grass_entered(area: Area2D) -> void:
	if area is Grass:
		eat_grass(area)
