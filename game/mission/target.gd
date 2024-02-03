class_name Target
extends RefCounted
"""
Represents configuration parameters to use a [Ability]. Most of the time it would be a target
like location or unit. Different abilities can create new targets or reuse others.

All extending classes MUST override [method Target.from_bytes] and [method Target.to_bytes]
which are used to pass targets via RPCs. The recommeded encoding is via [BinaryPayload].
"""


static func from_bytes(_data: PackedByteArray) -> Target:
	return Target.new()


func to_bytes() -> PackedByteArray:
	return PackedByteArray()
