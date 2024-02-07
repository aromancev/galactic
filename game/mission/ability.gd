class_name Ability
extends Node3D
"""
Represents [Unit] behaviour.

All extending classes MUST override [method Ability.use] and OPTIONALLY [method Ability.terminate].
[Ability] implementationa can use any engine callbacks like "_process" or "_physics_process"
to execute their logic.

WARNING: Unless you know what you are doing, you should only manipulate [Unit] via the proxy
returned by [member Ability.unit]. It ensures a safe way to not shoot yourself in the foot
while keeping [Unit] on all peers in sync.
"""

@export var resource: AbilityResource


# Called to execute the ability.
func use(_target: PackedByteArray) -> void:
	pass


# Called when ability should stop execution. Note: Node processing will not stop automatically.
# It is responsibility of the implementation to verify that it is not active after this call.
func terminate() -> void:
	pass


func get_unit() -> Unit:
	return get_parent()
