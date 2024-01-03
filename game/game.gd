# Represents a running game instance. Contains everything related to the actual gameplay.
extends Node

const Player := preload("res://game/session/player.gd")

@export var lobby: Control
@export var pause: Control
@export var replicator: Replicator
@export var world: World

func create():
    Session.create()

    world.bootstrap()

func load_latest():
    Session.create()

    replicator.set_model(Saver.load_latest_game().model)

func join(host: String):
    Session.join(host)

func _ready():
    Session.player_connected.connect(_on_player_connected)

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        pause.visible = not pause.visible

func _on_pause_btn_pressed():
    pause.visible = not pause.visible

func _on_lobby_btn_pressed():
    lobby.visible = not lobby.visible

func _on_pause_menu_save_game():
    var game := SavedGame.new()
    game.model = replicator.get_model()
    Saver.save_game(game)
    pause.visible = false

func _on_pause_menu_quit_game():
    get_tree().quit()

func _on_player_connected(peer_id: int, _player: Player):
    replicator.send_model(peer_id)
