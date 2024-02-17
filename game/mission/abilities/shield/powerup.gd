class_name ShieldPowerup
extends Area3D

signal collected


func _on_body_entered(body: Node3D) -> void:
	if not body is Unit:
		return

	var unit: Unit = body
	unit.add_ability("shield")
	unit.set_attribute_value("shield", unit.get_attribute_max_value("shield"))
	if is_multiplayer_authority():
		queue_free()
		collected.emit()
