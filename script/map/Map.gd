extends Node2D

class_name Map

## Emitted when cells are revealed or hidden, so the fog can redraw.
signal revealed_changed

@onready var	biome		: TileMapLayer = $biome
@onready var	prop		: TileMapLayer = $prop
@onready var	building	: TileMapLayer = $building

## Cells the player has already seen. Used as a set; only the keys matter.
var	_revealed	: Dictionary = {}


func	_ready() -> void:
	_warn_on_misaligned_layers()
	_warn_on_groundless_tiles()


## True when an entity is allowed to stand on [param cell].
## A cell with no biome drawn on it is off the map, so nothing can be there.
func	can_enter(cell : Vector2i) -> bool:
	return has_biome(cell)


## True when [param cell] has ground drawn on the biome layer.
func	has_biome(cell : Vector2i) -> bool:
	return biome.get_cell_source_id(cell) != -1


## The rectangle of cells the map covers, taken from the drawn biome.
func	get_bounds() -> Rect2i:
	return biome.get_used_rect()


## Where [param cell] sits in the map's own space.
## Entities stand on the center of a cell, so the rect is centered on that point.
func	cell_rect(cell : Vector2i) -> Rect2:
	var size := Vector2.ONE * Global.TILE_SIZE
	return Rect2(Vector2(cell) * Global.TILE_SIZE - size * 0.5, size)


## True once [param cell] has been seen. Revealed cells stay revealed.
func	is_revealed(cell : Vector2i) -> bool:
	return _revealed.has(cell)


## Reveals the square of side [code]vision_range * 2 + 1[/code] centered on
## [param cell]. A range of 2 reveals 5x5.
func	reveal_around(cell : Vector2i, vision_range : int) -> void:
	var changed := false
	for x in range(cell.x - vision_range, cell.x + vision_range + 1):
		for y in range(cell.y - vision_range, cell.y + vision_range + 1):
			var seen := Vector2i(x, y)
			if not _revealed.has(seen):
				_revealed[seen] = true
				changed = true
	if changed:
		revealed_changed.emit()


## Puts the whole map back under fog. The "until otherwise stated" hook.
func	hide_all() -> void:
	if _revealed.is_empty():
		return
	_revealed.clear()
	revealed_changed.emit()


## How many cells have been revealed so far.
func	revealed_count() -> int:
	return _revealed.size()


## A layer that is not centered on the cell grid would put its tiles half a cell
## away from where entities stand, so say so loudly instead of drifting quietly.
func	_warn_on_misaligned_layers() -> void:
	var expected := -Vector2.ONE * Global.TILE_SIZE * 0.5
	for layer : TileMapLayer in [biome, prop, building]:
		if not layer.position.is_equal_approx(expected):
			push_warning("Map: layer '%s' sits at %s, expected %s. Its tiles will not line up with entity coordinates." % [layer.name, layer.position, expected])


## Props and buildings need biome under them, same as entities do.
func	_warn_on_groundless_tiles() -> void:
	for layer : TileMapLayer in [prop, building]:
		for cell in layer.get_used_cells():
			if not has_biome(cell):
				push_warning("Map: '%s' has a tile at %s with no biome under it." % [layer.name, cell])
