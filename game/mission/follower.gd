class_name Follower
extends RefCounted
"""
Follower follows target node while avoiding obstacles.
"""

signal target_reached

const _LEVEL_COLLISION_LAYER = 0

# Distance to a point on a path to cosider it reached.
var margin: float = 0.2
# Distance to target to consider it reached.
var target_margin: float = 1
# Value that is going to be substracted from all navigation points Y coordinate. Useful because
# most of the time navigation mesh is floating some distance above the ground.
var height_offset: float = 0.5
# How often the follow path should be recaltulated.
var compute_timeout: float = 0.3

var _subject: Node3D
var _target: Node3D
var _path_index: int = 0
var _path: PackedVector3Array
# Time since last path computation. If negative, will calculate path immediately.
var _since_compute: float = -1


func _init(subject: Node3D) -> void:
	_subject = subject


func set_target(target: Node3D) -> void:
	# Can't follow itself.
	if _subject == target:
		return

	reset()
	_target = target
	_since_compute = -1


func reset() -> void:
	_target = null
	_path = []
	_path_index = 0


func is_navigation_finished() -> bool:
	if _target == null:
		return true

	return _subject.global_position.distance_to(_target.global_position) <= target_margin


# Returns direction for the unit to move towards the target avoiding obstacles.
func get_direction(delta: float) -> Vector3:
	if _target == null:
		return Vector3.ZERO

	if _subject.global_position.distance_to(_target.global_position) <= target_margin:
		reset()
		target_reached.emit()
		return Vector3.ZERO

	_compute_path(delta)

	# No navigation path means moving straight towards the target.
	if _path.is_empty():
		return _subject.global_position.direction_to(_target.global_position)

	# Iterate over all points that are too close.
	var path_point := _path[_path_index]
	path_point.y -= height_offset
	while _subject.global_position.distance_to(path_point) <= margin:
		_path_index += 1
		if _path_index >= _path.size():
			_path = []
			_path_index = 0
			return Vector3.ZERO

		path_point = _path[_path_index]
		path_point.y -= height_offset

	return _subject.global_position.direction_to(path_point)


func _compute_path(delta: float) -> void:
	if _target == null:
		return

	if _since_compute >= 0 and _since_compute < compute_timeout:
		_since_compute += delta
		return

	_since_compute = 0

	# Build navigation path.
	var map := _subject.get_world_3d().get_navigation_map()
	_path = NavigationServer3D.map_get_path(
		map, _subject.global_position, _target.global_position, true
	)
	_path_index = 1
