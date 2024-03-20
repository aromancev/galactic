class_name PersonalSpace
extends Area3D
"""
Personal space represents a concept of Unit not wanting to occupy the same
physical space as other Unit. It will push away all nodes with personal space.
IMPORTANT: PersonalSpace should always be a direct child of the node to work
properly.

Personal space concept often works better than rigid collisions. Especially with
network synchronization.
"""

const _MAX_SPEED = 5.
const _RADIUS = 1.
const _MAX_COLLISIONS = 10


func _physics_process(_delta: float) -> void:
	var subject: Unit = get_parent()
	var i := 0
	for a in get_overlapping_areas():
		if not a is PersonalSpace:
			continue

		if i > _MAX_COLLISIONS:
			return

		i += 1

		var colliding: Node3D = a.get_parent()
		if not colliding is CharacterBody3D:
			continue

		var unit: Unit = colliding
		var direction := subject.global_position.direction_to(unit.global_position)
		var distance := subject.global_position.distance_to(unit.global_position)
		var speed := (_RADIUS - distance) / _RADIUS * _MAX_SPEED
		if speed < 0:
			continue

		unit.add_frame_velocity(direction * speed)
