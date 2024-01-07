"""
Represents a way to control [Unit] behaviour.

Each [Controller] is owned by a peer which can be different from [Unit] authority.
IMPORTANT: [Controller] should only tell what [Unit] WANTS to do but it doesn't define
what it CAN do. It MUST NOT define any new behaviour for a [Unit] like an [Ability] would.
"""
class_name Controller
extends Node3D

var _unit: Unit
var _slug_id: int

static var _slugs: Dictionary = {}


static func get_slugs() -> PackedStringArray:
	_load_slugs()
	return _slugs.keys()


static func get_slug_id(slug: String) -> int:
	_load_slugs()
	var slug_id: int = _slugs.get(slug, -1)
	if slug_id < 0:
		push_error("Controller with slug '%s' does not exist" % slug)
		return -1
	return slug_id


static func load_new(slug_id: int, unit: Unit) -> Controller:
	if slug_id < 0 or slug_id >= get_slugs().size():
		return null

	var slug := get_slugs()[slug_id]
	var scene: PackedScene = load("res://game/mission/controllers/%s/controller.tscn" % slug)
	var controller: Controller = scene.instantiate()
	controller._unit = unit
	controller._slug_id = slug_id
	return controller


func get_class_slug_id() -> int:
	return _slug_id


func use_ability(slug: String, target: Target) -> void:
	_use_ability.rpc(Ability.get_slug_id(slug), target.to_bytes())


static func _load_slugs() -> void:
	if _slugs:
		return

	var slugs := DirAccess.get_directories_at("res://game/mission/controllers")
	for i in slugs.size():
		_slugs[slugs[i]] = i


func _ready() -> void:
	var is_authority := get_multiplayer_authority() == multiplayer.get_unique_id()
	set_process(is_authority)
	set_process_input(is_authority)
	set_physics_process(is_authority)


@rpc("authority", "call_local", "reliable")
func _use_ability(slug_id: int, target: PackedByteArray) -> void:
	_unit.use_ability(slug_id, target)
