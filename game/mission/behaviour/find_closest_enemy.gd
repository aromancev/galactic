class_name FindClosestEnemyAction
extends ActionLeaf
"""
Finds the closest enemy for the specified [Unit] and sets it to the specified Blackboard key.

Returns SUCCESS if enemy was found and set.
"""

@export_placeholder(EXPRESSION_PLACEHOLDER) var to_unit: String = ""
@export_placeholder(EXPRESSION_PLACEHOLDER) var set_key: String = ""

@onready var _to_unit_expr: Expression = _parse_expression(to_unit)
@onready var _set_key_expr: Expression = _parse_expression(set_key)


func tick(_actor: Node, bb: Blackboard) -> int:
	var unit: Unit = _to_unit_expr.execute([], bb)
	if _to_unit_expr.has_execute_failed():
		return FAILURE

	var enemies := unit.get_enemies()
	if enemies.is_empty():
		return FAILURE

	var closest: Unit = enemies[0]
	var closest_distance := unit.global_position.distance_to(closest.global_position)
	for enemy: Unit in enemies:
		var distance := unit.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance

	var key: Variant = _set_key_expr.execute([], bb)
	if _set_key_expr.has_execute_failed():
		return FAILURE

	bb.set_value(key, closest)
	return SUCCESS
