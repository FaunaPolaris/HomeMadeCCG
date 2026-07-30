extends Node2D


enum e_direction {
	LEFT,
	CENTER,
	RIGHT
}

var	looking	= e_direction.CENTER

func	_process(delta: float) -> void:
	var mouse_direction	= direction_of(get_viewport().get_mouse_position())
	look(mouse_direction)
	
func	look(mouse_direction : e_direction) -> void:
	if looking == mouse_direction:
		return
	if mouse_direction == e_direction.LEFT:
		$pupil.play("center>left")
		looking = e_direction.LEFT
	elif mouse_direction == e_direction.RIGHT:
		$pupil.play("center>right")
		looking = e_direction.RIGHT
	if mouse_direction == e_direction.CENTER:
		if looking == e_direction.LEFT:
			$pupil.play("left>center")
			looking = e_direction.CENTER
		if looking == e_direction.RIGHT:
			$pupil.play("right>center")
			looking = e_direction.CENTER

func	direction_of(mouse_position : Vector2) -> e_direction:
	if mouse_position.x > 1280:
		return e_direction.RIGHT
	elif mouse_position.x < 640:
		return e_direction.LEFT
	return e_direction.CENTER
