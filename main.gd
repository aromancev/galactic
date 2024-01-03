# Entry point of the game. Initiates all nodes.
# This is the only script that should be different for different platforms (e.g. dedicated server or client).
extends Node

@export var menu: Menu

const _game_scene = "res://game/game.tscn"

func _init() -> void:
    var saver := DiskSaver.new()
    saver.check_and_repair()
    Saver.instance = saver

func _on_menu_create(player_name: String) -> void:
    remove_child(menu)
    menu.queue_free()

    var player := Player.new()
    player.name = player_name
    Session.local_player = player
    var game: Game = (load(_game_scene) as PackedScene).instantiate()
    add_child(game)
    game.create()

func _on_menu_join(player_name: String, join_address: String) -> void:
    remove_child(menu)
    menu.queue_free()

    var player := Player.new()
    player.name = player_name
    Session.local_player = player
    var game: Game = (load(_game_scene) as PackedScene).instantiate()
    add_child(game)
    game.join(join_address)

func _on_menu_load_latest(player_name: String) -> void:
    remove_child(menu)
    menu.queue_free()

    var player := Player.new()
    player.name = player_name
    Session.local_player = player
    var game: Game = (load(_game_scene) as PackedScene).instantiate()
    add_child(game)
    game.load_latest()
