class_name Controller
extends Node3D
"""
Represents a way to control [Unit] behaviour.

Each [Controller] is owned by a peer which can be different from [Unit] authority.
IMPORTANT: [Controller] should only tell what [Unit] WANTS to do but it doesn't define
what it CAN do. It MUST NOT define any new behaviour for a [Unit] like an [Ability] would.
"""


func use_ability(slug: String, target: Target) -> void:
	_use_ability.rpc(AbilityResource.get_slug_id(slug), target.to_bytes())


func set_label(label: String) -> void:
	_get_unit().label = label


func _ready() -> void:
	set_process(is_multiplayer_authority())
	set_process_input(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())


func _get_unit() -> Unit:
	return get_parent()


# It is important to call RPC on the [Controller] object and not on the [Unit] object because
# of multiplayer authority.
@rpc("authority", "call_local", "reliable")
func _use_ability(slug_id: int, target: PackedByteArray) -> void:
	# Calling a private method because other ways to prevent undesired [Unit] calls are even more
	# ugly (like creating proxy objects).
	# gdlint:ignore = private-method-call
	_get_unit()._use_ability(slug_id, target)
