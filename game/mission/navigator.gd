class_name Navigator
extends RefCounted
"""
Navigator is a more flexible alternative to NavigationAgent3D.

It does not require node instantiation and uses physics to optimize path.
"""

signal target_reached

const _LEVEL_COLLISION_LAYER = 0

# Distance to a point on a path to cosider it reached.
var margin: float = 0.2
# Value that is going to be substracted from all navigation points Y coordinate. Useful because
# most of the time navigation mesh is floating some distance above the ground.
var height_offset: float = 0.5

var _subject: Node3D
var _target: Variant
var _path_index: int = 0
var _path: PackedVector3Array


func _init(subject: Node3D) -> void:
	_subject = subject


func set_target(target: Vector3) -> void:
	reset()
	_target = target


func is_navigation_finished() -> bool:
	return _target == null


func reset() -> void:
	_path = []
	_path_index = 0
	_target = null


# Returns direction for the unit to move towards the target avoiding obstacles.
# WARNING: Uses physics to optimize path. Call only inside `_physics_process`.
func get_direction(_delta: float) -> Vector3:
	if is_navigation_finished():
		return Vector3.ZERO

	_compute_path()

	# Iterate over all points that are too close.
	var from := _subject.global_position
	var path_point := _path[_path_index]
	path_point.y -= height_offset
	while from.distance_to(path_point) <= margin:
		_path_index += 1
		if _path_index >= _path.size():
			reset()
			target_reached.emit()
			return Vector3.ZERO

		path_point = _path[_path_index]
		path_point.y -= height_offset

	return from.direction_to(path_point)


func _compute_path() -> void:
	if _target == null or !_path.is_empty():
		return

	var map := _subject.get_world_3d().get_navigation_map()
	# Check if navigation is required.
	var space := _subject.get_world_3d().direct_space_state
	var from := NavigationServer3D.map_get_closest_point(map, _subject.global_position)
	var to := NavigationServer3D.map_get_closest_point(map, _target as Vector3)
	if LineOfSight.get_default().no_obstacles_between(space, from, to):
		_path = [from, to]
		_path_index = 1
		return

	# Build navigation path.
	_path = NavigationServer3D.map_get_path(map, _subject.global_position, _target as Vector3, true)
	_path_index = 1
