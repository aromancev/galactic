class_name Order
extends Node
"""
Order has two purposes (phases):
	1. Prepare - visually represent aiming of an [Ability] (e.g. change cursor shape to show
		targeting). In this case [Order.target] is always `null` and Order MUST emit
		[Order.prepared] signal to submit a target that will be later set in the queue phase.
		IMPORTANT: Targets can only be primitive values as they are passed via network. To pass a
		[Unit] as a target, for example, emit it's id (int), not the node itself.
	2. Queue - visually represent an intent to use an [Ability] that's already been confirmed. In
		this case [Order.target] is already set (typically to the value submitted in
		[Order.prepared]).

Always check [Order.is_preparing] to distinguish between phases and create a corresponding visual
representation.

[Order.target] may be set without a prepare phase by AI [Controller]s or UI shortcuts.

[Unit] stores [Order]s in a queue for execution as child nodes. But other nodes can also instantiate
[Order] in the prepareing phase. Never make assumtions about what is the orders parent. Moreover,
[Order] in the prepare phase is not the same instance as the queue phase.
"""

# Can be emitted to spawn additional nodes to visualise the order. Spanwed nodes are cleaned up
# automatically.
signal spawn(node: Node)
# Must be emitted to finish preparing a target. For example, when user is aiming at something.
signal prepared(target: Variant)

# True if user is aiming and false if the order is already in the queue.
var is_preparing: bool
var ability_slug: String
var ability: AbilityResource
# Target that was set for the order (typically by emitting [Order.prepared] in the prepare phase).
# If [Order.is_preparing] is true, target will always be `null`.
var target: Variant
var unit_position: Vector3

var _spawned: Array[Node]


# Should return the position where the [Unit] will be after using the ability. It is necessary to
# correctly display following orders.
func get_next_unit_position() -> Vector3:
	return unit_position


func _on_spawn(node: Node) -> void:
	_spawned.append(node)


# IMPORTANT: Extending classes should always call `super` in the beginning.
func _ready() -> void:
	spawn.connect(_on_spawn)
	set_process(false)
	set_physics_process(false)
	if !is_preparing:
		set_process_input(false)
		set_process_shortcut_input(false)
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)


# IMPORTANT: Extending classes should always call `super` in the end.
func _exit_tree() -> void:
	for node in _spawned:
		node.queue_free()
