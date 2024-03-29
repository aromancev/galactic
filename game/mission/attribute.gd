class_name Attribute
extends MultiplayerSynchronizer
"""
Represents a changing value sucn as health or speed
"""

signal changed

@export var resource: AttributeResource = AttributeResource.new():
	get:
		return resource
	set(v):
		resource = v
		min_value = v.min_value
		max_value = v.max_value
		value = v.value

@export var value: float:
	get:
		return value
	set(v):
		value = clamp(v, min_value, max_value)

@export var min_value: float
@export var max_value: float


func get_attribute_name() -> String:
	return resource.name


func display_bar() -> bool:
	return resource.display_bar


func get_color() -> Color:
	return resource.color


func _on_delta_synchronized() -> void:
	changed.emit()


func _on_synchronized() -> void:
	changed.emit()
