class_name UseAbilityAction
extends ActionLeaf
"""
Uses specified [Ability] on the specified target using the [Controller].
"""

@export_placeholder(EXPRESSION_PLACEHOLDER) var ability_slug: String = ""
@export_placeholder(EXPRESSION_PLACEHOLDER) var ability_target: String = ""

## If true the action will return SUCCESS immediately without waiting for the ability to finish.
@export var is_deferred: bool = false

var _is_using := false

@onready var _ability_target_expr: Expression = _parse_expression(ability_target)
@onready var _ability_slug_expr: Expression = _parse_expression(ability_slug)


func before_run(_actor: Node, _bb: Blackboard) -> void:
	_is_using = false


func tick(actor: Node, bb: Blackboard) -> int:
	var c := actor as Controller

	var slug: String = _ability_slug_expr.execute([], bb)
	if _ability_slug_expr.has_execute_failed():
		return FAILURE

	if !is_deferred:
		# Still using the ability.
		if c.get_unit().is_using_ability(slug) and _is_using:
			return RUNNING

		# Used instant ability in the previous tick.
		if _is_using:
			_is_using = false
			return SUCCESS

	var target: Variant = _ability_target_expr.execute([], bb)
	if _ability_target_expr.has_execute_failed():
		return FAILURE

	c.use_ability(slug, target)
	if !is_deferred and c.get_unit().is_using_ability(slug):
		_is_using = true
		return RUNNING

	return SUCCESS
