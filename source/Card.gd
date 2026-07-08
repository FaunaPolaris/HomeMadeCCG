extends Node2D

class_name Card

func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_mouse_entered() -> void:
	$border.texture = load("res://assets/interface/card/frame/card_selected.png")

func _on_area_mouse_exited() -> void:
	$border.texture = load("res://assets/interface/card/frame/card_frame.png")
