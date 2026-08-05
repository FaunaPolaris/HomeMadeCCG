extends Node2D


func _ready() -> void:
	Global.player_entity = load("res://scenes/player.tscn").instantiate()
	Global.player_entity.global_position = Vector2(320, 180)
	Global.player_entity.screen_focus = true
	Global.player_entity.map_position = Vector2.ZERO
	add_child(Global.player_entity)
