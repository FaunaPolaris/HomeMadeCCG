extends Node2D


func _ready() -> void:
	Global.player_entity = load("res://scenes/player.tscn").instantiate()
	Global.player_entity.global_position = Vector2(320, 180)
	Global.player_entity.screen_focus = true
	Global.player_entity.map_position = Vector2.ZERO
	Global.current_map = load("res://scenes/map.tscn").instantiate()
	add_child(Global.current_map)
	Global.drawMap()
	add_child(Global.player_entity)
