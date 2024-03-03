class_name SluggedResource
extends Resource


# Returns slug string uniquely identifying the resource IF the resource was loaded from disk.
func get_instance_slug() -> String:
	var parts := resource_path.split("/")
	if parts.size() < 2:
		return ""

	var dir_name := parts[parts.size() - 2]
	return dir_name
