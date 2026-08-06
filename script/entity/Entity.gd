extends Node2D

class_name Entity

## Which cell of the map this entity stands on.
## Up is -Y, matching Godot's screen coordinates.
@export var	map_position	: Vector2 = Vector2.ZERO

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
		move(Vector2(0, -1))
	elif event.is_action_pressed("ui_down"):
		move(Vector2(0, 1))
	elif event.is_action_pressed("ui_left"):
		move(Vector2(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move(Vector2(1, 0))


func	move(direction : Vector2) -> void:
	map_position += direction
	refresh_position()
	if screen_focus:
		Global.refresh_view()


## Snaps the entity onto its cell, in map-local space.
## The focused entity ends up at the screen center because the map itself is
## offset by exactly that cell — see [method Global.refresh_view].
func	refresh_position() -> void:
	position = map_position * Global.TILE_SIZE
