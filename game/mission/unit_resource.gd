class_name UnitResource
extends SluggedResource
"""
Represents all configuration resources that define a particular [Unit].
"""

@export var abilities: Array[AbilityResource]
@export var attributes: Array[AttributeResource]

static var _slugs := Slugs.new("res://game/mission/units")


static func get_slugs() -> PackedStringArray:
	return _slugs.get_all()


static func get_slug_id(slug: String) -> int:
	return _slugs.get_id(slug)


static func get_slug(slug_id: int) -> String:
	return _slugs.get_slug(slug_id)


static func get_resource_path(slug: String) -> String:
	return _slugs.get_resource_path(slug)


func instantiate() -> Unit:
	var unit: Unit = preload("res://game/mission/unit.tscn").instantiate()
	unit.resource = self
	return unit
