extends Node2D


func _ready() -> void:
	Global.current_map = load("res://scenes/map.tscn").instantiate()
	add_child(Global.current_map)

	var player : Entity = load("res://scenes/player.tscn").instantiate()
	player.map_position = Vector2i.ZERO
	Global.add_entity(player)
	Global.focus_entity(player)
