class_name TargetLocation
extends Target

var location: Vector3


func _init(p_location: Vector3) -> void:
	location = p_location


static func from_bytes(data: PackedByteArray) -> TargetLocation:
	var p := BinaryPayload.decoded(data)
	return TargetLocation.new(p.get_var(1) as Vector3)


func to_bytes() -> PackedByteArray:
	var p := BinaryPayload.new()
	p.set_var(1, location)
	return p.encode()
