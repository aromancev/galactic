extends Control

signal save_game
signal quit_game


func _on_save_pressed() -> void:
	save_game.emit()


func _on_quit_pressed() -> void:
	quit_game.emit()
