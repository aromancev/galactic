extends Node
"""
Highest-level entity that represents a particular mission. It could also be an intermediate
location like a base or a ship.

It contains level and units. It orchestrates all hihg-level logic of what is happening.
"""

# peer_id => Unit
var _players: Dictionary = {}

@onready var _level: Node3D = $Level
@onready var _unit_spawner: MultiplayerSpawner = $UnitSpawner
@onready var _units: Node3D = $Units
@onready var _ui: MissionUI = $UI
@onready var _mode_controls: Control = $UI/ModeControls
@onready var _num_enemies: LineEdit = $UI/ModeControls/HBoxContainer/NumEnemies


func _ready() -> void:
	_unit_spawner.set_spawn_function(_spawn_unit)
	_mode_controls.visible = is_multiplayer_authority()

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
	var unit: Unit = _unit_spawner.spawn(UnitResource.get_slug_id("trooper"))
	unit.add_controller("player", peer_id)
	unit.add_to_team(0)
	_players[peer_id] = unit
	_select_unit.rpc_id(peer_id, unit.id)


func _spawn_enemy() -> void:
	var unit: Unit = _unit_spawner.spawn(UnitResource.get_slug_id("alien"))
	if randi_range(0, 1):
		unit.add_controller("range", get_multiplayer_authority())
	else:
		unit.add_controller("melee", get_multiplayer_authority())
	unit.add_to_team(1)
	unit.add_to_group("enemies")


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
	unit.position = _get_random_point_on_test_level()
	unit.spawn.connect(_on_unit_spawn)
	return unit


func _spawn_shield() -> void:
	var Scene := preload("res://game/mission/abilities/shield/powerup.tscn")
	var shield: ShieldPowerup = Scene.instantiate()
	shield.position = _get_random_point_on_test_level()
	shield.collected.connect(_spawn_shield)
	_units.add_child(shield, true)


func _on_unit_spawn(node: Node) -> void:
	_units.add_child(node)


func _on_queue_switch_toggled(is_on: bool) -> void:
	if !is_multiplayer_authority():
		return

	for unit: Unit in _players.values():
		unit.is_queueing_abilities = is_on


func _on_start_queue_pressed() -> void:
	if !is_multiplayer_authority():
		return

	for unit: Unit in _players.values():
		unit.ability_queue_start()


func _get_random_point_on_test_level() -> Vector3:
	const _TEST_LEVEL_WIDTH = 16. * 4

	var p := Vector3.ZERO
	p.x = randf_range(-_TEST_LEVEL_WIDTH / 2, _TEST_LEVEL_WIDTH / 2)
	p.z = randf_range(-_TEST_LEVEL_WIDTH / 2, _TEST_LEVEL_WIDTH / 2)
	return p


func _on_spawn_enemies_pressed() -> void:
	_num_enemies.release_focus()
	for i in int(_num_enemies.text):
		_spawn_enemy()


func _on_clear_enemies_pressed() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()


@rpc("authority", "call_local", "reliable")
func _select_unit(id: int) -> void:
	_ui.select_unit(Unit.get_unit(id))
