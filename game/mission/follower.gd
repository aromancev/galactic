class_name Follower
extends RefCounted
"""
Follower follows target node while avoiding obstacles.

It does not require node instantiation and uses physics to optimize path.
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
# Physical radius of the subject. Will be used to check if the subject can pass directly without
# hitting anything.
var radius: float = 0.5:
	set(v):
		radius = v
		PhysicsServer3D.shape_set_data(_shape, v)
# How often the follow path should be recaltulated.
var compute_timeout: float = 0.3

var _subject: Node3D
var _target: Node3D
var _path_index: int = 0
var _path: PackedVector3Array
var _shape := PhysicsServer3D.sphere_shape_create()
var _since_compute: float


func _init(subject: Node3D) -> void:
	_subject = subject
	PhysicsServer3D.shape_set_data(_shape, radius)


func set_target(target: Node3D) -> void:
	# Can't follow itself.
	if _subject == target:
		return

	reset()
	_target = target


func reset() -> void:
	_target = null
	_path = []
	_path_index = 0


func is_navigation_finished() -> bool:
	if _target == null:
		return true

	return _subject.global_position.distance_to(_target.global_position) <= target_margin


# Returns direction for the unit to move towards the target avoiding obstacles.
# WARNING: Uses physics to optimize path. Call only inside `_physics_process`.
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

	if _since_compute < compute_timeout:
		_since_compute += delta
		return

	_since_compute = 0

	# Check if navigation is required.
	if _no_obstacles_between(_subject.global_position, _target.global_position):
		_path = []
		_path_index = 0
		return

	# Build navigation path.
	var map := _subject.get_world_3d().get_navigation_map()
	_path = NavigationServer3D.map_get_path(
		map, _subject.global_position, _target.global_position, true
	)
	_path_index = 1


func _no_obstacles_between(from: Vector3, to: Vector3) -> bool:
	from.y += radius + 0.1
	to.y += radius + 0.1

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape_rid = _shape
	query.collision_mask = 1 << _LEVEL_COLLISION_LAYER
	query.transform.origin = from
	query.motion = to - from

	var travel := _subject.get_world_3d().direct_space_state.cast_motion(query)
	# Can travel at least 90% of the path without hitting anything.
	# Not 100% because the path may end very close to a wall.
	return travel[0] >= 0.9


func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return

	PhysicsServer3D.free_rid(_shape)
