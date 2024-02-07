class_name SluggedResource
extends Resource


func get_instance_slug() -> String:
	var parts := resource_path.split("/")
	if parts.size() < 2:
		return ""

	var dir_name := parts[parts.size() - 2]
	return dir_name
