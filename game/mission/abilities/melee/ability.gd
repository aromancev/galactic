extends Ability

const _DAMAGE = 25

var _follower: Follower


func use(target: Variant) -> void:
	super(target)
	var unit := Unit.get_unit(target as int)
	_follower.set_target(unit)


func get_unit_velocity(delta: float) -> Vector3:
	if !is_using() or !get_unit().is_on_floor():
		return Vector3.ZERO

	return _follower.get_direction(delta) * get_unit().get_attribute_value("speed")


func terminate() -> void:
	_follower.reset()
	super()


func _hit() -> void:
	if !await timeout(1):
		done()
		return

	var unit := Unit.get_unit(get_target() as int)
	unit.increment_attribute_value("health", -_DAMAGE)
	if unit.get_attribute_value("health") == 0:
		unit.set_attribute_value("health", unit.get_attribute_max_value("health"))

	done()


func _ready() -> void:
	super()

	_follower = Follower.new(get_unit())
	_follower.target_reached.connect(_hit)
