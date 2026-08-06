extends Node

## Size of one map cell, in map-local pixels.
## The map is drawn at this scale; the on-screen size comes from the parent's scale.
const TILE_SIZE := 32

## The entity the player controls. The view is centered on it.
var	player_entity	: Entity
var	current_map		: Map


## Places [param entity] on the current map at its own [member Entity.map_position].
func	add_entity(entity : Entity) -> void:
	if current_map == null:
		push_error("Global.add_entity: no current_map to add the entity to.")
		return
	current_map.add_child(entity)
	entity.refresh_position()


## Hands control of the camera and the input to [param entity].
## Any previously focused entity keeps its map coordinates and stops reading input.
func	focus_entity(entity : Entity) -> void:
	if player_entity == entity:
		return
	if player_entity != null:
		player_entity.screen_focus = false
	player_entity = entity
	if entity != null:
		entity.screen_focus = true
	refresh_view()


## Slides the map so the focused entity's cell sits at the center of the screen.
## Every entity is a child of the map at [code]map_position * TILE_SIZE[/code], so
## offsetting the map by the focused entity's cell leaves that entity at the origin
## and keeps every other entity on its own coordinates.
func	refresh_view() -> void:
	if current_map == null or player_entity == null:
		return
	current_map.position = -player_entity.map_position * TILE_SIZE
