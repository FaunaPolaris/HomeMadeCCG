extends Resource

class_name	Tile

enum biome_list{
	BLOOM,
	MOULD,
	TOUPI,
	PRISTINA,
	CAVE,
	GRASH,
	SAND,
	WATER,
	DEEP_WATER
}

var passable	: bool = true
var	biome		: biome_list
## Anything you can interact with that leaves the map unchanged.
#var prop		: Item
## Enterable, and so a transition to another map.
#var building	: Building
