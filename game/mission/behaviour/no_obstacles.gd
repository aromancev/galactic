class_name NoObstaclesCondition
extends ConditionLeaf
"""
Returns SUCCESS if the path between two specified points is passable by a [Unit] without hitting any
obstacles. Otherwise returns FAILURE.
"""

@export_placeholder(EXPRESSION_PLACEHOLDER) var cast_from: String = ""
@export_placeholder(EXPRESSION_PLACEHOLDER) var cast_to: String = ""
@export_range(0, 100) var max_distance: float = 100

@onready var _cast_from_expr: Expression = _parse_expression(cast_from)
@onready var _cast_to_expr: Expression = _parse_expression(cast_to)


func tick(actor: Node, bb: Blackboard) -> int:
	var c: Controller = actor

	var from: Vector3 = _cast_from_expr.execute([], bb)
	if _cast_from_expr.has_execute_failed():
		return FAILURE

	var to: Vector3 = _cast_to_expr.execute([], bb)
	if _cast_to_expr.has_execute_failed():
		return FAILURE

	if from.distance_to(to) > max_distance:
		return FAILURE

	var space := c.get_unit().get_world_3d().direct_space_state
	var ok := LineOfSight.get_default().no_obstacles_between(space, from, to)

	return SUCCESS if ok else FAILURE
