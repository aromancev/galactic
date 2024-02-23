extends Ability

const _SPEED = 5

var _navigator: UnitNavigator


func use(target: Variant) -> void:
	super(target)
	_navigator.set_target_position(target as Vector3)


func get_unit_velocity() -> Vector3:
	if !is_using() or !get_unit().is_on_floor():
		return Vector3.ZERO

	if _navigator.is_navigation_finished():
		done()
		return Vector3.ZERO

	return _navigator.get_unit_velocity(get_unit(), _SPEED)


func _ready() -> void:
	super()

	_navigator = UnitNavigator.new()
	get_unit().add_child(_navigator)


func _exit_tree() -> void:
	_navigator.queue_free()

	super()
