extends Node2D

class_name Map

## Emitted when cells are revealed or hidden.
signal revealed_changed

@onready var	biome		: TileMapLayer = $biome
@onready var	prop		: TileMapLayer = $prop
@onready var	building	: TileMapLayer = $building

## The map as drawn in the editor: layer -> cell -> [source_id, atlas, alternative].
## This is the authority for what the map contains. The TileMapLayers themselves
## only ever hold the part of it the player has seen, so unexplored ground draws
## nothing at all and the background shows through.
var	_authored	: Dictionary = {}

## The area the authored map covers. Kept aside because the layers get emptied,
## which would otherwise shrink their used rect to whatever is currently visible.
var	_bounds		: Rect2i

## Cells the player has already seen. Used as a set; only the keys matter.
var	_revealed	: Dictionary = {}


func	_ready() -> void:
	_capture_authored_tiles()
	_warn_on_misaligned_layers()
	_warn_on_groundless_tiles()
	_erase_all_layers()


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


## True when the map was drawn with ground on [param cell].
## Reads what was authored, not what is currently visible, so passability does
## not depend on what the player has explored.
func	has_biome(cell : Vector2i) -> bool:
	return _cells_of(biome).has(cell)


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
## [param cell], drawing the tiles that were authored there. A range of 2
## reveals 5x5.
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


func	_layers() -> Array:
	return [biome, prop, building]


func	_cells_of(layer : TileMapLayer) -> Dictionary:
	return _authored.get(layer, {})


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
		_authored[layer] = cells
	_bounds = biome.get_used_rect()


func	_erase_all_layers() -> void:
	for layer : TileMapLayer in _layers():
		layer.clear()


## Draws whatever was authored on [param cell], across every layer.
func	_draw_cell(cell : Vector2i) -> void:
	for layer : TileMapLayer in _layers():
		var cells := _cells_of(layer)
		if not cells.has(cell):
			continue
		var tile : Array = cells[cell]
		layer.set_cell(cell, tile[0], tile[1], tile[2])


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
		for cell in _cells_of(layer):
			if not has_biome(cell):
				push_warning("Map: '%s' has a tile at %s with no biome under it." % [layer.name, cell])
