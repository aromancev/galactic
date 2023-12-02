# Represents a running game instance. Contains everything related to the actual gameplay (excluding main menu, extras, etc).
extends Node

const Player := preload("res://game/session/player.gd")

@export var lobby: Lobby
@export var navigation: Navigation

func create(player_name: String):
    # Initialize the game.
    navigation.generate()

    # Create a newtwork session.
    Session.local_player = Player.new()
    Session.local_player.name = player_name
    Session.create()

func join(host: String, player_name: String):
    Session.local_player = Player.new()
    Session.local_player.name = player_name
    Session.join(host)

func _on_chat_pressed():
    lobby.visible = not lobby.visible
