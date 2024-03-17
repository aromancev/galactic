# meta-name: Default
# meta-default: true
extends _BASE_


func tick(actor: Node, blackboard: Blackboard) -> int:
	return SUCCESS


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	pass


func before_run(actor: Node, blackboard: Blackboard) -> void:
	pass


func after_run(actor: Node, blackboard: Blackboard) -> void:
	pass
