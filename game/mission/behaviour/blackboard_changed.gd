class_name BlackBoardChanged
extends ConditionLeaf
"""
Returns SUCCESS if the specified Blackboard value has changed since the previous tick. Otherwise
returns FAILURE.
"""

@export_placeholder(EXPRESSION_PLACEHOLDER) var key: String = ""

## If true will return SUCCESS even if new value if null.
@export var allow_null: bool = false

var _prev_value: Variant = null

@onready var _key_expression: Expression = _parse_expression(key)


func tick(_actor: Node, bb: Blackboard) -> int:
	var bb_key: Variant = _key_expression.execute([], bb)
	if _key_expression.has_execute_failed():
		return FAILURE

	var new_value: Variant = bb.get_value(bb_key)
	if _prev_value != new_value:
		_prev_value = new_value
		if new_value == null and !allow_null:
			return FAILURE
		return SUCCESS

	return FAILURE
