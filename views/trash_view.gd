extends Control
## Cesto de basura con pedal. Recibe lo que se arrastra encima y abre la tapa al acercarse.

signal dropped(data: Dictionary)

const Art = preload("res://art.gd")

var _open := 0.0
var _gulp := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Arrastrá acá lo que quieras tirar (se descuenta de la caja)"


func _process(delta: float) -> void:
	var dragging := get_viewport().gui_is_dragging()
	var hover := dragging and Rect2(Vector2.ZERO, size).grow(20).has_point(get_local_mouse_position())
	var goal := 1.0 if hover else (0.25 if dragging else 0.0)
	_open = move_toward(_open, goal, delta * 6.0)
	_gulp = maxf(_gulp - delta * 3.0, 0.0)
	queue_redraw()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") in ["prepared", "plate"]


func _drop_data(_at: Vector2, data: Variant) -> void:
	_gulp = 1.0
	dropped.emit(data)


func _draw() -> void:
	var w := size.x
	var h := size.y - 18.0
	var top := 26.0
	var shake := sin(_gulp * 30.0) * 3.0 * _gulp
	# Sombra
	Art.ellipse(self, Vector2(w / 2.0, h + 2), Vector2(w * 0.42, 6), Color(0, 0, 0, 0.25))
	# Cuerpo (más angosto abajo)
	var body := PackedVector2Array([Vector2(8 + shake, top), Vector2(w - 8 + shake, top), Vector2(w - 16, h), Vector2(16, h)])
	draw_colored_polygon(body, Color("6f8a7a"))
	for k in 5:
		var x := 18.0 + k * (w - 36.0) / 4.0
		draw_line(Vector2(x + shake * 0.5, top + 8), Vector2(x + (w / 2.0 - x) * 0.08, h - 6), Color("587262"), 3)
	draw_line(Vector2(8 + shake, top + 2), Vector2(w - 8 + shake, top + 2), Color("8fa99a"), 4)
	# Pedal
	Art.rrect(self, Rect2(w / 2.0 - 14, h - 4, 28, 8), Color("3a3f45"), 3)
	# Interior oscuro cuando la tapa se abre
	if _open > 0.05:
		Art.ellipse(self, Vector2(w / 2.0 + shake, top), Vector2(w / 2.0 - 8, 6), Color("1d2420"))
	# Tapa: gira desde la bisagra de la izquierda
	var hinge := Vector2(8 + shake, top)
	draw_set_transform(hinge, -_open * 1.1, Vector2.ONE)
	Art.rrect(self, Rect2(-2, -10, w - 12, 12), Color("7f9a8a"), 5, Color("587262"), 2)
	Art.rrect(self, Rect2((w - 12) / 2.0 - 10, -16, 20, 7), Color("587262"), 3)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Art.text(self, Vector2(0, size.y - 2), "Tirar", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w, 4)
