extends Control
## Botón ilustrado: muestra un dibujo (textura, comida o función) y un texto abajo.
## Si tiene drag_data se puede arrastrar (por ejemplo, hasta el plato).

signal pressed
signal held      # se emite al apretar (antes de soltar): para acciones que se mantienen, como desparramar

const Art = preload("res://art.gd")

var texture: Texture2D = null
var food_id := ""
var entry: Dictionary = {}      # preparación (cocida/cortada): se dibuja con su punto de cocción
var chopped := false
var tint := Color.WHITE
var draw_fn := Callable()       # func(ci, rect)
var text := ""
var text_size := 13
var selected := false
var drag_data = null            # si no es null, se puede arrastrar y esto es lo que se suelta
var disabled := false:
	set(value):
		disabled = value
		modulate.a = 0.4 if value else 1.0
		mouse_default_cursor_shape = Control.CURSOR_ARROW if value else _cursor()

var _hover := false
var _pressing := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func _ready() -> void:
	if not disabled and mouse_default_cursor_shape == Control.CURSOR_ARROW:
		mouse_default_cursor_shape = _cursor()


func _cursor() -> Control.CursorShape:
	return Control.CURSOR_DRAG if drag_data != null else Control.CURSOR_POINTING_HAND


func _on_hover(h: bool) -> void:
	_hover = h
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or disabled:
		return
	if mb.pressed:
		_pressing = true
		accept_event()
		held.emit()
	elif _pressing:
		# Se cuenta como click al soltar (si se arrastró, el soltar va al destino y no llega acá)
		_pressing = false
		accept_event()
		if Rect2(Vector2.ZERO, size).has_point(mb.position):
			pressed.emit()


func _get_drag_data(_at: Vector2) -> Variant:
	if drag_data == null or disabled:
		return null
	_pressing = false
	var ghost = get_script().new()
	ghost.texture = texture
	ghost.food_id = food_id
	ghost.entry = entry
	ghost.chopped = chopped
	ghost.tint = tint
	ghost.draw_fn = draw_fn
	ghost.size = size
	ghost.position = -size / 2.0
	ghost.modulate = Color(1, 1, 1, 0.85)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var holder := Control.new()
	holder.add_child(ghost)
	set_drag_preview(holder)
	return drag_data


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if selected:
		Art.rrect(self, r, Color(1, 0.82, 0.3, 0.45), 12, Color("ffd166"), 3)
	elif _hover and not disabled:
		Art.rrect(self, r, Color(1, 1, 1, 0.22), 12)
	var lh := float(text_size + 6) if text != "" else 0.0
	var ir := Rect2(5, 4, size.x - 10, size.y - lh - 6)
	if _hover and not disabled:
		ir.position += Vector2(0, -2)
	if draw_fn.is_valid():
		draw_fn.call(self, ir)
	elif not entry.is_empty():
		Art.draw_entry(self, entry, ir)
	elif food_id != "":
		Art.draw_food(self, food_id, ir, tint, chopped)
	elif texture != null:
		Art.draw_tex(self, texture, ir, tint)
	if text != "":
		Art.text(self, Vector2(0, size.y - 6), text, text_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
