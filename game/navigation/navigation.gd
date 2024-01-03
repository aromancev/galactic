# Represents navigation within a galaxy.
class_name Navigation
extends Node

@export var galaxy: Galaxy

func generate() -> void:
    galaxy.generate()
