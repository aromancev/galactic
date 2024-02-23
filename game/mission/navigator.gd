class_name Navigator
extends RefCounted
"""
Navigator is a more flexible alternative to NavigationAgent3D.

It does not require node instantiation and uses physics to optimize path.
"""

const _RAY_HEIGHT = 0.5
const _LEVEL_COLLISION_LAYER = 0

var margin: float = 0.5
var height_offset: float = 0.5

var _subject: Node3D
var _target: Variant
var _path_index: int = 0
var _path: PackedVector3Array


func _init(subject: Node3D) -> void:
	_subject = subject


func set_target(target: Vector3) -> void:
	_reset_navigation()
	_target = target


func is_navigation_finished() -> bool:
	return _target == null


# Returns direction for the unit to move towards the target avoiding obstacles.
# WARNING: Uses physics to optimize path. Call only inside `_physics_process`.
func get_direction() -> Vector3:
	if is_navigation_finished():
		return Vector3.ZERO

	_calculate_path()

	# Iterate over all points that are too close.
	var from := _subject.global_position
	var path_point := _path[_path_index]
	path_point.y -= height_offset
	while from.distance_to(path_point) <= margin:
		_path_index += 1
		if _path_index >= _path.size():
			_reset_navigation()
			return Vector3.ZERO

		path_point = _path[_path_index]
		path_point.y -= height_offset

	return from.direction_to(path_point)


func _calculate_path() -> void:
	if _target == null or !_path.is_empty():
		return

	# Check if navigation is required.
	if _no_obstacles_between(_subject.global_position, _target as Vector3):
		_path = [_subject.global_position, _target]
		_path[0].y += height_offset
		_path[1].y += height_offset
		_path_index = 0
		return

	# Build navigation path.
	var map := _subject.get_world_3d().get_navigation_map()
	var from := _subject.global_position
	_path = NavigationServer3D.map_get_path(map, from, _target as Vector3, true)
	_path_index = 0


func _no_obstacles_between(from: Vector3, to: Vector3) -> bool:
	from.y += _RAY_HEIGHT
	to.y += _RAY_HEIGHT

	var space := _subject.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << _LEVEL_COLLISION_LAYER
	return space.intersect_ray(query).is_empty()


func _reset_navigation() -> void:
	_path = []
	_path_index = 0
	_target = null
