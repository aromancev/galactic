class_name Agent
extends Node3D

@export var tree: AnimationTree
@export var default_animation: StringName = "idle"

@onready var _state_machine: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")


func play(animation: StringName) -> void:
	_state_machine.travel(animation)


func reset() -> void:
	_state_machine.travel(default_animation)


func set_speed(animation: StringName, speed: float) -> void:
	tree.set("parameters/%s/TimeScale/scale" % animation, speed)
