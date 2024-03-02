extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if not body is Unit:
		return

	var unit: Unit = body
	unit.add_impulse(-global_basis.z * 15)
