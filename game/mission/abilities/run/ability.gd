extends Ability

const _RUNSPEED = 10
var _is_running: bool = false

func use(target: Variant) -> void:
	super(target)
	
	var unit: Unit = get_unit()
	if _is_running:
		unit.increment_attribute_value("speed", -_RUNSPEED)
		_is_running = false
	else:
		unit.increment_attribute_value("speed", _RUNSPEED)
		_is_running = true

	done()
