class_name AgentResource
extends SluggedResource
"""
Represents all configuration resources that define a particular [Agent].
"""

## Scene must be extended from [Agent].
@export var agent_scene: PackedScene

static var _slugs := Slugs.new("res://game/mission/agents")


static func get_slugs() -> PackedStringArray:
	return _slugs.get_all()


static func get_slug_id(slug: String) -> int:
	return _slugs.get_id(slug)


static func get_slug(slug_id: int) -> String:
	return _slugs.get_slug(slug_id)


static func get_resource_path(slug: String) -> String:
	return _slugs.get_resource_path(slug)
