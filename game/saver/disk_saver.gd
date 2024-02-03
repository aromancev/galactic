# Implements saver for disk storage.
# Primary usage is for desktop clients.
#
# Each game save is represented by one file. Files are named using the pattern: [time]_[id]. The
# time format is lexicographically ordered. Since file names are returned in alphabetical order,
# this means save files are ordered by creation time and we don't need to actually read the files
# to get the latest, for example.
#
# The code itself SHOULD NOT know or rely on any specific time format. If you need to display save
# creation time in age, put it in the file itself.
class_name DiskSaver
extends Saver.Abstract

const _FILES_DIR = "user://save"
const _MAX_FILES_PER_ID = 1
const _MAX_FILES_TOTAL = 100
const _COMPRESSION = FileAccess.COMPRESSION_FASTLZ

var _current_id: UUID


func save_game(game: SavedGame) -> UUID:
	# Create a directory if it doesn't exist.
	DirAccess.make_dir_recursive_absolute(_FILES_DIR)

	if _current_id == null:
		_current_id = UUID.new()

	# Create a temporary file first.
	# If the game crushes while writing to this file, it will be discarded on `check_and_repair`.
	var tmp_path := _get_path("_" + _new_file_name(_current_id))
	var path := _get_path(_new_file_name(_current_id))
	var file := FileAccess.open_compressed(tmp_path, FileAccess.WRITE, _COMPRESSION)
	if FileAccess.get_open_error():
		return null

	# Write the file.
	file.store_var(BuildInfo.version)
	file.store_var(game.model)
	file.close()

	# File is fully written. Now it's safe to rename it.
	DirAccess.rename_absolute(tmp_path, path)

	# Remove the old save files if it exist. If the game crushes after renaming the new save but
	# before removing the old one, we'll have an extra save file. This is extremely unlikely though
	# and is better than potentially losing a save. The extra file will be cleaned up by
	# `check_and_repair` or `save_game`.
	_remove_extra_files(_current_id)
	return _current_id


func load_latest_game() -> SavedGame:
	var names := _read_file_names()
	if names.size() == 0:
		return null

	return load_game(_get_id(names[0]))


func load_game(id: UUID) -> SavedGame:
	if !id.is_valid():
		return null

	_current_id = id

	var f := FileAccess.open_compressed(
		_get_path(_read_latest_name(id)), FileAccess.READ, _COMPRESSION
	)
	if FileAccess.get_open_error():
		return null

	var game := SavedGame.new()
	game.version = f.get_var()
	if !BuildInfo.is_verion_compatible(game.version):
		return null

	game.id = id
	game.model = f.get_var()
	return game


func set_save_id(id: UUID) -> void:
	if !id.is_valid():
		return

	_current_id = id


func has_saves() -> bool:
	return _read_file_names().size() != 0


# Restores a valid file structure in the save directory. For example, after the game was closed or
# crashed while saving.
# Use once when the game starts.
func check_and_repair() -> void:
	# Create a directory if it doesn't exist.
	DirAccess.make_dir_recursive_absolute(_FILES_DIR)

	var total_count := 0
	var id_counts: Dictionary = {}
	var files := DirAccess.get_files_at(_FILES_DIR)
	files.reverse()  # Reverse the order to get the latest save first.
	for name in files:
		# Remove all extra files.
		if total_count > _MAX_FILES_TOTAL:
			DirAccess.remove_absolute(_get_path(name))
			continue

		# Unfinished files.
		if name.begins_with("_"):
			DirAccess.remove_absolute(_get_path(name))
			continue

		# Incorrect naming.
		var parts := name.split("_")
		if parts.size() != 2:
			DirAccess.remove_absolute(_get_path(name))
			continue

		# Too many files for the same id.
		var id_str := parts[1]
		var count := id_counts.get(id_str, 0) as int + 1
		if count > _MAX_FILES_PER_ID:
			DirAccess.remove_absolute(_get_path(name))
			continue

		id_counts[id_str] = count
		total_count += 1


func _read_latest_name(id: UUID) -> String:
	for name in _read_file_names():
		if _get_id(name).is_equal(id):
			return name

	return ""


func _remove_extra_files(id: UUID) -> void:
	var file_count := 0
	for name in _read_file_names():
		if id != _get_id(name):
			continue

		if file_count > _MAX_FILES_PER_ID:
			DirAccess.remove_absolute(_get_path(name))
		else:
			file_count += 1


func _read_file_names() -> PackedStringArray:
	var all_files := DirAccess.get_files_at(_FILES_DIR)
	var healthy_files := Array(all_files).filter(
		func(f: String) -> bool: return !f.begins_with("_") && f.count("_") == 1
	)
	healthy_files.reverse()  # Reverse the order to get the latest save first.
	return PackedStringArray(healthy_files)


func _get_path(name: String) -> String:
	return "%s/%s" % [_FILES_DIR, name]


func _get_id(name: String) -> UUID:
	return UUID.new(name.split("_")[1])


# This is the only method that should know about the specific time format. Other methods
# just assume this is a lexicographically ordered string.
# DO NOT spread this knowledge to other methods to be able to easily change it later.
func _new_file_name(id: UUID) -> String:
	return (
		"%s%03d_%s"
		% [
			# Trim symbols that can't be used in a file name.
			Time.get_datetime_string_from_system().replace(":", "").replace("T", ""),
			# Include milliseconds to avoid collisions of the name generated within the same
			# second.
			Time.get_ticks_msec() % 1000,
			id.to_string()
		]
	)
