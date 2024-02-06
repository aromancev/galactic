class_name Knockback
extends Node

const _INITIAL_SPEED = 10
const _DISTANCE = 2
const _STOP_MARGIN = 0.2

var _unit: Unit
var _direction: Vector3
var _initial_pos: Vector3


func _init(unit: Unit, direction: Vector3) -> void:
	_unit = unit
	_direction = direction
	_initial_pos = unit.global_position


func _physics_process(delta: float) -> void:
	# Gradually slowing down.
	var progress := 1 - _unit.global_position.distance_to(_initial_pos) / _DISTANCE
	var speed := _INITIAL_SPEED * progress
	var collision := _unit.move_and_collide(_direction * speed * delta)
	if collision:
		queue_free()
		return

	if _initial_pos.distance_to(_unit.global_position) < _DISTANCE - _STOP_MARGIN:
		return

	queue_free()
