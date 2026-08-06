extends Node

class_name MapTransition

## One doorway out of a map. Add one as a child of a map for every building tile
## drawn on it: the building layer supplies the art, this node supplies where it
## goes. See plot/making_a_map.md.

## The cell this doorway sits on. Must be a cell with a building drawn on it.
@export var	cell			: Vector2i = Vector2i.ZERO

## The map scene to travel to.
##
## Stored as a path rather than a [PackedScene] on purpose: two maps that lead to
## each other would otherwise be a circular resource reference, which is exactly
## what a pair of connected doors is.
@export_file("*.tscn") var	destination	: String = ""

## The cell in the destination map the player arrives on.
##
## Point this just inside the destination rather than at the door on the other
## side, so arriving does not leave the player standing on the way back.
@export var	arrival_cell	: Vector2i = Vector2i.ZERO


## True when this transition has somewhere to go.
func	is_valid() -> bool:
	return not destination.is_empty() and ResourceLoader.exists(destination)
