"""
A basic entity that represents any charachter in the mission. It can be an NPC, a player, an enemy
, etc.

There is only one scene for all the units but it is designed to be configurable to represent 
different units. The unit configuration is called [Model] and contains all the resources
that define how a particular unit should look and behave like [Ability], [Controller], etc. 
"""
class_name Unit
extends CharacterBody3D

# Key is a pair of slug_id and authority_id stored a Vector2i.
var _controllers: Dictionary = {}
# Key is slug_id.
var _abilities: Dictionary = {}
var _model: Model

@onready var _controller_spawner: MultiplayerSpawner = $ControllerSpawner
@onready var _ability_spawner: MultiplayerSpawner = $AbilitySpawner


# Creates a new configured unit instance.
# Always use this function to create a new unit.
static func instantiate(model: Model) -> Unit:
	var unit: Unit = preload("res://game/mission/unit.tscn").instantiate()
	unit._model = model
	return unit


# Creates and adds a new [Controller] to the unit. The controller will be replicated to all
# peers but only the peer with [param authority_id] will be able to use it.
func add_controller(slug_id: int, authority_id: int) -> void:
	if !is_multiplayer_authority():
		return

	var key := Vector2i(slug_id, authority_id)
	if _controllers.has(key):
		return

	_controller_spawner.spawn(key)


# Removes a [Controller] from the unit.
func remove_controller(slug_id: int, authority_id: int) -> void:
	if !is_multiplayer_authority():
		return

	var key := Vector2i(slug_id, authority_id)
	var controller: Controller = _controllers.get(key)
	if !controller:
		return

	_controllers.erase(key)
	controller.queue_free()


# Creates and adds a [Ability] to the unit. The ability will be replicated to all peers.
func add_ability(slug_id: int) -> void:
	if !is_multiplayer_authority():
		return

	if _abilities.has(slug_id):
		return

	_ability_spawner.spawn(slug_id)


# Removes a [Ability] from the unit.
func remove_ability(slug_id: int) -> void:
	if !is_multiplayer_authority():
		return

	var ability: Ability = _abilities.get(slug_id)
	if !ability:
		return

	_abilities.erase(slug_id)
	ability.queue_free()


# Uses a [Ability]. Should only be called by the authority as RPC but can be called as a regular
# function by a [Controller], for example.
@rpc("authority", "call_local", "reliable")
func use_ability(slug_id: int, target: PackedByteArray) -> void:
	var ability: Ability = _abilities.get(slug_id)
	if !ability:
		return

	ability.use(target)


# Terminates a [Ability]. Should only be called by the authority as RPC but can be called as a regular
# function by a [Controller], for example.
@rpc("authority", "call_local", "reliable")
func terminate_ability(slug_id: int) -> void:
	var ability: Ability = _abilities.get(slug_id)
	if !ability:
		return

	ability.terminate()


func _ready() -> void:
	_controller_spawner.set_spawn_function(_spawn_controller)
	_controller_spawner.despawned.connect(_on_controller_despawned)
	_ability_spawner.set_spawn_function(_spawn_ability)
	_ability_spawner.despawned.connect(_on_ability_despawned)

	if !is_multiplayer_authority():
		return

	# Spawning abilities for all peers. It is tempting to do this locally on every peer
	# to save traffic but it is a bad idea because abilities are dynamic and can be removed at any
	# time. This means peers that join later should receive a modified list of abilities.
	for slug in _model.abilities:
		_ability_spawner.spawn(Ability.get_slug_id(slug))


func _spawn_controller(key: Vector2i) -> Controller:
	var slug_id := key.x
	var authority_id := key.y

	var controller := Controller.load_new(slug_id, self)
	if !controller:
		push_error("Can't find controller with slug_id = %s" % slug_id)
		return

	controller.set_multiplayer_authority(authority_id)
	_controllers[key] = controller
	return controller


# This is only called on puppets (non-authority peers) which is why authority removes it in
# [method Unit.remove_controller].
func _on_controller_despawned(controller: Controller) -> void:
	var key := Vector2i(
		controller.get_class_slug_id(),
		controller.get_multiplayer_authority(),
	)
	_controllers.erase(key)


func _spawn_ability(slug_id: int) -> Ability:
	var ability := Ability.load_new(slug_id, self)
	if !ability:
		push_error("Can't find ability with slug_id =  %s" % slug_id)
		return

	_abilities[slug_id] = ability
	return ability


# This is only called on puppets (non-authority peers) which is why authority removes it in
# [method Unit.remove_ability].
func _on_ability_despawned(ability: Ability) -> void:
	_abilities.erase(ability.get_class_slug_id())
