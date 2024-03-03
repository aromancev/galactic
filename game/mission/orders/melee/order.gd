extends Order


func get_next_unit_position() -> Vector3:
	var unit := Unit.get_unit(target as int)
	if unit:
		return unit.global_position

	return unit_position


func _ready() -> void:
	super()

	if is_preparing:
		Input.set_custom_mouse_cursor(
			preload("res://game/mission/icons/target.png"), Input.CURSOR_ARROW, Vector2(16, 16)
		)
	else:
		var pos := get_next_unit_position()
		var marker: Node3D = preload("res://game/mission/orders/melee/target.tscn").instantiate()
		marker.position = pos
		spawn.emit(marker)
		spawn.emit(Line3D.new([unit_position, pos], Color.GREEN, true))


func _exit_tree() -> void:
	if is_preparing:
		Input.set_custom_mouse_cursor(null)

	super()


func _input(event: InputEvent) -> void:
	if !event.is_action_pressed("select"):
		return

	var unit := MissionCamera.get_instance().get_unit_cursor_projection()
	if unit == null:
		return

	prepared.emit(unit.id)
	get_viewport().set_input_as_handled()
