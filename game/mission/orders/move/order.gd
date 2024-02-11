extends Order


func get_next_unit_position() -> Vector3:
	return target


func _ready() -> void:
	super()

	var marker: Node3D = preload("res://game/mission/orders/move/target.tscn").instantiate()
	marker.position = target
	spawn.emit(marker)
	spawn.emit(Line3D.new([unit_position, target], Color.BLUE, true))
