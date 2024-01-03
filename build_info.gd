class_name BuildInfo
extends Object

static var version: PackedInt32Array:
	get:
		return PackedInt32Array([0, 1, 0])


static func is_verion_compatible(compare: PackedInt32Array) -> bool:
	if compare[0] != version[0]:
		return false

	if compare[1] > version[1]:
		return false

	return true
