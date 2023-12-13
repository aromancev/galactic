# Main menu of the game.
class_name Menu
extends Node

@export var player_name: LineEdit
@export var join_address: LineEdit

signal create(name: String)
signal join(name: String, address: String)

func _on_create_pressed():
    create.emit(player_name.text)

func _on_join_pressed():
    join.emit(player_name.text, join_address.text)
