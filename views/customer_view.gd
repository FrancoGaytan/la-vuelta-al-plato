extends Control
## Un comensal. Se dibuja abajo al centro del control.

signal clicked

const Art = preload("res://art.gd")

var look: Dictionary = {}
var mood := 0
var scale_factor := 1.0
var walking := false
var head_only := false
var bubble := ""
var bubble_lift := 0.0
var bubble_while_walking := false
var clickable := false:
	set(value):
		clickable = value
		mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


var _acc := 0.0


## 30 cuadros por segundo alcanzan para respirar, parpadear y caminar (y el celu lo agradece)
func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 1.0 / 30.0:
		_acc = fmod(_acc, 1.0 / 30.0)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if clickable and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		clicked.emit()


func _draw() -> void:
	if look.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	var bob := absf(sin(t * 9.0)) * 6.0 if walking else 0.0
	var base := Vector2(size.x / 2.0, size.y)
	Art.draw_character(self, look, base, scale_factor, mood, t, head_only, bob)
	if bubble != "" and (not walking or bubble_while_walking):
		Art.bubble(self, base + Vector2(0, -190 * scale_factor - bubble_lift), bubble, 16)
