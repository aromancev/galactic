# Main menu of the game.
class_name Menu
extends Node

@export var player_name: LineEdit
@export var join_address: LineEdit
@export var load_latest_btn: Button

signal create(name: String)
signal load_latest(name: String)
signal join(name: String, address: String)

func _ready():
    if Saver.has_saves():
        load_latest_btn.visible = true

func _on_create_pressed():
    create.emit(player_name.text)

func _on_join_pressed():
    join.emit(player_name.text, join_address.text)

func _on_continue_pressed():
    load_latest.emit(player_name.text)
