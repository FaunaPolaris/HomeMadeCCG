extends Node2D

## The map a new game opens on.
const STARTING_MAP := "res://scenes/maps/temple.tscn"

## Where the player stands in [constant STARTING_MAP] at the start of a new game.
const STARTING_CELL := Vector2i.ZERO

## The deck a player starts with before the save holds one of their own.
const STARTER_DECK := "res://resources/decks/starter_deck.json"


func _ready() -> void:
	var map_path := STARTING_MAP
	var player_cell := STARTING_CELL

	# Continue from the save if there is one, otherwise begin a new game.
	if SaveGame.load_from_disk() == OK and not SaveGame.current_map_path.is_empty():
		map_path = SaveGame.current_map_path
		player_cell = SaveGame.player_cell

	Global.current_map = load(map_path).instantiate()
	add_child(Global.current_map)
	SaveGame.restore(Global.current_map)

	var player : Entity = load("res://scenes/player.tscn").instantiate()
	player.map_position = player_cell
	Global.add_entity(player)
	Global.focus_entity(player)

	SaveGame.current_map_path = map_path
	SaveGame.player_cell = player_cell

	if SaveGame.player_deck.is_empty():
		SaveGame.player_deck = _read_decklist(STARTER_DECK)
	$player_deck.load_deck(SaveGame.player_deck)


func _read_decklist(path: String) -> Array:
	var json : JSON = load(path)
	if json == null or not json.data is Array:
		push_error("main: '%s' is not a decklist." % path)
		return []
	return json.data
