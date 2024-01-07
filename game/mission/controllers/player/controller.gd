class_name ControllerPlayer
extends Controller

@onready var _name: Label3D = $Name


func _input(event: InputEvent) -> void:
	if !event.is_action_pressed("select_alt"):
		return

	var target := MissionCamera.get_active().get_cursor_projection()
	use_ability("navigate", TargetLocation.new(target))


func _ready() -> void:
	super()

	Session.player_connected.connect(_on_player_joined)
	var player := Session.get_player(get_multiplayer_authority())
	if !player:
		return
	_name.text = player.name


func _on_player_joined(peer_id: int, player: Player) -> void:
	if peer_id != get_multiplayer_authority():
		return

	_name.text = player.name
