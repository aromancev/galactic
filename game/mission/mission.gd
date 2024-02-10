extends Node
"""
Highest-level entity that represents a particular mission. It could also be an intermediate
location like a base or a ship.

It contains level and units. It orchestrates all hihg-level logic of what is happening.
"""

var _players: Dictionary = {}

@onready var _level: Node3D = $Level
@onready var _unit_spawner: MultiplayerSpawner = $UnitSpawner
@onready var _units: Node3D = $Units


func _ready() -> void:
	_unit_spawner.set_spawn_function(_spawn_unit)

	if !is_multiplayer_authority():
		return

	_level.add_child(preload("res://game/mission/levels/test/level.tscn").instantiate())

	Session.player_connected.connect(_spawn_player)
	Session.player_disconnected.connect(_despawn_player)
	for id: int in Session.players:
		_spawn_player(id, Session.get_player(id))

	for i in 2:
		_spawn_shield()


func _spawn_player(peer_id: int, _player: Player) -> void:
	var unit: Unit = _unit_spawner.spawn(UnitResource.get_slug_id("test"))
	unit.add_controller("player", peer_id)
	_players[peer_id] = unit


func _despawn_player(peer_id: int) -> void:
	var unit: Unit = _players.get(peer_id)
	if !unit:
		return

	unit.queue_free()
	_players.erase(peer_id)


func _spawn_unit(slug_id: int) -> Unit:
	var slug := UnitResource.get_slug(slug_id)
	var resource: UnitResource = load(UnitResource.get_resource_path(slug))
	var unit := resource.instantiate()
	unit.position = Vector3(randf_range(-5, 5), 1, randf_range(-5, 5))
	unit.spawn.connect(_on_unit_spawn)
	return unit


func _spawn_shield() -> void:
	var Scene := preload("res://game/mission/abilities/shield/powerup.tscn")
	var shield: ShieldPowerup = Scene.instantiate()
	shield.position = Vector3(randf_range(-5, 5), 0.5, randf_range(-5, 5))
	shield.collected.connect(_spawn_shield)
	_units.add_child(shield, true)


func _on_unit_spawn(node: Node) -> void:
	_units.add_child(node)
