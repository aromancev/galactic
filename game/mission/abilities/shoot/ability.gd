extends Ability


func use(target: Variant) -> void:
	super(target)

	await prepare(0.2)

	var ProjectileScene: PackedScene = preload("res://game/mission/abilities/shoot/projectile.tscn")
	var projectile: Node3D = ProjectileScene.instantiate()
	var unit_pos := get_unit().position
	var spawn_offset := unit_pos.direction_to(target as Vector3)
	spawn_offset.y = 0
	spawn_offset = spawn_offset.normalized()
	spawn_offset *= get_unit().get_radius() + 0.2
	var spawn_pos := unit_pos + spawn_offset

	projectile.look_at_from_position(unit_pos, spawn_pos)
	projectile.position = spawn_pos
	projectile.position.y = 1
	spawn.emit(projectile)

	done()
