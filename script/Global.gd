extends Node

var	player_entity	: Entity
var	current_map		: Map


func drawMap():
	current_map.global_position = player_entity.map_position * 96
