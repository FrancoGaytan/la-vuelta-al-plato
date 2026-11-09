extends Control
## Prensa de tortillas (México): se arrastra una bolita de masa y se baja la palanca
## (mantener apretado y arrastrar hacia abajo) hasta que la tortilla queda aplanada.

signal dropped(data: Dictionary)
signal pressing(amount: float)      # cuánto se bajó la palanca en este movimiento (0-1)
signal tapped

const Art = preload("res://art.gd")
const MASA := Color("efe2b4")

var masa = null          # null o {pressed}
var _down := false
var _last_y := 0.0
var _lever := 0.0        # posición visible de la palanca (0 arriba, 1 abajo)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	var goal := 0.0
	if masa != null:
		goal = float(masa["pressed"]) if _down else float(masa["pressed"]) * 0.25
	_lever = move_toward(_lever, goal, delta * (8.0 if _down else 2.5))
	queue_redraw()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "masa"


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_down = mb.pressed
		_last_y = mb.position.y
		if mb.pressed and (masa == null or float(masa["pressed"]) >= 1.0):
			tapped.emit()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _down and masa != null:
		var dy := mm.position.y - _last_y
		_last_y = mm.position.y
		if dy > 0.0:
			pressing.emit(dy / 190.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false


func _draw() -> void:
	var base_c := Vector2(size.x / 2.0, size.y - 120)
	var R := 150.0
	var p := float(masa["pressed"]) if masa != null else 0.0
	# Base de hierro con su nylon
	Art.ellipse(self, base_c + Vector2(6, 26), Vector2(R + 20, 56), Color(0, 0, 0, 0.25))
	Art.rrect(self, Rect2(base_c.x - R - 14, base_c.y, 2 * R + 28, 26), Color("3a3634"), 10)
	Art.ellipse(self, base_c, Vector2(R + 14, 54), Color("4a4542"))
	Art.ellipse(self, base_c, Vector2(R, 46), Color("e8edf0"))
	Art.ellipse(self, base_c + Vector2(-30, -10), Vector2(60, 10), Color(1, 1, 1, 0.5))
	# Bisagra atrás
	Art.rrect(self, Rect2(base_c.x - 30, base_c.y - 60, 60, 26), Color("2e2a28"), 6)
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if _can_drop_data(Vector2.ZERO, dd):
			Art.ellipse(self, base_c, Vector2(R + 24, 62), Color(1, 0.85, 0.3, 0.25 + 0.15 * sin(Time.get_ticks_msec() / 150.0)))
	# La masa: bolita que se aplana
	if masa != null:
		var r := lerpf(34.0, R - 10.0, p)
		var h := lerpf(30.0, 4.0, p)
		Art.ellipse(self, base_c + Vector2(0, 4), Vector2(r, r * 0.3), Color(0, 0, 0, 0.12))
		Art.ellipse(self, base_c - Vector2(0, h * 0.5), Vector2(r, r * 0.3 + h * 0.5), MASA.darkened(0.06))
		Art.ellipse(self, base_c - Vector2(0, h * 0.7), Vector2(r * 0.96, r * 0.28 + h * 0.4), MASA)
		Art.ellipse(self, base_c - Vector2(r * 0.25, h * 0.9 + r * 0.06), Vector2(r * 0.3, r * 0.06 + h * 0.15), Color(1, 1, 1, 0.3))
	# Tapa: baja con la palanca (abierta = levantada atrás)
	var lid_y := lerpf(base_c.y - 190.0, base_c.y - 22.0, _lever)
	var lid_ry := lerpf(16.0, 44.0, _lever)
	Art.ellipse(self, Vector2(base_c.x, lid_y + 14), Vector2(R + 12, lid_ry), Color("2a2624"))
	Art.ellipse(self, Vector2(base_c.x, lid_y), Vector2(R + 12, lid_ry), Color("4d4744"))
	Art.ellipse(self, Vector2(base_c.x - 40, lid_y - lid_ry * 0.3), Vector2(50, lid_ry * 0.2), Color(1, 1, 1, 0.1))
	draw_line(Vector2(base_c.x, base_c.y - 48), Vector2(base_c.x, lid_y), Color("2e2a28"), 10)
	# Palanca: sale de adelante; arriba cuando está abierta, abajo al presionar
	var pivot := Vector2(base_c.x + R + 4, base_c.y - 6)
	var ang := lerpf(-1.25, 0.45, _lever)
	var tip := pivot + Vector2.from_angle(ang) * 150.0
	draw_line(pivot, tip, Color("2a2624"), 14)
	draw_line(pivot, tip, Color("57514d"), 9)
	Art.rrect(self, Rect2(tip - Vector2(16, 16), Vector2(32, 32)), Color("8a2a1e"), 12)
	draw_circle(pivot, 12, Color("2a2624"))
	var hint := ""
	if masa == null:
		hint = "Arrastrá una bolita de masa a la prensa"
	elif p < 1.0:
		hint = "Mantené apretado y bajá la palanca (%d%%)" % int(p * 100.0)
	else:
		hint = "¡Tortilla lista! Mandala al comal"
	Art.text(self, Vector2(0, size.y - 14), hint, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
