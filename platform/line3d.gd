class_name Line3D
extends MeshInstance3D


func _init(points: PackedVector3Array, color: Color, no_depth_test: bool = false) -> void:
	var imesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	material.no_depth_test = no_depth_test
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	imesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for p in points:
		imesh.surface_add_vertex(p)
	imesh.surface_end()

	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = imesh
