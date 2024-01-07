class_name MissionCamera
extends Camera3D
"""
Controlls how camera behavis in the mission.

Active camera instance can be retreived with [method MissionCamera.get_active]. It provides
helper methods to project cursor position onto the level geometry which can be used for
to target a [Ability], for example.
"""

const _MOVE_SPEED = 40
const _TARGET_RAY_LENGTH = 1000

var _cursor_projection: Vector3

static var _active: MissionCamera = null


static func get_active() -> MissionCamera:
	return _active


func get_cursor_projection() -> Vector3:
	return _cursor_projection


func _init() -> void:
	_active = self


func _physics_process(delta: float) -> void:
	_move(delta)
	_update_cursor_projection()


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


func _update_cursor_projection() -> void:
	var space_state := get_world_3d().direct_space_state
	var mousepos := get_viewport().get_mouse_position()

	var origin := project_ray_origin(mousepos)
	var end := origin + project_ray_normal(mousepos) * _TARGET_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var intersection := space_state.intersect_ray(query)
	if !intersection:
		return

	_cursor_projection = intersection.position
