class_name Card
extends Control

## A card from the cardbox: the frame every system is shown and handled
## through, be it a plant, an animal or an inventory.

enum Element { FIRE, AIR, WATER, EARTH, THUNDER, HUNGER, WOOD, SMOKE, NULL }

const SIZE := Vector2(192, 288)
const ICON_SIZE := 12

@export var card_name := "CARD NAME":
	set(value):
		card_name = value
		if is_node_ready():
			%name_label.text = value

@export_multiline var description := "Card description":
	set(value):
		description = value
		if is_node_ready():
			%description_label.text = value

@export var element := Element.NULL:
	set(value):
		element = value
		if is_node_ready():
			_show_element_icon()


func _ready() -> void:
	%name_label.text = card_name
	%description_label.text = description
	_limit_description_lines()
	_show_element_icon()


func _limit_description_lines() -> void:
	# A Label draws its own text past its rect (clip_contents only clips
	# children), so overflow is prevented by capping the visible lines to
	# what fits inside the description frame.
	var label: Label = %description_label
	var settings := label.label_settings
	var line_height := settings.font.get_height(settings.font_size) + settings.line_spacing
	label.max_lines_visible = int(label.size.y / line_height)


func _show_element_icon() -> void:
	var icon: AtlasTexture = %element_icon.texture
	icon.region = Rect2(element * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE)
