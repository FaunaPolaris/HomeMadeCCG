extends Control

## The strip at the top of the center panel that answers "where and when".
## The name is a nod to Minecraft's WAILA mod; the tile details it once
## showed moved onto cards, so this reads the player's cell and the calendar
## instead: X and Y on the position plate, the date on the calendar plate.


@onready var	_x_label		: Label = %x_label
@onready var	_y_label		: Label = %y_label
@onready var	_calendar_label	: Label = %calendar_label


func	_ready() -> void:
	Global.player_moved.connect(_on_player_moved)
	# Every date change is a day change, so one signal keeps the text current.
	Calendar.day_changed.connect(_on_day_changed)
	_calendar_label.text = Calendar.date_text()
	if Global.player_entity != null:
		_on_player_moved(Global.player_entity.map_position)


func	_on_player_moved(cell : Vector2i) -> void:
	_x_label.text = "%02d" % cell.x
	_y_label.text = "%02d" % cell.y


func	_on_day_changed(_day : int) -> void:
	_calendar_label.text = Calendar.date_text()
