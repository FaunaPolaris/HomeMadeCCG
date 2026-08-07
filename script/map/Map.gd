extends Node2D

class_name Map

## Emitted when cells are revealed or hidden.
signal revealed_changed

@onready var	biome		: TileMapLayer = $biome
@onready var	prop		: TileMapLayer = $prop
@onready var	building	: TileMapLayer = $building

## The map as drawn in the editor: layer name -> cell -> [source_id, atlas, alternative].
## The TileMapLayers themselves only ever hold the part the player has seen, so
## unexplored ground draws nothing and the background shows through.
var	_authored	: Dictionary = {}

## What the player has changed since, on top of [member _authored].
## layer name -> cell -> tile array, or null where the player removed a tile.
## This is the part that goes into a save; the authored map comes from the scene.
var	_changes	: Dictionary = {}

## The area the authored map covers. Kept aside because the layers get emptied,
## which would otherwise shrink their used rect to whatever is currently visible.
var	_bounds		: Rect2i

## Cells the player has already seen. Used as a set; only the keys matter.
var	_revealed	: Dictionary = {}


func	_ready() -> void:
	_capture_authored_tiles()
	_warn_on_misaligned_layers()
	_warn_on_groundless_tiles()
	_warn_on_broken_transitions()
	_erase_all_layers()


## Identifies this map in save data.
##
## The scene path is used because it is already unique and needs no upkeep — no
## registry to maintain and no ids to keep from colliding. Renaming a map scene
## does orphan its saved state, which is worth knowing before renaming one.
func	get_map_id() -> String:
	if scene_file_path.is_empty():
		push_warning("Map: this map was not loaded from a scene file, so its state cannot be saved.")
	return scene_file_path


## True when an entity is allowed to stand on [param cell].
## A cell with no biome drawn on it is off the map, and a cell already taken is
## full — one entity per cell. [param mover] is the entity asking, so that it
## never counts as blocking itself.
##
## Props and buildings deliberately do not block: walking onto them is how you
## interact with them. Unexplored cells do not block either — walking into the
## dark is how you reveal it.
func	can_enter(cell : Vector2i, mover : Entity = null) -> bool:
	if not has_biome(cell):
		return false
	var occupant := entity_at(cell)
	return occupant == null or occupant == mover


## True when there is ground on [param cell].
## Reads the map's content rather than what is currently drawn, so passability
## does not depend on what the player has explored.
func	has_biome(cell : Vector2i) -> bool:
	return not tile_at(&"biome", cell).is_empty()


## The entity standing on [param cell], or null when the cell is free.
##
## This walks the map's children rather than keeping an index of cells, so it
## cannot go stale when an entity is placed by assigning map_position directly.
## Worth turning into an index if entity counts ever get large.
func	entity_at(cell : Vector2i) -> Entity:
	for child in get_children():
		var entity := child as Entity
		if entity != null and entity.map_position == cell:
			return entity
	return null


## The doorway on [param cell], or null when there is none.
func	transition_at(cell : Vector2i) -> MapTransition:
	for child in get_children():
		var transition := child as MapTransition
		if transition != null and transition.cell == cell:
			return transition
	return null


## The rectangle of cells the authored map covers.
func	get_bounds() -> Rect2i:
	return _bounds


## Where [param cell] sits in the map's own space.
## Entities stand on the center of a cell, so the rect is centered on that point.
func	cell_rect(cell : Vector2i) -> Rect2:
	var size := Vector2.ONE * Global.TILE_SIZE
	return Rect2(Vector2(cell) * Global.TILE_SIZE - size * 0.5, size)


## True once [param cell] has been seen. Revealed cells stay revealed.
func	is_revealed(cell : Vector2i) -> bool:
	return _revealed.has(cell)


## Reveals the square of side [code]vision_range * 2 + 1[/code] centered on
## [param cell], drawing what is there. A range of 2 reveals 5x5.
func	reveal_around(cell : Vector2i, vision_range : int) -> void:
	var changed := false
	for x in range(cell.x - vision_range, cell.x + vision_range + 1):
		for y in range(cell.y - vision_range, cell.y + vision_range + 1):
			var seen := Vector2i(x, y)
			if _revealed.has(seen):
				continue
			_revealed[seen] = true
			_draw_cell(seen)
			changed = true
	if changed:
		refresh_entity_visibility()
		revealed_changed.emit()


## Puts the whole map back under fog. The "until otherwise stated" hook.
func	hide_all() -> void:
	if _revealed.is_empty():
		return
	_revealed.clear()
	_erase_all_layers()
	refresh_entity_visibility()
	revealed_changed.emit()


## How many cells have been revealed so far.
func	revealed_count() -> int:
	return _revealed.size()


## Hides entities standing on cells the player has not seen, so an unexplored
## area gives nothing away.
func	refresh_entity_visibility() -> void:
	for child in get_children():
		var entity := child as Entity
		if entity != null:
			entity.visible = is_revealed(entity.map_position)


## What is on [param cell] of [param layer_name]: the player's change if there is
## one, otherwise what the map was drawn with. Empty array means nothing there.
func	tile_at(layer_name : StringName, cell : Vector2i) -> Array:
	var changed : Dictionary = _changes.get(layer_name, {})
	if changed.has(cell):
		var tile = changed[cell]
		return [] if tile == null else tile
	return (_authored.get(layer_name, {}) as Dictionary).get(cell, [])


## Puts a tile on [param cell] and remembers it as a player change, so it
## survives leaving the map and coming back.
func	change_tile(layer_name : StringName, cell : Vector2i, source_id : int, atlas_coords : Vector2i, alternative : int = 0) -> void:
	_record_change(layer_name, cell, [source_id, atlas_coords, alternative])


## Takes whatever is on [param cell] away and remembers the removal. This is what
## collecting a prop will do.
func	remove_tile(layer_name : StringName, cell : Vector2i) -> void:
	_record_change(layer_name, cell, null)


## Everything about this map worth saving. JSON-safe: no Vector2i, no objects.
## The authored map is not included — that lives in the scene file.
func	capture_state() -> Dictionary:
	var revealed : Array = []
	for cell in _revealed:
		revealed.append(SaveGame.cell_to_key(cell))

	var changes := {}
	for layer_name in _changes:
		var cells := {}
		for cell in _changes[layer_name]:
			cells[SaveGame.cell_to_key(cell)] = _tile_to_json(_changes[layer_name][cell])
		changes[String(layer_name)] = cells

	return {"revealed": revealed, "changes": changes}


## Puts back a state produced by [method capture_state] and redraws to match.
func	apply_state(state : Dictionary) -> void:
	_changes.clear()
	var saved_changes : Dictionary = state.get("changes", {})
	for layer_name in saved_changes:
		var cells := {}
		for key in saved_changes[layer_name]:
			cells[SaveGame.key_to_cell(String(key))] = _tile_from_json(saved_changes[layer_name][key])
		_changes[StringName(layer_name)] = cells

	_revealed.clear()
	for key in state.get("revealed", []):
		_revealed[SaveGame.key_to_cell(String(key))] = true

	_erase_all_layers()
	for cell in _revealed:
		_draw_cell(cell)
	refresh_entity_visibility()
	revealed_changed.emit()


func	_record_change(layer_name : StringName, cell : Vector2i, tile) -> void:
	if _layer_named(layer_name) == null:
		push_error("Map: there is no layer called '%s'." % layer_name)
		return
	if not _changes.has(layer_name):
		_changes[layer_name] = {}
	_changes[layer_name][cell] = tile
	if is_revealed(cell):
		_draw_cell(cell)


func	_layers() -> Array:
	return [biome, prop, building]


func	_layer_named(layer_name : StringName) -> TileMapLayer:
	for layer : TileMapLayer in _layers():
		if layer.name == layer_name:
			return layer
	return null


## Copies what was drawn in the editor out of the layers, so they are free to be
## used as the render target for the explored part of the map.
func	_capture_authored_tiles() -> void:
	for layer : TileMapLayer in _layers():
		var cells := {}
		for cell in layer.get_used_cells():
			cells[cell] = [
				layer.get_cell_source_id(cell),
				layer.get_cell_atlas_coords(cell),
				layer.get_cell_alternative_tile(cell),
			]
		_authored[layer.name] = cells
	_bounds = biome.get_used_rect()


func	_erase_all_layers() -> void:
	for layer : TileMapLayer in _layers():
		layer.clear()


## Draws whatever belongs on [param cell], across every layer.
func	_draw_cell(cell : Vector2i) -> void:
	for layer : TileMapLayer in _layers():
		var tile := tile_at(layer.name, cell)
		if tile.is_empty():
			layer.erase_cell(cell)
		else:
			layer.set_cell(cell, tile[0], tile[1], tile[2])


static func	_tile_to_json(tile) -> Variant:
	if tile == null:
		return null
	var atlas : Vector2i = tile[1]
	return [tile[0], atlas.x, atlas.y, tile[2]]


static func	_tile_from_json(data) -> Variant:
	if data == null:
		return null
	return [int(data[0]), Vector2i(int(data[1]), int(data[2])), int(data[3])]


## A layer that is not centered on the cell grid would put its tiles half a cell
## away from where entities stand, so say so loudly instead of drifting quietly.
func	_warn_on_misaligned_layers() -> void:
	var expected := -Vector2.ONE * Global.TILE_SIZE * 0.5
	for layer : TileMapLayer in _layers():
		if not layer.position.is_equal_approx(expected):
			push_warning("Map: layer '%s' sits at %s, expected %s. Its tiles will not line up with entity coordinates." % [layer.name, layer.position, expected])


## Props and buildings need biome under them, same as entities do.
func	_warn_on_groundless_tiles() -> void:
	for layer : TileMapLayer in [prop, building]:
		for cell in (_authored.get(layer.name, {}) as Dictionary):
			if not has_biome(cell):
				push_warning("Map: '%s' has a tile at %s with no biome under it." % [layer.name, cell])


## Every building is a doorway, so a building without a MapTransition is a door
## that goes nowhere, and a MapTransition without a building is a door you cannot
## see. Both are almost certainly mistakes while drawing.
func	_warn_on_broken_transitions() -> void:
	var buildings : Dictionary = _authored.get(&"building", {})
	for cell in buildings:
		if transition_at(cell) == null:
			push_warning("Map '%s': building at %s has no MapTransition, so it leads nowhere." % [name, cell])
	for child in get_children():
		var transition := child as MapTransition
		if transition == null:
			continue
		if not buildings.has(transition.cell):
			push_warning("Map '%s': MapTransition '%s' is on %s, where no building is drawn." % [name, transition.name, transition.cell])
		if not transition.is_valid():
			push_warning("Map '%s': MapTransition '%s' points at '%s', which does not exist." % [name, transition.name, transition.destination])
