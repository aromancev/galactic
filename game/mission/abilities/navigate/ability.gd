class_name AbilityNavigate
extends Ability

const _SPEED = 5

@onready var _navigator: NavigationAgent3D = $NavigationAgent3D


func use(target: PackedByteArray) -> void:
	var location := TargetLocation.from_bytes(target)
	_navigator.set_target_position(location.location)


func terminate() -> void:
	_navigator.set_target_position(global_position)


func _physics_process(_delta: float) -> void:
	if _navigator.is_navigation_finished():
		return

	unit.velocity = (
		unit.global_position.direction_to(_navigator.get_next_path_position()) * _SPEED
	)
	unit.move_and_slide()
