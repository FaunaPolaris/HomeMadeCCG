class_name CardList
extends Control

## A vertical strip of cards clipped to one interface panel. Scrolls with
## the mouse wheel or by dragging (mouse or touch), easing toward the
## target offset and snapping to whole pixels so the art stays crisp.

const CARD_SCENE := preload("res://scenes/cards/card.tscn")

## Gap between stacked cards, in card pixels.
const CARD_GAP := 8.0

## How far one wheel notch scrolls.
const WHEEL_STEP := 48.0

## Easing rate toward the target offset; higher is snappier.
const SMOOTHING := 12.0

## Cards to fill the list with until real systems hand theirs over.
@export var placeholder_cards := 6

var _target := 0.0
var _offset := 0.0
var _dragging := false

@onready var _cards: Control = %cards


func _ready() -> void:
	for i in placeholder_cards:
		var card: Card = CARD_SCENE.instantiate()
		card.card_name = "CARD %d" % (i + 1)
		card.element = (i % Card.Element.size()) as Card.Element
		add_card(card)


func add_card(card: Card) -> void:
	_cards.add_child(card)
	card.position = Vector2(0, (_cards.get_child_count() - 1) * (Card.SIZE.y + CARD_GAP))


func clear_cards() -> void:
	for card in _cards.get_children():
		card.queue_free()
	_target = 0.0


func _max_scroll() -> float:
	var count := _cards.get_child_count()
	if count == 0:
		return 0.0
	var total := count * (Card.SIZE.y + CARD_GAP) - CARD_GAP
	return maxf(0.0, total - size.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target -= WHEEL_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target += WHEEL_STEP
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		_target -= event.relative.y
		_offset = _target  # follow the pointer directly, no easing
	elif event is InputEventScreenDrag:
		_target -= event.relative.y
		_offset = _target
	_target = clampf(_target, 0.0, _max_scroll())


func _process(delta: float) -> void:
	_offset = lerpf(_offset, _target, 1.0 - exp(-SMOOTHING * delta))
	_cards.position.y = -roundf(_offset)
