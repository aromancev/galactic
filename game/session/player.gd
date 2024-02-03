# Info about a player in network session.
class_name Player
extends RefCounted

var name: String


static func from_bytes(bin: PackedByteArray) -> Player:
	var payload := BinaryPayload.decoded(bin)
	var player := Player.new()
	player.name = payload.get_var(1)
	return player


func to_bytes() -> PackedByteArray:
	var payload := BinaryPayload.new()
	payload.set_var(1, name)
	return payload.encode()
