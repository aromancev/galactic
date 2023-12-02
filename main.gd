# Entry point of the game. Initiates all nodes.
extends Node

@export var menu: Menu

const Game := preload("res://game/game.tscn")

func _on_menu_create(player_name):
    remove_child(menu)

    var game := Game.instantiate()
    add_child(game)
    game.create(player_name)

func _on_menu_join(player_name, join_address):
    remove_child(menu)

    var game := Game.instantiate()
    add_child(game)
    game.join(join_address, player_name)
