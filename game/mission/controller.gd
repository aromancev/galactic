class_name Controller
extends Node
"""
Represents a way to control [Unit] behaviour.

Each [Controller] is owned by a peer which can be different from [Unit] authority.
IMPORTANT: [Controller] should only tell what [Unit] WANTS to do but it doesn't define
what it CAN do. It MUST NOT define any new behaviour for a [Unit] like an [Ability] would.
"""


func get_unit() -> Unit:
	return get_parent()


# Uses unit ability on all clients.
# Always use this method instead of calling unit directly.
func use_ability(ability_slug: String, target: Variant) -> void:
	var authority := get_unit().get_multiplayer_authority()
	var ability_slug_id := AbilityResource.get_slug_id(ability_slug)
	_use_ability.rpc_id(authority, ability_slug_id, target)


# Pops unit ability on all clients.
# Always use this method instead of calling unit directly.
func ability_queue_pop() -> void:
	var authority := get_unit().get_multiplayer_authority()
	_ability_queue_pop.rpc_id(authority)


# Clears ability queue on all clients.
# Always use this method instead of calling unit directly.
func ability_queue_clear() -> void:
	var authority := get_unit().get_multiplayer_authority()
	_ability_queue_clear.rpc_id(authority)


func set_label(label: String) -> void:
	get_unit().label = label


func _ready() -> void:
	set_process(is_multiplayer_authority())
	set_process_input(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())


# It is important to call RPC on the [Controller] object and not on the [Unit] object because
# of multiplayer authority.
@rpc("authority", "call_local", "reliable")
func _use_ability(ability_slug_id: int, target: Variant) -> void:
	if !get_unit().is_multiplayer_authority():
		return

	var ability_slug := AbilityResource.get_slug(ability_slug_id)

	if get_unit().is_queueing_abilities:
		get_unit().queue_ability(ability_slug, target)
	else:
		get_unit().use_ability(ability_slug, target)


# It is important to call RPC on the [Controller] object and not on the [Unit] object because
# of multiplayer authority.
@rpc("authority", "call_local", "reliable")
func _ability_queue_pop() -> void:
	if !get_unit().is_multiplayer_authority():
		return

	if !get_unit().is_queueing_abilities:
		return

	get_unit().ability_queue_pop()


# It is important to call RPC on the [Controller] object and not on the [Unit] object because
# of multiplayer authority.
@rpc("authority", "call_local", "reliable")
func _ability_queue_clear() -> void:
	if !get_unit().is_multiplayer_authority():
		return

	if !get_unit().is_queueing_abilities:
		return

	get_unit().ability_queue_clear()
