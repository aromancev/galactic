extends Ability

const _DAMAGE = 25
const _HIT_RANGE = 1

var _follower: Follower


func use(target: Variant) -> void:
	super(target)
	var unit := Unit.get_unit(target as int)
	if unit == get_unit():
		return

	if get_unit().global_position.distance_to(unit.global_position) <= _HIT_RANGE + 0.1:
		_hit()
	else:
		_follower.set_target(unit)
		get_unit().get_agent().play("run")


func process_movement(delta: float) -> Unit.Movement:
	if !is_using() or !get_unit().is_on_floor():
		return null

	var dir := _follower.get_direction(delta)
	if dir == Vector3.ZERO:
		return Unit.Movement.new(
			Vector3.ZERO,
			get_unit().global_position.direction_to(
				Unit.get_unit(get_target() as int).global_position
			)
		)
	return Unit.Movement.new(dir * get_unit().get_attribute_value("speed"), dir)


func terminate() -> void:
	_follower.reset()
	get_unit().get_agent().reset()
	super()


func _hit() -> void:
	var agent := get_unit().get_agent()
	agent.set_speed("punch", 1.5)
	agent.play("punch")
	if !await timeout(0.7):
		done()
		return

	var unit := Unit.get_unit(get_target() as int)
	unit.increment_attribute_value("health", -_DAMAGE)
	if unit.get_attribute_value("health") == 0:
		unit.set_attribute_value("health", unit.get_attribute_max_value("health"))

	await timeout(0.3)
	done()


func _ready() -> void:
	super()

	_follower = Follower.new(get_unit())
	_follower.target_margin = _HIT_RANGE
	_follower.target_reached.connect(_hit)
