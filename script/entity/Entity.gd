extends Node2D

class_name Entity

## Which cell of the map this entity stands on.
## Up is -Y, matching Godot's screen coordinates.
@export var	map_position	: Vector2i = Vector2i.ZERO

## How far this entity sees, in cells. 2 reveals a 5x5 square around it.
@export var	vision_range	: int = 2

## Only the focused entity reads input and is centered on screen.
## Set this through [method Global.focus_entity] so a single entity holds focus.
var	screen_focus	: bool = false :
	set(value):
		screen_focus = value
		set_process_unhandled_input(value)


func	_ready() -> void:
	set_process_unhandled_input(screen_focus)
	refresh_position()


func	_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		move(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		move(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		move(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move(Vector2i(1, 0))


## Steps one cell in [param direction], if the map allows it.
## Returns true when the entity actually moved.
func	move(direction : Vector2i) -> bool:
	var target : Vector2i = map_position + direction
	if not can_enter(target):
		return false
	map_position = target
	refresh_position()
	if screen_focus:
		Global.refresh_view()
	return true


## True when this entity is allowed to stand on [param cell].
## Without a map loaded there is nothing to block movement, so anything goes.
func	can_enter(cell : Vector2i) -> bool:
	if Global.current_map == null:
		return true
	return Global.current_map.can_enter(cell)


## Snaps the entity onto its cell, in map-local space.
## The focused entity ends up at the screen center because the map itself is
## offset by exactly that cell — see [method Global.refresh_view].
func	refresh_position() -> void:
	position = Vector2(map_position) * Global.TILE_SIZE
