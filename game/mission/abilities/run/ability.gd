extends Ability

const _RUNSPEEDMULT = 1.4

var _navigator: Navigator


func use(target: Variant) -> void:
	super(target)
	_navigator.set_target(target as Vector3)


func get_unit_velocity(delta: float) -> Vector3:
	if !is_using() or !get_unit().is_on_floor():
		return Vector3.ZERO

	var unit: Unit = get_unit()
	return _navigator.get_direction(delta) * unit.get_attribute_value("speed") * _RUNSPEEDMULT


func _ready() -> void:
	super()

	_navigator = Navigator.new(get_unit())
	_navigator.target_reached.connect(done)
