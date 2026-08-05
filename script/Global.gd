extends Node

var player_entity	: Entity

func player_move(new_map_postion : Vector2):
	player_entity.map_position = new_map_postion
