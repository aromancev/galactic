extends Ability

const _SPAWN_DISTANCE = 0.2


func use(target: PackedByteArray) -> void:
	var location := TargetLocation.from_bytes(target)
	var ProjectileScene: PackedScene = preload("res://game/mission/abilities/shoot/projectile.tscn")
	var projectile: Node3D = ProjectileScene.instantiate()
	var unit_pos := get_unit().global_position
	var spawn_offset := unit_pos.direction_to(location.location)
	spawn_offset.y = 0
	spawn_offset = spawn_offset.normalized()
	spawn_offset *= get_unit().get_radius() + _SPAWN_DISTANCE
	var spawn_pos := unit_pos + spawn_offset

	spawn.emit(projectile)
	projectile.look_at_from_position(unit_pos, spawn_pos)
	projectile.global_position = spawn_pos
	projectile.global_position.y = unit_pos.y
