class_name LewData
extends Resource

enum State {
	PLAIN,
	POISONOUS,
	TASTY,
}

@export var state: State = State.PLAIN
