# Represents a running game instance. Contains everything related to the actual gameplay.
class_name Game
extends Node

@export var lobby: Control
@export var pause: Control
@export var replicator: Replicator
@export var world: World

func create() -> void:
    Session.create()

    world.bootstrap()

func load_latest() -> void:
    Session.create()

    replicator.set_model(Saver.load_latest_game().model)

func join(host: String) -> void:
    Session.join(host)

func _ready() -> void:
    Session.player_connected.connect(_on_player_connected)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        pause.visible = not pause.visible

func _on_pause_btn_pressed() -> void:
    pause.visible = not pause.visible

func _on_lobby_btn_pressed() -> void:
    lobby.visible = not lobby.visible

func _on_pause_menu_save_game() -> void:
    var game := SavedGame.new()
    game.model = replicator.get_model()
    Saver.save_game(game)
    pause.visible = false

func _on_pause_menu_quit_game() -> void:
    get_tree().quit()

func _on_player_connected(peer_id: int, _player: Player) -> void:
    replicator.send_model(peer_id)
