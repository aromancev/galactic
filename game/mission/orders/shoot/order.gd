extends Order


func _ready() -> void:
	super()

	var marker: Node3D = preload("res://game/mission/orders/shoot/target.tscn").instantiate()
	marker.position = target
	spawn.emit(marker)
	spawn.emit(Line3D.new([unit_position, target], Color.RED, true))
