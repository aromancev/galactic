class_name AbilityUsedEvent
extends UnitEvent

var slug: String
var target: Variant


func _init(unit_id_p: int, slug_p: String, target_p: Variant = null) -> void:
	super(unit_id_p)
	slug = slug_p
	target = target_p
