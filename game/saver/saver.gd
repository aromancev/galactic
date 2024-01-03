# Manipulates and controls game saves.
# Can have multiple implementations (e.g. clients may want to save to disk and dedicated server to
# cloud object storage). Game saves are identified by an ID. Essentially this ID is a game session
# (a new "run"). There can only be one save file per session (because roguelike, duh).
extends Node

var instance: Abstract


# Abstract is what any specific saver should implement.
class Abstract:
	func has_saves() -> bool:
		return false

	func save_game(_game: SavedGame) -> UUID:
		return null

	func load_game(_id: UUID) -> SavedGame:
		return null

	func load_latest_game() -> SavedGame:
		return null

	func set_save_id(_id: UUID) -> void:
		pass


# Returns true if there are any saved games.
func has_saves() -> bool:
	return instance.has_saves()


# Saves the game and returns save id.
# If no ID is set, creates a new one and remembers it.
# If ID is set, overrides it.
func save_game(game: SavedGame) -> UUID:
	return instance.save_game(game)


# Loads game with a specific ID.
# Future saves will override this ID.
# If no such save exists, returns null.
func load_game(id: UUID) -> SavedGame:
	return instance.load_game(id)


# Loads latest available game.
# Future saves will override the ID of the loaded one.
# If no saves exist, returns null.
func load_latest_game() -> SavedGame:
	return instance.load_latest_game()


# Sets the ID. Useful to synchronize saves across multiple clients.
func set_save_id(id: UUID) -> void:
	return instance.set_save_id(id)
