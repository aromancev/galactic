class_name AbilityResource
extends SluggedResource

@export var scene: PackedScene

static var _slugs := Slugs.new("res://game/mission/abilities")


static func get_slugs() -> PackedStringArray:
	return _slugs.get_all()


static func get_slug_id(slug: String) -> int:
	return _slugs.get_id(slug)


static func get_slug(slug_id: int) -> String:
	return _slugs.get_slug(slug_id)


static func get_resource_path(slug: String) -> String:
	return _slugs.get_resource_path(slug)


func instantiate() -> Ability:
	var ability: Ability = scene.instantiate()
	ability.resource = self
	return ability
