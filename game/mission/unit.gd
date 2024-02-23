class_name Unit
extends CharacterBody3D
"""
A basic entity that represents any charachter in the mission. It can be an NPC, a player, an enemy
, etc.

There is only one scene for all the units but it is designed to be configurable to represent
different units. The unit configuration is called [Model] and contains all the resources
that define how a particular unit should look and behave like [Ability], [Controller], etc.
"""

signal spawn(node: Node)

const _MAX_IMPULSE_HORIZONTAL = 15
const _MAX_IMPULSE_VERTICAL = 5
const _HORIZONTAL_DRAG = 10
const _GRAVITY = 9.8

@export var resource: UnitResource = UnitResource.new()

@export var label: String:
	get:
		return label
	set(v):
		label = v
		if _ui:
			_ui.label = v

# Bit field that stores all teams that the Unit is in.
@export var _teams: int
@export var is_queueing_abilities: bool = false:
	set(v):
		is_queueing_abilities = v
		ability_queue_clear()

@export var _position_sync: Vector3:
	set(v):
		_position_sync = v
		if !is_multiplayer_authority():
			position = v

@export var _impulse_sync: Vector3:
	set(v):
		_impulse_sync = v
		if !is_multiplayer_authority():
			_impulse = v

var _impulse: Vector3

# Array[slug, authority_id] => [Controller].
var _controllers: Dictionary = {}
# Slug => [Ability].
var _abilities: Dictionary = {}
# Slug => [Attribute].
var _attributes: Dictionary = {}

@onready var _controller_spawner: MultiplayerSpawner = $ControllerSpawner
@onready var _ability_spawner: MultiplayerSpawner = $AbilitySpawner
@onready var _order_spawner: MultiplayerSpawner = $OrderSpawner
@onready var _orders: Node = $Orders
@onready var _attribute_spawner: MultiplayerSpawner = $AttributeSpawner
@onready var _collider: CollisionShape3D = $CollisionShape3D
@onready var _ui: UnitUI = $UI


func get_radius() -> float:
	var capsule: CapsuleShape3D = _collider.shape
	return capsule.radius


func add_to_team(team: int) -> void:
	assert(team >= 0 and team < 64, "Exceeded team number range [0, 63].")
	_teams |= 1 << team


func remove_from_team(team: int) -> void:
	assert(team >= 0 and team < 64, "Exceeded team number range [0, 63].")
	_teams &= ~(1 << team)


func get_teams() -> int:
	return _teams


func is_on_same_team(other: Unit) -> bool:
	return bool(other.get_teams() & _teams)


func add_impulse(delta: Vector3) -> void:
	if !is_multiplayer_authority():
		return

	if !delta:
		return

	_impulse += delta

	# Limiting horizontal impulse.
	var xz := _impulse
	xz.y = 0
	if xz.length() > _MAX_IMPULSE_HORIZONTAL:
		xz = xz.normalized() * _MAX_IMPULSE_HORIZONTAL
	_impulse.x = xz.x
	_impulse.z = xz.z

	# Limiting vertical impulse.
	_impulse.y = clamp(delta.y, 0, _MAX_IMPULSE_VERTICAL)

	_position_sync = position
	_impulse_sync = _impulse


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
func use_ability(ability_slug: String, _order_slug: String, target: Variant) -> void:
	if !is_multiplayer_authority():
		return

	var ability_slug_id := AbilityResource.get_slug_id(ability_slug)
	_position_sync = position
	_use_ability.rpc(ability_slug_id, target)


# Terminates a [Ability]. Should only be called by the authority as RPC but can be called as a
# regular function by a [Controller], for example.
func terminate_ability(slug: String) -> void:
	if !is_multiplayer_authority():
		return

	_terminate_ability.rpc(AbilityResource.get_slug_id(slug))


func queue_ability(ability_slug: String, order_slug: String, target: Variant) -> void:
	if !is_multiplayer_authority():
		return

	var ability_slug_id := AbilityResource.get_slug_id(ability_slug)
	var order_slug_id := OrderResource.get_slug_id(order_slug)
	_order_spawner.spawn([ability_slug_id, order_slug_id, target])


func ability_queue_start() -> void:
	if !is_multiplayer_authority():
		return

	var oldest := _get_order(0)
	if !oldest:
		return

	_use_ability.rpc(AbilityResource.get_slug_id(oldest.ability_slug), oldest.target)


func ability_queue_clear() -> void:
	if !is_multiplayer_authority():
		return

	for q in _orders.get_children():
		q.queue_free()


func ability_queue_pop() -> void:
	if !is_multiplayer_authority():
		return

	var oldest := _get_order(0)
	if !oldest:
		return

	oldest.queue_free()


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


func get_attribute_value(slug: String) -> float:
	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return 0

	return attribute.value


func get_attribute_min_value(slug: String) -> float:
	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return 0

	return attribute.min_value


func get_attribute_max_value(slug: String) -> float:
	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return 0

	return attribute.max_value


func increment_attribute_value(slug: String, delta: float) -> void:
	if !is_multiplayer_authority():
		return

	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	for ability: Ability in _abilities.values():
		delta = ability.before_attribute_increment(slug, delta)

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
	_order_spawner.set_spawn_function(_spawn_order)
	_attribute_spawner.set_spawn_function(_spawn_attribute)
	_attribute_spawner.despawned.connect(_despawn_attribute)

	if !is_multiplayer_authority():
		return

	_position_sync = position

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


func _physics_process(delta: float) -> void:
	var prevoius_impulse := _impulse
	velocity = _impulse + _get_ability_velocity()
	var collided := move_and_slide()
	# Don't fly up if hit a wall or something.
	if collided and _impulse.y > 0:
		_impulse.y = 0

	if is_on_floor() and _impulse.y <= _GRAVITY * delta:
		_impulse.y = 0
	else:
		_impulse.y -= _GRAVITY * delta

	var horizontal_impulse := Vector3(_impulse.x, 0, _impulse.z)
	if horizontal_impulse.length() <= _HORIZONTAL_DRAG * delta:
		_impulse.x = 0
		_impulse.z = 0
	else:
		horizontal_impulse -= horizontal_impulse.normalized() * _HORIZONTAL_DRAG * delta
		_impulse.x = horizontal_impulse.x
		_impulse.z = horizontal_impulse.z

	if !is_multiplayer_authority():
		return

	if prevoius_impulse != Vector3.ZERO and _impulse == Vector3.ZERO:
		# Stopped moving.
		_impulse_sync = _impulse
		_position_sync = position


# Only one ability is allowed to move unit at a time. Ability that was added earlier will
# have priority.
func _get_ability_velocity() -> Vector3:
	for a: Ability in _abilities.values():
		var v := a.get_unit_velocity()
		if v != Vector3.ZERO:
			return v

	return Vector3.ZERO


func _spawn_controller(key: PackedInt32Array) -> Controller:
	var slug_id := key[0]
	var authority_id := key[1]

	var slug := ControllerResource.get_slug(slug_id)
	var res: ControllerResource = load(ControllerResource.get_resource_path(slug))
	if !res:
		push_error("Can't find Controller with slug_id = %s" % slug_id)
		return

	var controller := Controller.new()
	controller.set_script(res.controller_script)
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

	if !is_multiplayer_authority():
		_controllers.erase(key)
		return

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

	var ability: Ability = Ability.new()
	ability.set_script(res.ability_script)
	ability.resource = res
	ability.spawn.connect(_on_spawn)
	ability.used.connect(_on_ability_used.bind(slug))

	_abilities[slug] = ability
	return ability


func _despawn_ability(ability: Ability) -> void:
	for slug: String in _abilities:
		if _abilities[slug] == ability:
			_remove_ability(slug)
			return


func _remove_ability(slug: String) -> void:
	if !is_multiplayer_authority():
		_abilities.erase(slug)
		return

	var ability: Ability = _abilities.get(slug)
	if !ability:
		return

	_abilities.erase(slug)
	ability.queue_free()
	for order: Order in _orders.get_children():
		if order.ability_slug == slug:
			order.queue_free()


@rpc("authority", "call_local", "reliable")
func _use_ability(ability_slug_id: int, target: Variant) -> void:
	var slug := AbilityResource.get_slug(ability_slug_id)
	var ability: Ability = _abilities.get(slug)
	if !ability:
		return

	ability.call_deferred("use", target)


@rpc("authority", "call_local", "reliable")
func _terminate_ability(slug_id: int) -> void:
	var slug := AbilityResource.get_slug(slug_id)
	var ability: Ability = _abilities.get(slug)
	if !ability:
		return

	ability.terminate()


func _on_spawn(node: Node) -> void:
	spawn.emit(node)


func _on_ability_used(_target: Variant, slug: String) -> void:
	if !is_multiplayer_authority():
		return

	_position_sync = position

	var oldest: Order = _get_order(0)
	var next: Order = _get_order(1)

	if !oldest:
		return

	if oldest.ability_slug != slug:
		return

	# Free immediately to avoid infinite loop if ability is done within one frame.
	oldest.free()

	if !next:
		return

	var ability: Ability = _abilities.get(next.ability_slug)
	if !ability:
		push_error("Ability form queue with slug = %s does not exist." % next.ability_slug)
		next.queue_free()
		return

	_use_ability.rpc(AbilityResource.get_slug_id(next.ability_slug), next.target)


func _get_order(index: int) -> Order:
	if _orders.get_child_count() <= index:
		return null

	return _orders.get_child(index)


func _get_last_order() -> Order:
	if _orders.get_child_count() == 0:
		return null
	return _get_order(_orders.get_child_count() - 1)


func _spawn_order(args: Array) -> Order:
	var ability_slug_id: int = args[0]
	var order_slug_id: int = args[1]
	var target: Variant = args[2]

	var order_slug := OrderResource.get_slug(order_slug_id)
	var ability_slug := AbilityResource.get_slug(ability_slug_id)
	var res: OrderResource = load(OrderResource.get_resource_path(order_slug))
	if !res:
		push_error("Can't find Order with slug_id =  %s" % order_slug)
		return

	var order := Order.new()
	order.set_script(res.order_script)
	order.spawn.connect(_on_spawn)

	var last_order := _get_last_order()
	if last_order:
		order.unit_position = last_order.get_next_unit_position()
	else:
		order.unit_position = global_position
	order.ability_slug = ability_slug
	order.resource = res
	order.target = target
	return order


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


func _despawn_attribute(attribute: Attribute) -> void:
	print(attribute)
	for slug: String in _attributes:
		if _attributes[slug] == attribute:
			_remove_attribute(slug)
			return


func _remove_attribute(slug: String) -> void:
	_ui.remove_bar(slug)

	if !is_multiplayer_authority():
		_attributes.erase(slug)
		return

	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	_attributes.erase(slug)
	attribute.queue_free()


func _on_attribute_changed(slug: String) -> void:
	var attribute: Attribute = _attributes.get(slug)
	if !attribute:
		return

	_ui.set_bar_progress(slug, attribute.value / attribute.max_value)
