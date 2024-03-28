extends Ability

var _navigator: Navigator


func use(target: Variant) -> void:
	super(target)
	_navigator.set_target(target as Vector3)
	get_unit().get_agent().play("run")


func process_movement(delta: float) -> Unit.Movement:
	if !is_using() or !get_unit().is_on_floor():
		return null

	var dir := _navigator.get_direction(delta)
	return Unit.Movement.new(dir * get_unit().get_attribute_value("speed"), dir)


func done() -> void:
	super()
	get_unit().get_agent().reset()


func terminate() -> void:
	_navigator.reset()
	get_unit().get_agent().reset()
	super()


func _ready() -> void:
	super()

	_navigator = Navigator.new(get_unit())
	_navigator.target_reached.connect(done)
