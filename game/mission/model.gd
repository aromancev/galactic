class_name Model
extends Resource
"""
Represents all configuration resources that define a particular [Unit].
"""

# Abilities that [Unit] should have by default. Should be a list of [Ability] slugs.
@export var abilities: PackedStringArray

static var _slugs: Dictionary = {}


static func get_slugs() -> PackedStringArray:
	_load_slugs()
	return _slugs.keys()


static func get_slug_id(slug: String) -> int:
	_load_slugs()
	var slug_id: int = _slugs.get(slug, -1)
	if slug_id < 0:
		push_error("Model with slug '%s' does not exist" % slug)
		return -1
	return slug_id


static func load_new(slug_id: int) -> Model:
	if slug_id < 0 or slug_id >= get_slugs().size():
		return null

	var slug := get_slugs()[slug_id]
	return load("res://game/mission/models/%s/model.tres" % slug)


static func _load_slugs() -> void:
	if _slugs:
		return

	var slugs := DirAccess.get_directories_at("res://game/mission/models")
	for i in slugs.size():
		_slugs[slugs[i]] = i
