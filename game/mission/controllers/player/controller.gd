class_name ControllerPlayer
extends Controller


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select_alt"):
		var target: Variant = MissionCamera.get_active().get_level_cursor_projection()
		if target == null:
			return
		use_ability("navigate", TargetLocation.new(target as Vector3))

	if event.is_action_pressed("select"):
		var target := MissionCamera.get_active().get_cursor_projection_at(0)
		use_ability("shoot", TargetLocation.new(target))


func _ready() -> void:
	super()

	Session.player_connected.connect(_on_player_joined)
	var player := Session.get_player(get_multiplayer_authority())
	if !player:
		return

	set_label(player.name)


func _on_player_joined(peer_id: int, player: Player) -> void:
	if peer_id != get_multiplayer_authority():
		return

	set_label(player.name)
