# Menu with chat and player info. Available at any point in the game as a menu.
class_name Lobby
extends Node

@export var player_list: Node
@export var messages: Node
@export var messages_scroll: ScrollContainer
@export var input: TextEdit

func _ready() -> void:
    Session.player_connected.connect(_update_players)
    Session.player_disconnected.connect(_update_players)

@rpc("any_peer", "call_local", "reliable")
func _add_message(text: String) -> void:
    var player: Player = Session.players[multiplayer.get_remote_sender_id()]
    var l := Label.new()
    l.text = "[%s] %s" % [player.name, text]
    messages.add_child(l)
    var bar := messages_scroll.get_v_scroll_bar()
    
    await RenderingServer.frame_pre_draw
    bar.value = bar.max_value

func _update_players(_peer_id: int, _player: Player) -> void:
    for c in player_list.get_children():
        player_list.remove_child(c)
        c.queue_free()

    for p: Player in Session.players.values():
        var l := Label.new()
        l.text = p.name
        player_list.add_child(l)

func _input(event: InputEvent) -> void:
    if not event.is_pressed():
        return

    if not (event is InputEventKey):
        return

    var event_key: InputEventKey = event
    if event_key.keycode != KEY_ENTER:
        return

    if not input.has_focus():
        return

    get_tree().get_root().set_input_as_handled()
    _add_message.rpc(input.text)
    input.clear()
