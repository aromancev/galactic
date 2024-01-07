class_name ControllerPlayer
extends Controller


func _input(event: InputEvent) -> void:
	if !event.is_action_pressed("select_alt"):
		return

	var target := MissionCamera.get_active().get_cursor_projection()
	use_ability("navigate", TargetLocation.new(target))
