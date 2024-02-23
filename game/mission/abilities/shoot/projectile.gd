extends StaticBody3D

const _SPEED = 7
const _MAX_DISTANCE = 50
const _DAMAGE = 20

var _original_pos: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if _original_pos == Vector3.ZERO:
		_original_pos = global_position

	if global_position.distance_to(_original_pos) > _MAX_DISTANCE:
		queue_free()
		return

	var collision := move_and_collide(-global_basis.z * _SPEED * delta)
	if !collision:
		return

	for i in collision.get_collision_count():
		var collider := collision.get_collider(i)
		if not collider is Unit:
			break

		var unit: Unit = collider
		unit.increment_attribute_value("health", -_DAMAGE)
		if unit.get_attribute_value("health") == 0:
			unit.set_attribute_value("health", unit.get_attribute_max_value("health"))

		var impulse := position.direction_to(unit.position)
		impulse.y = 0
		impulse = impulse.normalized() * 5
		impulse.y = 2
		unit.add_impulse(impulse)
		break

	queue_free()
