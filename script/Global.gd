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
	if not current_map.has_biome(entity.map_position):
		push_warning("Global.add_entity: '%s' is being placed on %s, which has no biome under it." % [entity.name, entity.map_position])
	var occupant := current_map.entity_at(entity.map_position)
	if occupant != null:
		push_warning("Global.add_entity: '%s' is being placed on %s, already held by '%s'." % [entity.name, entity.map_position, occupant.name])
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


## Brings everything that follows the focused entity up to date: where the map
## sits, and how much of it the player has seen.
##
## Every entity is a child of the map at [code]map_position * TILE_SIZE[/code], so
## offsetting the map by the focused entity's cell leaves that entity at the origin
## and keeps every other entity on its own coordinates.
func	refresh_view() -> void:
	if current_map == null or player_entity == null:
		return
	current_map.position = -Vector2(player_entity.map_position) * TILE_SIZE
	current_map.reveal_around(player_entity.map_position, player_entity.vision_range)


## Called whenever an entity finishes a step. Only the focused entity triggers
## anything, so an NPC walking over a doorway does not drag the player through it.
func	entity_entered_cell(entity : Entity) -> void:
	if entity != player_entity or current_map == null:
		return
	var transition := current_map.transition_at(entity.map_position)
	if transition != null:
		travel(transition)


## Takes the player through [param transition].
func	travel(transition : MapTransition) -> void:
	if not transition.is_valid():
		push_error("Global.travel: '%s' points at '%s', which does not exist." % [transition.name, transition.destination])
		return
	var scene : PackedScene = load(transition.destination)
	if scene == null:
		push_error("Global.travel: could not load '%s'." % transition.destination)
		return
	change_map(scene, transition.arrival_cell)


## Swaps the current map for [param scene] and puts the player down on
## [param arrival_cell].
##
## The map the player leaves is remembered first and put back if they return, so
## what they explored and changed is not lost. The player is detached before the
## old map is freed — the map is scenery, the player is not.
func	change_map(scene : PackedScene, arrival_cell : Vector2i) -> void:
	if current_map == null:
		push_error("Global.change_map: there is no current map to leave.")
		return

	var root := current_map.get_parent()
	var traveller := player_entity

	if traveller != null and traveller.get_parent() == current_map:
		current_map.remove_child(traveller)

	SaveGame.remember(current_map)
	var leaving := current_map
	root.remove_child(leaving)
	leaving.queue_free()

	current_map = scene.instantiate()
	root.add_child(current_map)
	SaveGame.restore(current_map)

	if traveller != null:
		traveller.map_position = arrival_cell
		add_entity(traveller)
		refresh_view()

	SaveGame.current_map_path = current_map.get_map_id()
	SaveGame.player_cell = arrival_cell
	SaveGame.save_to_disk()
