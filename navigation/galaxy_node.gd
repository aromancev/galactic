# Represents a particular destination within a cell.
class_name GalaxyNode
extends Node2D

signal selected

@export var collider: CollisionShape2D

const radius := 5
var is_selected: bool = false:
	set(val):
		is_selected = val
		queue_redraw()

var is_destination: bool = false:
	set(val):
		is_destination = val
		queue_redraw()

func _draw():
	var color := Color.YELLOW
	if is_destination:
		color = Color.BLUE
	if is_selected:
		color = Color.WHITE

	draw_circle(Vector2(), radius, color)

func _ready():
	collider.shape.radius = radius

func _on_collider_input_event(_viewport, event, _shape_idx):
	if not event.is_pressed() or event.button_index != MOUSE_BUTTON_LEFT:
		return

	selected.emit()
