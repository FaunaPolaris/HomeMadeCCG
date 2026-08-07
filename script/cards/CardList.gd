class_name CardList
extends Control

## A vertical strip of cards clipped to one interface panel. Scrolls with
## the mouse wheel or by dragging (mouse or touch) and always comes to
## rest centered on one card: a wheel notch moves one whole card, and a
## released drag eases to whichever card is nearest.

## The list started or finished sliding open or closed.
signal open_changed(now_open: bool)

## Cards were loaded, added or cleared.
signal deck_changed

## The scroll settled toward a different card.
signal selection_changed(index: int)

const CARD_SCENE := preload("res://scenes/cards/card.tscn")

## Gap between stacked cards, in card pixels.
const CARD_GAP := 8.0

## Easing rate toward the target offset; higher is snappier.
const SMOOTHING := 12.0

## How long the deck takes to slide open or closed.
const SLIDE_TIME := 0.25

## Cards to fill the list with until real systems hand theirs over.
@export var placeholder_cards := 6

## Where the list rests, relative to its open position, while the deck
## is closed. Zero means the list has nowhere to hide and stays put.
@export var slide_when_closed := Vector2.ZERO

## Whether the deck starts open. Toggled by the toggle_deck action.
@export var open := true:
	set = set_open

## The card the scroll is resting on, or heading toward.
var selected_index := 0

var _target := 0.0
var _offset := 0.0
var _dragging := false
var _open_position := Vector2.ZERO
var _slide: Tween

@onready var _cards: Control = %cards


func _ready() -> void:
	for i in placeholder_cards:
		var card: Card = CARD_SCENE.instantiate()
		card.card_name = "CARD %d" % (i + 1)
		card.element = (i % Card.Element.size()) as Card.Element
		add_card(card)
	_open_position = position
	if not open:
		position = _open_position + slide_when_closed
		visible = slide_when_closed == Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# Every list answers the action; the event stays unhandled so the
	# other panel's list slides together with this one.
	if event.is_action_pressed("toggle_deck"):
		set_open(not open)


func set_open(value: bool) -> void:
	open = value
	if not is_node_ready():
		return
	open_changed.emit(open)
	if _slide:
		_slide.kill()
	visible = true
	var resting := _open_position + (Vector2.ZERO if open else slide_when_closed)
	_slide = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_slide.tween_property(self, "position", resting, SLIDE_TIME)
	if not open and slide_when_closed != Vector2.ZERO:
		_slide.tween_callback(func() -> void: visible = false)


func add_card(card: Card) -> void:
	_cards.add_child(card)
	card.position = Vector2(0, (_cards.get_child_count() - 1) * (Card.SIZE.y + CARD_GAP))
	deck_changed.emit()


## Replaces the list's contents with one card per decklist entry.
func load_deck(deck: Array) -> void:
	clear_cards()
	for entry in deck:
		if entry is Dictionary:
			var card: Card = CARD_SCENE.instantiate()
			card.apply_data(entry)
			add_card(card)


func card_count() -> int:
	return _cards.get_child_count()


func clear_cards() -> void:
	for card in _cards.get_children():
		# Detach right away so add_card counts only the cards that stay.
		_cards.remove_child(card)
		card.queue_free()
	_target = 0.0
	_offset = 0.0
	deck_changed.emit()
	_update_selection()


## One card of scroll distance.
func _pitch() -> float:
	return Card.SIZE.y + CARD_GAP


## The offset that puts the last card in the panel.
func _max_scroll() -> float:
	return maxf(0.0, (_cards.get_child_count() - 1) * _pitch())


## The nearest offset that frames a card exactly.
func _snapped(value: float) -> float:
	return clampf(roundf(value / _pitch()) * _pitch(), 0.0, _max_scroll())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target = _snapped(_target - _pitch())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target = _snapped(_target + _pitch())
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if not _dragging:
				_target = _snapped(_target)
	elif event is InputEventMouseMotion and _dragging:
		_drag_by(event.relative.y)
	elif event is InputEventScreenDrag:
		_drag_by(event.relative.y)
	elif event is InputEventScreenTouch and not event.pressed:
		_target = _snapped(_target)
	_update_selection()


## Dragging follows the pointer directly; the snap waits for the release.
func _drag_by(relative_y: float) -> void:
	_target = clampf(_target - relative_y, 0.0, _max_scroll())
	_offset = _target


func _update_selection() -> void:
	var index := int(roundf(_target / _pitch()))
	if index != selected_index:
		selected_index = index
		selection_changed.emit(index)


func _process(delta: float) -> void:
	_offset = lerpf(_offset, _target, 1.0 - exp(-SMOOTHING * delta))
	_cards.position.y = -roundf(_offset)
