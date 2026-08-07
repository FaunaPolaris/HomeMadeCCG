extends CanvasLayer

class_name CheatMenu

## Instant commands for testing the game by hand.
##
## Only exists in debug builds, so it cannot reach players no matter what is
## added to it. Hidden until [constant TOGGLE_KEY] is pressed.
##
## To add a command: write a method that does the thing and returns a short line
## saying what it did, then add one entry to [method _commands]. Nothing else.

## Shows and hides the menu.
const TOGGLE_KEY := KEY_F1

@onready var	_panel			: PanelContainer = $panel
@onready var	_command_list	: VBoxContainer = $panel/layout/commands
@onready var	_status			: Label = $panel/layout/status


## Every button in the menu, top to bottom.
func	_commands() -> Array:
	return [
		{"label": "Reset save (new game)", "action": _reset_save},
	]


func	_ready() -> void:
	# A cheat menu that ships is a bug, so make it impossible rather than
	# remembering to take it out.
	if not OS.is_debug_build():
		queue_free()
		return

	for command in _commands():
		var button := Button.new()
		button.text = command["label"]
		button.pressed.connect(_run.bind(command))
		_command_list.add_child(button)

	_status.text = ""
	_panel.visible = false


func	_unhandled_key_input(event : InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == TOGGLE_KEY:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func	_run(command : Dictionary) -> void:
	var result : String = command["action"].call()
	# Printed as well as shown: a command that reloads the scene takes this menu
	# down with it, so the label would never be read.
	print("[cheat] %s" % result)
	_status.text = result


## Throws the save away and restarts from the top, as a first launch would.
func	_reset_save() -> String:
	SaveGame.discard()
	# Deferred so this returns and the click finishes before the scene holding
	# this menu is torn down.
	get_tree().reload_current_scene.call_deferred()
	return "save discarded, restarting"
