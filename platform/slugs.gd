class_name Slugs
extends RefCounted

var _slugs: Dictionary = {}
var _dir: String


func _init(dir: String) -> void:
	_dir = dir


func get_all() -> PackedStringArray:
	load_all()
	return _slugs.keys()


func get_slug(id: int) -> String:
	load_all()
	if id < 0 || id >= _slugs.size():
		return ""

	return _slugs.keys()[id]


func get_id(slug: String) -> int:
	load_all()
	var slug_id: int = _slugs.get(slug, -1)
	if slug_id < 0:
		return -1
	return slug_id


func load_all() -> void:
	if _slugs:
		return

	var slugs := DirAccess.get_directories_at(_dir)
	for i in slugs.size():
		_slugs[slugs[i]] = i


func get_resource_path(slug: String) -> String:
	return "%s/%s/resource.tres" % [_dir, slug]
