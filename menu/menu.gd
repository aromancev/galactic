# Main menu of the game.
class_name Menu
extends Node

signal create(name: String)
signal load_latest(name: String)
signal join(name: String, address: String)

@export var player_name: LineEdit
@export var join_address: LineEdit
@export var load_latest_btn: Button


func _ready() -> void:
	if Saver.has_saves():
		load_latest_btn.visible = true


func _on_create_pressed() -> void:
	create.emit(player_name.text)


func _on_join_pressed() -> void:
	join.emit(player_name.text, join_address.text)


func _on_continue_pressed() -> void:
	load_latest.emit(player_name.text)
