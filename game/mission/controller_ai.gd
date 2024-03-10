class_name ControllerAI
extends Controller
"""
Base class for all AI controllers.
IMPORTANT: All behaviour trees should be direct children of the controller scene.
"""

@export var blackboard: Blackboard


func _ready() -> void:
	super()

	for c: Node in get_children():
		if not c is BeehaveTree:
			continue

		var tree: BeehaveTree = c
		tree.enabled = tree.enabled and is_processing()

	if blackboard:
		blackboard.set_value("unit", get_unit())
