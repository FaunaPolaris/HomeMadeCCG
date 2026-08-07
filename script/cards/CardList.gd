class_name CardList
extends Control

## A vertical strip of cards clipped to one interface panel. Scrolls with
## the mouse wheel or by dragging (mouse or touch), easing toward the
## target offset and snapping to whole pixels so the art stays crisp.

## The list started or finished sliding open or closed.
signal open_changed(now_open: bool)

const CARD_SCENE := preload("res://scenes/cards/card.tscn")

## Gap between stacked cards, in card pixels.
const CARD_GAP := 8.0

## How far one wheel notch scrolls.
const WHEEL_STEP := 48.0

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


## Replaces the list's contents with one card per decklist entry.
func load_deck(deck: Array) -> void:
	clear_cards()
	for entry in deck:
		if entry is Dictionary:
			var card: Card = CARD_SCENE.instantiate()
			card.apply_data(entry)
			add_card(card)


func clear_cards() -> void:
	for card in _cards.get_children():
		# Detach right away so add_card counts only the cards that stay.
		_cards.remove_child(card)
		card.queue_free()
	_target = 0.0
	_offset = 0.0


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
