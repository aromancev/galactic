extends Ability

const _SPEED = 3

var _follower: Follower


func use(target: Variant) -> void:
	super(target)
	var unit := Unit.get_unit(target as int)
	_follower.set_target(unit)


func get_unit_velocity(delta: float) -> Vector3:
	if _follower.is_navigation_finished():
		done()
		return Vector3.ZERO

	if !is_using() or !get_unit().is_on_floor():
		return Vector3.ZERO

	return _follower.get_direction(delta) * _SPEED


func _ready() -> void:
	super()

	_follower = Follower.new(get_unit())
