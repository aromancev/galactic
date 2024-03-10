class_name LineOfSight
extends RefCounted

const _LEVEL_COLLISION_LAYER = 0

# Radius of the sphere used to cast motion.
var radius: float = 0.5:
	set(v):
		radius = v
		PhysicsServer3D.shape_set_data(_shape, v)

# Distance gap from floor when casting motion. If set to 0 may randomly collide with floor.
var clearance: float = 0.1

var _shape := PhysicsServer3D.sphere_shape_create()

static var _default := LineOfSight.new()


static func get_default() -> LineOfSight:
	return _default


func _init() -> void:
	PhysicsServer3D.shape_set_data(_shape, radius)


func no_obstacles_between(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	from.y += radius + clearance
	to.y += radius + clearance

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape_rid = _shape
	query.collision_mask = 1 << _LEVEL_COLLISION_LAYER
	query.transform.origin = from
	query.motion = to - from

	var travel := space.cast_motion(query)
	return travel[0] == 1


func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return

	PhysicsServer3D.free_rid(_shape)
