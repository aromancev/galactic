class_name ControllerPlayer
extends Controller


func _input(event: InputEvent) -> void:
	if not event is UnitEvent:
		return

	var unit_event: UnitEvent = event
	if unit_event.unit_id != get_unit_id():
		return

	if event is AbilityUsedEvent:
		var e: AbilityUsedEvent = event
		use_ability(e.slug, e.target)

	elif event is AbilityQueueClearEvent:
		ability_queue_clear()


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
