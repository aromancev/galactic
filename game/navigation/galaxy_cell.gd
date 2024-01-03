# Represents a cell on the navigation map. Has a node inside that is randomly placed within the
# cell. The position of the node does not affect the gameplay and is only for visual aesthetics.
class_name GalaxyCell
extends Node2D

signal selected

@export var node: GalaxyNode

var is_selected: bool = false:
	set(val):
		node.is_selected = val
var is_destination: bool = false:
	set(val):
		node.is_destination = val

var node_position := Vector2()
var neighbors: Array[GalaxyCell]


func jitter(rand: RandomNumberGenerator, j_min: float, j_max: float) -> void:
	var distance := rand.randf_range(j_min, j_max)
	var angle := rand.randf_range(0, 2 * PI)
	node.position = Vector2(
		distance * cos(angle),
		distance * sin(angle),
	)
	node_position = self.position + node.position


func _on_galaxy_node_selected() -> void:
	selected.emit()
