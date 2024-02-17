extends Ability


func _ready() -> void:
	super()
	get_unit().add_attribute("shield")


func use(_t: Variant) -> void:
	done()


func before_attribute_increment(slug: String, delta: float) -> float:
	if slug != "health" || delta > 0:
		return delta

	var remaining := get_unit().get_attribute_value("shield")
	remaining += delta
	if remaining > 0:
		get_unit().set_attribute_value("shield", remaining)
		return 0

	get_unit().remove_attribute("shield")
	remove_self()
	return remaining
