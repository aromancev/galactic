class_name UnitNavigator
extends NavigationAgent3D

var _velocity: Vector3


func get_unit_velocity(unit: Unit, speed: float) -> Vector3:
	if is_navigation_finished():
		return Vector3.ZERO

	# Calculate new desired velocity. Actual velocity will be calculated async by the agent.
	var direction := unit.global_position.direction_to(get_next_path_position())
	direction = direction.normalized()

	# Avoidance becomes too complicated if colliding with multiple surfaces (excluding floor).
	if unit.is_on_floor() and unit.get_slide_collision_count() > 2:
		set_velocity(direction * speed)
		return _velocity

	if unit.get_slide_collision_count() > 1:
		set_velocity(direction * speed)
		return _velocity

	for i in unit.get_slide_collision_count():
		var c := unit.get_slide_collision(i)
		var collider := c.get_collider()
		if not collider is Unit:
			continue

		var other_unit: Unit = collider

		# We need to identify which direction to turn to walk around the unit. To do that we are
		# creating a plane that goes along the direction the unit was moving and detecting if the
		# unit we bumped into is on one side of the plane or the other.
		var plane := Plane(direction.rotated(Vector3.UP, PI / 2), unit.global_position)
		if plane.is_point_over(other_unit.global_position):
			return c.get_normal().rotated(Vector3.UP, PI / 2) * speed
		return c.get_normal().rotated(Vector3.UP, -PI / 2) * speed

	# No collisions, use normal avoidance.
	set_velocity(direction * speed)

	# Always return safe velocity that is calculated async.
	return _velocity


func _ready() -> void:
	# Baken navigation baths are 0.5 meter above the ground.
	# If this is not done, units will try to "climb" up when moving.
	path_height_offset = 0.5
	avoidance_enabled = true
	velocity_computed.connect(_on_velocity_computed)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	_velocity = safe_velocity
