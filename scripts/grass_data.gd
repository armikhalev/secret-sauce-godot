class_name GrassData
extends Resource

enum State {
	PLAIN,
	POISONOUS,
	TASTY,
}

@export var state: State = State.PLAIN
