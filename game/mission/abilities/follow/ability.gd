extends Ability

const _MARGIN = 1

var _follower: Follower


func use(target: Variant) -> void:
	super(target)
	var unit := Unit.get_unit(target as int)
	_follower.set_target(unit)
	if get_unit().global_position.distance_to(unit.global_position) > _MARGIN + 0.1:
		_follower.set_target(unit)
		get_unit().get_agent().play("run")


func process_movement(delta: float) -> Unit.Movement:
	if !is_using() or !get_unit().is_on_floor():
		return null

	var dir := _follower.get_direction(delta)
	return Unit.Movement.new(dir * get_unit().get_attribute_value("speed"), dir)


func done() -> void:
	super()
	get_unit().get_agent().reset()


func terminate() -> void:
	_follower.reset()
	get_unit().get_agent().reset()
	super()


func _ready() -> void:
	super()

	_follower = Follower.new(get_unit())
	_follower.target_margin = _MARGIN
	_follower.target_reached.connect(done)
