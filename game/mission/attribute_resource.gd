class_name AttributeResource
extends SluggedResource
"""
Represents all configuration resources that define a particular [Attribute].
"""

@export var name: String
@export var color: Color = Color.WHITE
@export var value: float = 0
@export var min_value: float = 0
@export var max_value: float = 0
@export var display_bar: bool = false

static var _slugs := Slugs.new("res://game/mission/attributes")


static func get_slugs() -> PackedStringArray:
	return _slugs.get_all()


static func get_slug_id(slug: String) -> int:
	return _slugs.get_id(slug)


static func get_slug(slug_id: int) -> String:
	return _slugs.get_slug(slug_id)


static func get_resource_path(slug: String) -> String:
	return _slugs.get_resource_path(slug)


func instantiate() -> Attribute:
	var attribute: Attribute = preload("res://game/mission/attribute.tscn").instantiate()
	attribute.resource = self
	return attribute
