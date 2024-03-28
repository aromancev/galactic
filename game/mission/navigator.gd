class_name Navigator
extends RefCounted
"""
Navigator is a more flexible alternative to NavigationAgent3D.
"""

signal target_reached

const _LEVEL_COLLISION_LAYER = 0

# Distance to a point on a path to cosider it reached.
var margin: float = 0.2
# Value that is going to be substracted from all navigation points Y coordinate. Useful because
# most of the time navigation mesh is floating some distance above the ground.
var height_offset: float = 0.5

var is_debug: bool = false

var _subject: Node3D
var _target: Variant
var _path_index: int = 0
var _path: PackedVector3Array
var _debug_line: Line3D


func _init(subject: Node3D) -> void:
	_subject = subject


func get_target() -> Variant:
	return _target


func set_target(target: Vector3) -> void:
	reset()
	_target = target


func is_navigation_finished() -> bool:
	return _target == null


func reset() -> void:
	_path = []
	_path_index = 0
	_target = null
	if _debug_line:
		_debug_line.queue_free()
		_debug_line = null


# Returns direction for the unit to move towards the target avoiding obstacles.
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
	_path = NavigationServer3D.map_get_path(map, _subject.global_position, _target as Vector3, true)
	_path_index = 1

	if _debug_line:
		_debug_line.queue_free()
		_debug_line = null

	if is_debug:
		_debug_line = Line3D.new(_path, Color.RED, true)
		_subject.get_tree().get_root().add_child(_debug_line)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _debug_line:
		_debug_line.queue_free()
