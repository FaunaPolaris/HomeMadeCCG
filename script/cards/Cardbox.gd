class_name Cardbox
extends TextureButton

## The box a card list is kept in. It sits in the screen's bottom margin,
## draws open or closed to match its list, and clicking it toggles the
## list on its own — independent of the E key, which moves every list.

@export var list: CardList


func _ready() -> void:
	if list == null:
		push_warning("Cardbox '%s' has no list to watch." % name)
		return
	set_pressed_no_signal(list.open)
	toggled.connect(func(pressed: bool) -> void: list.set_open(pressed))
	list.open_changed.connect(set_pressed_no_signal)
