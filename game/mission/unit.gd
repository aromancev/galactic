class_name Unit
extends CharacterBody3D
"""
A basic entity that represents any charachter in the mission. It can be an NPC, a player, an enemy
, etc.

There is only one scene for all the units but it is designed to be configurable to represent
different units. The unit configuration is called [Model] and contains all the resources
that define how a particular unit should look and behave like [Ability], [Controller], etc.
"""

@export var resource: UnitResource = UnitResource.new()
@export var label: String:
	get:
		return label
	set(v):
		label = v
		if _ui:
			_ui.label = v

# Array[slug, authority_id] => [Controller].
var _controllers: Dictionary = {}
# Slug => [Ability].
var _abilities: Dictionary = {}
# Slug => [Attribute].
var _attributes: Dictionary = {}

@onready var _controller_spawner: MultiplayerSpawner = $ControllerSpawner
@onready var _ability_spawner: MultiplayerSpawner = $AbilitySpawner
@onready var _attribute_spawner: MultiplayerSpawner = $AttributeSpawner
@onready var _ui: UnitUI = $UI


# Creates and adds a new [Controller] to the unit. The controller will be replicated to all
# peers but only the peer with [param authority_id] will be able to use it.
func add_controller(slug: String, authority_id: int) -> void:
	if !is_multiplayer_authority():
		return

	if _controllers.has([slug, authority_id]):
		return

	_controller_spawner.spawn(
		PackedInt32Array([ControllerResource.get_slug_id(slug), authority_id])
	)


# Removes a [Controller] from the unit.
func remove_controller(slug: String, authority_id: int) -> void:
	if !is_multiplayer_authority():
		return

	_remove_controller(slug, authority_id)


# Creates and adds a [Ability] to the unit. The ability will be replicated to all peers.
func add_ability(slug: String) -> void:
	if !is_multiplayer_authority():
		return

	if _abilities.has(slug):
		return

	var slug_id := AbilityResource.get_slug_id(slug)
	_ability_spawner.spawn(slug_id)


# Removes a [Ability] from the unit.
func remove_ability(slug: String) -> void:
	if !is_multiplayer_authority():
		return

	_remove_ability(slug)


# Uses a [Ability]. Should only be called by the authority as RPC but can be called as a regular
# function by a [Controller], for example.
func use_ability(slug: String, target: Target) -> void:
	if !is_multiplayer_authority():
		return

	_use_ability.rpc(AbilityResource.get_slug_id(slug), target.to_bytes())


# Terminates a [Ability]. Should only be called by the authority as RPC but can be called as a
# regular function by a [Controller], for example.
func terminate_ability(slug: String) -> void:
	if !is_multiplayer_authority():
		return

	_terminate_ability.rpc(AbilityResource.get_slug_id(slug))


func add_attribute(slug: String) -> void:
	if !is_multiplayer_authority():
		return

	if _attributes.has(slug):
		return

	var slug_id := AttributeResource.get_slug_id(slug)
	_attribute_spawner.spawn(slug_id)


func remove_attribute(slug: String) -> void:
	if !is_multiplayer_authority():
		return

	_remove_attribute(slug)


func increment_attribute_value(slug: String, delta: float) -> void:
	if !is_multiplayer_authority():
		return

	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	attribute.value += delta
	_on_attribute_changed(slug)


func set_attribute_value(slug: String, value: float) -> void:
	if !is_multiplayer_authority():
		return

	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	attribute.value = value
	_on_attribute_changed(slug)


func set_attribute_min_value(slug: String, min_value: float) -> void:
	if !is_multiplayer_authority():
		return

	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	attribute.min_value = min_value
	_on_attribute_changed(slug)


func set_attribute_max_value(slug: String, max_value: float) -> void:
	if !is_multiplayer_authority():
		return

	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	attribute.max_value = max_value
	_on_attribute_changed(slug)


func _ready() -> void:
	_ui.label = label

	_controller_spawner.set_spawn_function(_spawn_controller)
	_controller_spawner.despawned.connect(_despawn_controller)
	_ability_spawner.set_spawn_function(_spawn_ability)
	_ability_spawner.despawned.connect(_despawn_ability)
	_attribute_spawner.set_spawn_function(_spawn_attribute)
	_attribute_spawner.despawned.connect(_despawn_attribute)

	if !is_multiplayer_authority():
		return

	# Spawning dynamic components for all peers. It is tempting to do this locally on every peer
	# to save traffic but it is a bad idea because dynamic components and can be removed at any
	# time. This means peers that join later should receive a modified list of components.
	# Resetting resources from local because they can be modified inside UnitResource.
	for res in resource.abilities:
		var slug_id := AbilityResource.get_slug_id(res.get_instance_slug())
		var ability: Ability = _ability_spawner.spawn(slug_id)
		ability.resource = res

	for res in resource.attributes:
		var slug := res.get_instance_slug()
		var slug_id := AttributeResource.get_slug_id(slug)
		var attribute: Attribute = _attribute_spawner.spawn(slug_id)
		attribute.resource = res


@rpc("authority", "call_local", "reliable")
func _use_ability(slug_id: int, target: PackedByteArray) -> void:
	var slug := AbilityResource.get_slug(slug_id)
	var ability: Ability = _abilities.get(slug)
	if !ability:
		return

	ability.use(target)


@rpc("authority", "call_local", "reliable")
func _terminate_ability(slug_id: int) -> void:
	var slug := AbilityResource.get_slug(slug_id)
	var ability: Ability = _abilities.get(slug)
	if !ability:
		return

	ability.terminate()


func _spawn_controller(key: PackedInt32Array) -> Controller:
	var slug_id := key[0]
	var authority_id := key[1]

	var slug := ControllerResource.get_slug(slug_id)
	var res: ControllerResource = load(ControllerResource.get_resource_path(slug))
	if !res:
		push_error("Can't find Controller with slug_id = %s" % slug_id)
		return

	var controller := res.instantiate()
	controller.set_multiplayer_authority(authority_id)
	_controllers[[slug, authority_id]] = controller
	return controller


func _despawn_controller(controller: Controller) -> void:
	for key: Array in _controllers:
		var slug: String = key[0]
		var authority_id: int = key[1]
		if _controllers[key] == controller:
			_remove_controller(slug, authority_id)
			return


func _remove_controller(slug: String, authority_id: int) -> void:
	var key := [slug, authority_id]
	var controller: Controller = _controllers.get(key)
	if !controller:
		return

	_controllers.erase(key)
	controller.queue_free()


func _spawn_ability(slug_id: int) -> Ability:
	var slug := AbilityResource.get_slug(slug_id)
	var res: AbilityResource = load(AbilityResource.get_resource_path(slug))
	if !res:
		push_error("Can't find Ability with slug_id =  %s" % slug_id)
		return

	var ability := res.instantiate()

	_abilities[slug] = ability
	return ability


func _despawn_ability(ability: Ability) -> void:
	for slug: String in _abilities:
		if _abilities[slug] == ability:
			_remove_ability(slug)
			return


func _remove_ability(slug: String) -> void:
	var ability: Ability = _abilities.get(slug)
	if !ability:
		return

	_abilities.erase(slug)
	ability.queue_free()


func _spawn_attribute(slug_id: int) -> Attribute:
	var slug := AttributeResource.get_slug(slug_id)
	var res: AttributeResource = load(AttributeResource.get_resource_path(slug))
	if !res:
		push_error("Can't find Attribute with slug_id =  %s" % slug_id)
		return

	var attribute := res.instantiate()
	attribute.changed.connect(_on_attribute_changed.bind(slug))
	_on_attribute_changed(slug)
	if attribute.display_bar():
		_ui.add_bar(slug, AttributeBar.from_attribute(attribute))

	_attributes[slug] = attribute
	return attribute


func _despawn_attribute(attibute: Attribute) -> void:
	for slug: String in _attributes:
		if _attributes[slug] == attibute:
			_remove_attribute(slug)
			return


func _remove_attribute(slug: String) -> void:
	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	_attributes.erase(slug)
	attribute.queue_free()
	_ui.remove_bar(slug)


func _on_attribute_changed(slug: String) -> void:
	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	_ui.set_bar_progress(slug, attribute.value / attribute.max_value)
