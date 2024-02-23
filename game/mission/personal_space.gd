class_name PersonalSpace
extends Area3D
"""
Personal space represents a concept of node not wanting to occupy the same
physical space as other nodes. It will push away all nodes with personal space.
IMPORTANT: PersonalSpace should always be a direct child of the node to work
properly.

Personal space concept often works better than rigid collisions. Especially with
network synchronization.
"""

const _MAX_SPEED = 5.
const _RADIUS = 1.
const _MAX_COLLISIONS = 10


func _physics_process(delta: float) -> void:
	var unit: Node3D = get_parent()
	var i := 0
	for a in get_overlapping_areas():
		if not a is PersonalSpace:
			continue

		if i > _MAX_COLLISIONS:
			return

		i += 1

		var colliding: Node3D = a.get_parent()
		var direction := unit.global_position.direction_to(colliding.global_position)
		var distance := unit.global_position.distance_to(colliding.global_position)
		var speed := (_RADIUS - distance) / _RADIUS * _MAX_SPEED
		if speed < 0:
			continue

		colliding.global_position += direction * speed * delta
