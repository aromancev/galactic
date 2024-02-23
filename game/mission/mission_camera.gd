class_name MissionCamera
extends Camera3D
"""
Controlls how camera behavis in the mission.

Active camera instance can be retreived with [method MissionCamera.get_active]. It provides
helper methods to project cursor position onto the level geometry which can be used for
to target a [Ability], for example.
"""

const _MOVE_SPEED = 40
const _TARGET_RAY_LENGTH = 100
const _LEVEL_COLLISION_LAYER = 0

var _level_cursor_projection: Variant

static var _active: MissionCamera = null


static func get_active() -> MissionCamera:
	return _active


# Returns a point in 3D space projected from camera to a certain hight (y coordinate).
# Useful for aiming and launching projectiles in a specific direction.
func get_cursor_projection_at(y: float) -> Vector3:
	var plane := Plane(Vector3.UP, y)
	var mouse_pos := get_viewport().get_mouse_position()
	return plane.intersects_ray(project_ray_origin(mouse_pos), project_ray_normal(mouse_pos))


# Returns a point in 3D space projected from camera to the level geometry. If no intersection is
# found (the projection didn't hit the level), null is returned.
# Useful for movement.
func get_level_cursor_projection() -> Variant:
	return _level_cursor_projection


func _init() -> void:
	_active = self


func _process(delta: float) -> void:
	_move(delta)


func _physics_process(_delta: float) -> void:
	_update_level_cursor_projection()


func _move(delta: float) -> void:
	var vector := Vector3()
	if Input.is_action_pressed("ui_up"):
		vector -= global_transform.basis.z
	if Input.is_action_pressed("ui_down"):
		vector += global_transform.basis.z
	if Input.is_action_pressed("ui_left"):
		vector -= global_transform.basis.x
	if Input.is_action_pressed("ui_right"):
		vector += global_transform.basis.x

	vector.y = 0
	if !vector:
		return

	transform.origin += vector * _MOVE_SPEED * delta


func _update_level_cursor_projection() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var origin := project_ray_origin(mouse_pos)
	var end := origin + project_ray_normal(mouse_pos) * _TARGET_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1 << _LEVEL_COLLISION_LAYER
	var intersection := get_world_3d().direct_space_state.intersect_ray(query)
	if !intersection:
		_level_cursor_projection = null
		return

	_level_cursor_projection = intersection.position
