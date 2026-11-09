extends Control
## Crêpière (Francia): se suelta un cucharón de masa y se esparce haciendo círculos con el rastrillo
## (mantener apretado y girar) hasta cubrir todo el disco. Avisa cuántas vueltas se dieron (spread).

signal dropped(data: Dictionary)
signal spread(turns: float)
signal tapped

const Art = preload("res://art.gd")
const BATTER := Color("f4e4bc")

var crepe = null         # null o {spread}
var _down := false
var _last_a := 0.0
var _cursor := Vector2(-1000, -1000)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _center() -> Vector2:
	return Vector2(size.x / 2.0, size.y / 2.0 - 14)


func _radius() -> float:
	return minf(size.x, size.y) * 0.42


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "batter"


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_down = mb.pressed
		_cursor = mb.position
		_last_a = (mb.position - _center()).angle()
		if mb.pressed and (crepe == null or float(crepe["spread"]) >= 1.0):
			tapped.emit()
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_cursor = mm.position
		if _down and crepe != null:
			var rel := mm.position - _center()
			if rel.length() < 20.0 or rel.length() > _radius() * 1.1:
				_last_a = rel.angle()
				return
			var a := rel.angle()
			var da := wrapf(a - _last_a, -PI, PI)
			_last_a = a
			spread.emit(absf(da) / TAU)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false
		_cursor = Vector2(-1000, -1000)


func _draw() -> void:
	var c := _center()
	var R := _radius()
	# Base de acero y disco negro caliente
	Art.ellipse(self, c + Vector2(8, 16), Vector2(R + 26, R + 18), Color(0, 0, 0, 0.25))
	draw_circle(c, R + 20, Color("9aa3ab"))
	draw_circle(c, R + 14, Color("c8ccd0"))
	draw_circle(c, R, Color("26272a"))
	draw_arc(c, R - 6, PI * 1.1, PI * 1.6, 24, Color(1, 1, 1, 0.1), 4)
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if _can_drop_data(Vector2.ZERO, dd):
			draw_arc(c, R + 8, 0, TAU, 48, Color(1, 0.85, 0.3, 0.6 + 0.3 * sin(Time.get_ticks_msec() / 150.0)), 5)
	if crepe == null:
		Art.text(self, Vector2(0, c.y + 6), "Arrastrá el cucharón con masa", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
		return
	var sp: float = crepe["spread"]
	# La masa: una laguna gruesa que se vuelve un disco fino
	var r := lerpf(R * 0.32, R * 0.97, sp)
	var pts := PackedVector2Array()
	var rough := (1.0 - sp) * 0.16
	for i in 40:
		var a := TAU * i / 40.0
		var nz := sin(a * 5.0 + 0.7) * 0.6 + sin(a * 11.0 + 2.1) * 0.4
		pts.append(c + Vector2.from_angle(a) * r * (1.0 + nz * rough))
	draw_colored_polygon(pts, BATTER.darkened(0.05 * (1.0 - sp)))
	# Surcos del rastrillo
	for k in int(3 + sp * 5):
		draw_arc(c, r * (0.2 + k * 0.1), k * 0.9, k * 0.9 + 2.2, 18, Color(0.85, 0.75, 0.5, 0.35), 2)
	Art.ellipse(self, c + Vector2(-r * 0.3, -r * 0.35), Vector2(r * 0.25, r * 0.08), Color(1, 1, 1, 0.2))
	# El rastrillo, siguiendo la mano
	if _cursor.x > -500 and sp < 1.0:
		var t := (_cursor - c).orthogonal().normalized()
		if t.length() < 0.1:
			t = Vector2.RIGHT
		draw_line(_cursor - t * 46, _cursor + t * 46, Color("b8864a"), 9)
		draw_line(_cursor, _cursor + (_cursor - c).normalized() * 70 if (_cursor - c).length() > 1 else _cursor + Vector2(0, 70), Color("c8965a"), 7)
	var hint := "Mantené apretado y hacé círculos con el rastrillo (%d%%)" % int(sp * 100.0) if sp < 1.0 else "¡Bien finita! Mandala a la crepera"
	Art.text(self, Vector2(0, size.y - 10), hint, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
