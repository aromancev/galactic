class_name UnitUI
extends Node3D
"""
Represents graphical display above [Unit].
"""

const _LABEL_HEIGHT = 0.3
const _UNIT_HEIGHT = 2.

@export var label: String:
	get:
		return _label.text
	set(v):
		_label.text = v

var _bars: Dictionary = {}

@onready var _label: Label3D = $Label


func add_bar(slug: String, bar: AttributeBar) -> void:
	_bars[slug] = bar
	add_child(bar)
	_update_positions()


func remove_bar(slug: String) -> void:
	var bar: AttributeBar = _bars.get(slug)
	if !bar:
		return

	bar.queue_free()
	_bars.erase(slug)
	_update_positions()


func set_bar_progress(slug: String, progress: float) -> void:
	var bar: AttributeBar = _bars.get(slug)
	if !bar:
		return

	bar.progress = progress


# TODO: Bar positions slide relative to one another because they are separate billboards.
func _update_positions() -> void:
	var pos := 0.0
	for bar: AttributeBar in _bars.values():
		bar.position.y = pos + bar.get_height() / 2
		pos += bar.get_height()

	_label.position.y = pos + _LABEL_HEIGHT / 2
	pos += _LABEL_HEIGHT
	position.y = _UNIT_HEIGHT
