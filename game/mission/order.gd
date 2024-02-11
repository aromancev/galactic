class_name Order
extends Node

signal spawn(node: Node)

@export var resource: OrderResource
@export var ability_slug: String

var target: Variant
var unit_position: Vector3

var _spawned: Array[Node]


func get_next_unit_position() -> Vector3:
	return unit_position


func _on_spawn(node: Node) -> void:
	_spawned.append(node)


# IMPORTANT: Extending classes should always call `super` in the beginning.
func _ready() -> void:
	spawn.connect(_on_spawn)
	set_process(false)
	set_process_input(false)
	set_process_shortcut_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_physics_process(false)


func _exit_tree() -> void:
	for node in _spawned:
		node.queue_free()
