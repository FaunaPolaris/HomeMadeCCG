extends Node

## Holds what the player has done to every map they have visited, and writes it
## somewhere the same file can be read back on any platform.
##
## Format is plain JSON so it stays portable: the same save opens on Windows,
## Linux and Android, and a cloud sync can carry the file across without
## translating it. Nothing platform-specific — no absolute paths, no binary
## layout that depends on word size or endianness.
##
## [code]user://[/code] is the correct home for it on every target. Godot resolves
## it to %APPDATA% on Windows, ~/.local/share on Linux and the app's private
## storage on Android, which is also the path a Steam Auto-Cloud rule should point
## at per OS.

## Bumped whenever the on-disk layout changes, so an old file can be recognised
## rather than silently misread.
const FORMAT_VERSION := 1

const SAVE_PATH := "user://save.json"

## Written next to the real file and renamed over it, so a crash midway through
## saving cannot leave a half-written save behind.
const TEMP_PATH := "user://save.json.part"

## Scene path of the map the player was on.
var	current_map_path	: String = ""

## Cell the player was standing on.
var	player_cell			: Vector2i = Vector2i.ZERO

## The cards in the player's deck, as the JSON-safe dictionaries
## [method Card.to_data] makes. Empty means "not dealt yet" — the game
## seeds it from the starter decklist.
var	player_deck			: Array = []

## map id (its scene path) -> that map's state, as returned by [method Map.capture_state].
var	_maps				: Dictionary = {}


## Stores [param map]'s current state, replacing anything held for it.
func	remember(map : Map) -> void:
	if map == null:
		return
	var id := map.get_map_id()
	if id.is_empty():
		return
	_maps[id] = map.capture_state()


## Puts back whatever was stored for [param map]. Does nothing on a first visit,
## which correctly leaves the map unexplored.
func	restore(map : Map) -> void:
	if map == null:
		return
	var id := map.get_map_id()
	if _maps.has(id):
		map.apply_state(_maps[id])


## True when this map has been visited before.
func	has_state(map_id : String) -> bool:
	return _maps.has(map_id)


## Forgets everything held in memory. Used by a new game.
func	clear() -> void:
	_maps.clear()
	current_map_path = ""
	player_cell = Vector2i.ZERO
	player_deck = []
	Calendar.days_passed = 0


## Forgets everything and deletes the save from disk, leaving nothing for the
## next launch to continue from. Clearing memory alone would not be enough — the
## next map change would just write the old state back out.
func	discard() -> void:
	clear()
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveGame: could not open user:// to delete the save.")
		return
	for path : String in [SAVE_PATH, TEMP_PATH]:
		var file_name := path.get_file()
		if dir.file_exists(file_name):
			var err := dir.remove(file_name)
			if err != OK:
				push_error("SaveGame: could not delete %s (error %d)." % [path, err])


## True when there is a save on disk to continue from.
func	save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func	save_to_disk() -> Error:
	var payload := {
		"version": FORMAT_VERSION,
		"current_map": current_map_path,
		"player_cell": cell_to_key(player_cell),
		"days_passed": Calendar.days_passed,
		"deck": player_deck,
		"maps": _maps,
	}
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		push_error("SaveGame: could not open %s for writing (error %d)." % [TEMP_PATH, err])
		return err
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	# Rename over the real file only once the new one is complete on disk.
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveGame: could not open user:// to finish the save.")
		return ERR_FILE_CANT_OPEN
	if dir.file_exists(SAVE_PATH.get_file()):
		dir.remove(SAVE_PATH.get_file())
	var err := dir.rename(TEMP_PATH.get_file(), SAVE_PATH.get_file())
	if err != OK:
		push_error("SaveGame: could not put the finished save in place (error %d)." % err)
	return err


func	load_from_disk() -> Error:
	if not save_exists():
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var open_err := FileAccess.get_open_error()
		push_error("SaveGame: could not open %s (error %d)." % [SAVE_PATH, open_err])
		return open_err
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveGame: %s is not valid save data; ignoring it." % SAVE_PATH)
		return ERR_PARSE_ERROR

	var version := int(parsed.get("version", 0))
	if version != FORMAT_VERSION:
		push_warning("SaveGame: save is format %d, this build reads %d. Ignoring it rather than guessing." % [version, FORMAT_VERSION])
		return ERR_INVALID_DATA

	current_map_path = String(parsed.get("current_map", ""))
	player_cell = key_to_cell(String(parsed.get("player_cell", "0,0")))
	# Saves from before the calendar existed simply start on the first day.
	Calendar.days_passed = int(parsed.get("days_passed", 0))
	# Saves from before the deck existed simply have no "deck" key; an
	# empty deck makes the game deal the starter decklist again.
	var deck : Variant = parsed.get("deck", [])
	player_deck = deck if deck is Array else []
	_maps = parsed.get("maps", {})
	return OK


## Cells are dictionary keys in the save, and JSON keys have to be strings.
static func	cell_to_key(cell : Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func	key_to_cell(key : String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		push_warning("SaveGame: '%s' is not a cell key." % key)
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
