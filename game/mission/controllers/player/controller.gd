class_name ControllerPlayer
extends Controller


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select_alt"):
		var target := MissionCamera.get_active().get_cursor_projection()
		use_ability("navigate", TargetLocation.new(target))

	if event.is_action_pressed("select"):
		pass


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
