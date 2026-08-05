extends Node2D

class_name Entity

var screen_focus	: bool = false
var map_position		: Vector2 

func	_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		move(Vector2(0, 1))
	elif event.is_action_pressed("ui_down"):
		move(Vector2(0, -1))
	elif event.is_action_pressed("ui_left"):
		move(Vector2(1, 0))
	elif event.is_action_pressed("ui_right"):
		move(Vector2(-1, 0))

func	move(direction : Vector2):
	map_position += direction
	Global.drawMap()
	
