class_name OrderResource
extends SluggedResource

@export var order_script: Script

static var _slugs := Slugs.new("res://game/mission/orders")


static func get_slugs() -> PackedStringArray:
	return _slugs.get_all()


static func get_slug_id(slug: String) -> int:
	return _slugs.get_id(slug)


static func get_slug(slug_id: int) -> String:
	return _slugs.get_slug(slug_id)


static func get_resource_path(slug: String) -> String:
	return _slugs.get_resource_path(slug)


func set_body(_body: Variant) -> void:
	pass


func get_body() -> Variant:
	return null
