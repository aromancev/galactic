@tool
class_name AttributeBar
extends MeshInstance3D
"""
Represents a visual UI for a particular [Attribute] that [Unit] can have.
"""

@export var color_from: Color = Color.BLACK:
	get:
		return _get_shader_param("albedoFrom")
	set(v):
		_set_shader_param("albedoFrom", v)

@export var color_to: Color = Color.BLACK:
	get:
		return _get_shader_param("albedoTo")
	set(v):
		_set_shader_param("albedoTo", v)

@export var color_bg: Color = Color.BLACK:
	get:
		return _get_shader_param("albedoBG")
	set(v):
		_set_shader_param("albedoBG", v)

@export_range(0, 1) var progress: float = 0:
	get:
		return _get_shader_param("progress")
	set(v):
		_set_shader_param("progress", v)


static func from_attribute(attribute: Attribute) -> AttributeBar:
	var bar: AttributeBar = preload("res://game/mission/attribute_bar.tscn").instantiate()
	bar.color_bg = Color.GRAY
	bar.color_from = attribute.get_color()
	bar.color_to = attribute.get_color()
	bar.progress = attribute.value / attribute.max_value
	return bar


func get_height() -> float:
	return 0.1


func _get_shader_param(param: String) -> Variant:
	var material: ShaderMaterial = get_active_material(0)
	return material.get_shader_parameter(param)


func _set_shader_param(param: String, value: Variant) -> void:
	var material: ShaderMaterial = get_active_material(0)
	material.set_shader_parameter(param, value)
