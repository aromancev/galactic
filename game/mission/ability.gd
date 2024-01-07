class_name Ability
extends Node3D
"""
Represents [Unit] behaviour.

All extending classes MUST override [method Ability.use] and OPTIONALLY [method Ability.terminate].
[Ability] implementationa can use any engine callbacks like "_process" or "_physics_process"
to execute their logic.

WARNING: Unless you know what you are doing, you should only manipulate [Unit] via the proxy
returned by [member Ability.unit]. It ensures a safe way to not shoot yourself in the foot
while keeping [Unit] on all peers in sync.
"""

var unit: UnitProxy:
	get:
		return _proxy

var _unit: Unit
var _proxy: UnitProxy
var _slug_id: int

static var _slugs: Dictionary = {}


# Called to execute the ability.
func use(_target: PackedByteArray) -> void:
	pass


# Called when ability should stop execution. Note: Node processing will not stop automatically.
# It is responsibility of the implementation to verify that it is not active after this call.
func terminate() -> void:
	pass


static func get_slugs() -> PackedStringArray:
	_load_slugs()
	return _slugs.keys()


static func get_slug_id(slug: String) -> int:
	_load_slugs()
	var slug_id: int = _slugs.get(slug, -1)
	if slug_id < 0:
		push_error("Ability with slug '%s' does not exist" % slug)
		return -1
	return slug_id


# Loads and returns a new instance of the ability scene. Only create new abilities using this
# method.
static func load_new(slug_id: int, unit_p: Unit) -> Ability:
	if slug_id < 0 or slug_id >= get_slugs().size():
		return null

	var slug := get_slugs()[slug_id]
	var scene: PackedScene = load("res://game/mission/abilities/%s/ability.tscn" % slug)
	var ability: Ability = scene.instantiate()
	ability._unit = unit_p
	ability._proxy = UnitProxy.new(unit_p)
	ability._slug_id = slug_id
	return ability


func get_class_slug_id() -> int:
	return _slug_id


static func _load_slugs() -> void:
	if _slugs:
		return

	var slugs := DirAccess.get_directories_at("res://game/mission/abilities")
	for i in slugs.size():
		_slugs[slugs[i]] = i


# A safe [Unit] wrapper for [Ability] implementations.
class UnitProxy:
	extends RefCounted

	var velocity: Vector3:
		get:
			return _unit.velocity

		set(v):
			_unit.velocity = v

	var global_position: Vector3:
		get:
			return _unit.global_position

	var _unit: Unit

	func move_and_slide() -> bool:
		return _unit.move_and_slide()

	func add_ability(slug: String) -> void:
		_unit.add_ability(Ability.get_slug_id(slug))

	func remove_ability(slug: String) -> void:
		_unit.remove_ability(Ability.get_slug_id(slug))

	func use_ability(slug: String, target: Target) -> void:
		if !_unit.is_multiplayer_authority():
			return

		_unit.use_ability.rpc(Ability.get_slug_id(slug), target.to_bytes())

	func _init(unit: Unit) -> void:
		_unit = unit
