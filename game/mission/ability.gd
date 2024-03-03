class_name Ability
extends Node
"""
Represents [Unit] behaviour such as move or attack.

WARNING: Extending classes should never free themselves.
Use [method Ability.remove_self] instead.
"""

signal spawn(node: Node)
signal used(target: Variant)
signal terminated

@export var resource: AbilityResource

var _is_using: bool
var _target: Variant


# Called to execute the ability.
# IMPORTANT: Extending classes should always call `super` in the beginning.
func use(target: Variant) -> void:
	_is_using = true
	_target = target


# Called when ability should stop execution. Note: Node processing will not stop automatically.
# It is responsibility of the implementation to verify that it is not active after this call.
# IMPORTANT: Extending classes should always call `super` in the end.
func terminate() -> void:
	if !_is_using:
		return

	_is_using = false
	_target = null
	terminated.emit()


# Called inside `_physics_process` so it is safe to use physics inside.
func get_unit_velocity(_delta: float) -> Vector3:
	return Vector3.ZERO


# Called before incrementing an attribute. Must return a new delta that should be propagated to the
# attribute.
# Useful to override attribute changes, for example to reduce incoming damage.
func before_attribute_increment(_slug: String, delta: float) -> float:
	return delta


func is_using() -> bool:
	return _is_using


func get_target() -> Variant:
	return _target


func get_unit() -> Unit:
	return get_parent()


func remove_self() -> void:
	if !get_unit().is_multiplayer_authority():
		return

	get_unit().remove_ability(resource.get_instance_slug())


func done() -> void:
	if !_is_using:
		return

	_is_using = false
	var target: Variant = _target
	_target = null
	used.emit(target)


# IMPORTANT: Extending classes should always call `super` in the beginning.
func _ready() -> void:
	set_physics_process(false)
	set_process_input(false)
	set_process_shortcut_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)


# Just in case an ability frees itself this will make sure authority removes it from the
# `_abilities` Dictionary as well.
# IMPORTANT: Extending classes should always call `super` in the end.
func _exit_tree() -> void:
	remove_self()
