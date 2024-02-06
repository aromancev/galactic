class_name Ability
extends Node3D
"""
Represents [Unit] behaviour.

[Ability] implementationa can use any engine callbacks like "_process" or "_physics_process"
to execute their logic.

WARNING: Extending classes should never free themselves.
Use [method Ability.remove_self] instead.
"""

signal spawn(node: Node)

@export var resource: AbilityResource


# Called to execute the ability.
func use(_target: PackedByteArray) -> void:
	pass


# Called when ability should stop execution. Note: Node processing will not stop automatically.
# It is responsibility of the implementation to verify that it is not active after this call.
func terminate() -> void:
	pass


# Called before incrementing an attribute. Must return a new delta that should be propagated to the
# attribute.
# Useful to override attribute changes, for example to reduce incoming damage.
func before_attribute_increment(_slug: String, delta: float) -> float:
	return delta


func get_unit() -> Unit:
	return get_parent()


func remove_self() -> void:
	if !get_unit().is_multiplayer_authority():
		return

	get_unit().remove_ability(resource.get_instance_slug())


# Just in case an ability frees itself this will make sure authority removes it from the
# `_abilities` Dictionary as well.
func _exit_tree() -> void:
	remove_self()
