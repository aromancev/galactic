extends Order


func _ready() -> void:
	super()

	if is_preparing:
		Input.set_custom_mouse_cursor(
			preload("res://game/mission/icons/target.png"), Input.CURSOR_ARROW, Vector2(16, 16)
		)
	else:
		var marker: Node3D = preload("res://game/mission/orders/shoot/target.tscn").instantiate()
		marker.position = target
		spawn.emit(marker)
		spawn.emit(Line3D.new([unit_position, target], Color.RED, true))


func _exit_tree() -> void:
	if is_preparing:
		Input.set_custom_mouse_cursor(null)

	super()


func _input(event: InputEvent) -> void:
	if !event.is_action_pressed("select"):
		return

	prepared.emit(MissionCamera.get_instance().get_cursor_projection_at(unit_position.y))
	get_viewport().set_input_as_handled()
