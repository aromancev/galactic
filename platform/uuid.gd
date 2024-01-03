# UUID Implements UUID v4 specification: https://datatracker.ietf.org/doc/html/rfc4122
# Or a more didjastable explanation:
# https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_(random)
class_name UUID
extends RefCounted

var _data: PackedByteArray


func is_valid() -> bool:
	# Check length, version, and variant bits.
	return _data.size() == 16 and _data[6] & 0xf0 == 0x40 and _data[8] & 0xc0 == 0x80


func is_equal(other: UUID) -> bool:
	return _data == other._data


func _init(from: Variant = null) -> void:
	if from is PackedByteArray:
		_data = from
	elif from is String:
		_data = (from as String).replace("-", "").hex_decode()
	elif from is UUID:
		_data = PackedByteArray((from as UUID)._data)
	elif from == null:
		_data = Crypto.new().generate_random_bytes(16)
		# Set version and variant bits.
		_data[6] = (_data[6] & 0x0f) | 0x40
		_data[8] = (_data[8] & 0x3f) | 0x80
	else:
		assert(false, "UUID can only be created from UUID, String, or PackedByteArray.")


func _to_string() -> String:
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % (_data as Array)
