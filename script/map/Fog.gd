extends Node2D

class_name Fog

## Colour of a cell the player has not seen yet.
## Flat rectangles are a placeholder until there is fog art to draw instead.
const UNSEEN_COLOR := Color(0.03, 0.028, 0.07)

@onready var	_map	: Map = get_parent()


func	_ready() -> void:
	_map.revealed_changed.connect(queue_redraw)


## Covers every unseen cell inside the map's bounds. Outside the bounds there is
## nothing to hide, so the background shows through as void.
func	_draw() -> void:
	var bounds := _map.get_bounds()
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var cell := Vector2i(x, y)
			if not _map.is_revealed(cell):
				draw_rect(_map.cell_rect(cell), UNSEEN_COLOR)
