# World represents everything that is changing while the game is running.
# Typically, game levels, charachters, or even persistent game data will be here.
class_name World
extends Node


func bootstrap() -> void:
	var navigation: Navigation = (
		(load("res://game/navigation/navigation.tscn") as PackedScene).instantiate()
	)
	add_child(navigation)
	navigation.generate()
