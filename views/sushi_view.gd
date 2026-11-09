extends Control
## Esterilla de sushi (Japón): se pone el alga, se cubre de arroz frotando, se agregan los rellenos,
## se enrolla deslizando hacia arriba y se corta en piezas. Modifica `roll` directamente (el arroz)
## y avisa: rice (cubrió más arroz), rolling(cuánto subió) y tapped (toques para cortar).

signal dropped(data: Dictionary)
signal rice
signal rolling(amount: float)
signal tapped

const Art = preload("res://art.gd")
const COLS := 10
const ROWS := 6
const FILL_COLS := {"Salmón": Color("f28a5a"), "Palta": Color("8ab83a"), "Pepino": Color("5a9a3a"),
	"Queso crema": Color("fbf6ea"), "Kanikama": Color("e8503a")}

var roll = null           # null o {stage, rice, fillings, rolled, cuts}
var need_cuts := 6
var _down := false
var _last := Vector2.ZERO
var _cursor := Vector2(-1000, -1000)
var _tap := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_tap = maxf(_tap - delta * 5.0, 0.0)
	queue_redraw()


func bump() -> void:
	_tap = 1.0


func _nori() -> Rect2:
	return Rect2(Vector2(size.x / 2.0 - 210, 50), Vector2(420, 250))


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "nori"


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_down = mb.pressed
		_cursor = mb.position
		_last = mb.position
		if mb.pressed:
			if roll == null or int(roll["stage"]) in [2, 4]:
				tapped.emit()
			elif int(roll["stage"]) == 1:
				_spread(mb.position)
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_cursor = mm.position
		if _down and roll != null:
			match int(roll["stage"]):
				1:
					_spread(mm.position)
				3:
					var dy := _last.y - mm.position.y
					if dy > 0.0:
						rolling.emit(dy)
		_last = mm.position


## Frotar el arroz: se cubren las celdas que toca la mano
func _spread(p: Vector2) -> void:
	var n := _nori()
	var cells: Array = roll["rice"]
	var changed := false
	for r in ROWS:
		for c in COLS:
			var cc := n.position + Vector2((c + 0.5) * n.size.x / COLS, (r + 0.5) * n.size.y / ROWS)
			if cc.distance_to(p) < 34.0 and not cells[r * COLS + c]:
				cells[r * COLS + c] = true
				changed = true
	if changed:
		rice.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false
		_cursor = Vector2(-1000, -1000)


func _draw() -> void:
	var n := _nori()
	# Esterilla de bambú
	var mat := n.grow(30)
	Art.rrect(self, Rect2(mat.position + Vector2(5, 8), mat.size), Color(0, 0, 0, 0.25), 6)
	Art.rrect(self, mat, Color("d8c88a"), 6)
	for k in int(mat.size.y / 12):
		draw_line(Vector2(mat.position.x, mat.position.y + 6 + k * 12), Vector2(mat.end.x, mat.position.y + 6 + k * 12), Color("b8a46a"), 2)
	for x in [mat.position.x + 30, mat.get_center().x, mat.end.x - 30]:
		draw_line(Vector2(x, mat.position.y), Vector2(x, mat.end.y), Color("8a6a3a"), 2)
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if _can_drop_data(Vector2.ZERO, dd):
			Art.rrect(self, mat.grow(4), Color(0, 0, 0, 0), 8, Color(1, 0.85, 0.3, 0.6 + 0.3 * sin(Time.get_ticks_msec() / 150.0)), 5)
	if roll == null:
		Art.text(self, Vector2(0, n.get_center().y), "Arrastrá una hoja de alga a la esterilla", 20, Color(0.25, 0.18, 0.08), HORIZONTAL_ALIGNMENT_CENTER, size.x)
		return
	var stage: int = roll["stage"]
	var hint := ""
	if stage <= 3:
		var rolled: float = roll["rolled"] if stage == 3 else 0.0
		var top_y := n.position.y
		var cut_y := lerpf(n.end.y, n.position.y + 30, rolled)
		# Alga y arroz (lo que todavía no se enrolló)
		draw_rect(Rect2(n.position.x, top_y, n.size.x, cut_y - top_y), Color("1d2a1e"))
		var cells: Array = roll["rice"]
		for r in ROWS:
			for c in COLS:
				if not cells[r * COLS + c]:
					continue
				var cr := Rect2(n.position + Vector2(c * n.size.x / COLS, r * n.size.y / ROWS), Vector2(n.size.x / COLS, n.size.y / ROWS))
				if cr.position.y > cut_y:
					continue
				cr.size.y = minf(cr.size.y, cut_y - cr.position.y)
				draw_rect(cr.grow(1), Color("fbfbf4"))
				for g in 4:
					draw_circle(cr.position + Vector2(5 + (g * 13) % int(cr.size.x - 6), 5 + (g * 7) % maxi(int(cr.size.y - 6), 1)), 1.6, Color("e6e6d8"))
		# Rellenos en tiras, cerca de abajo
		var fills: Array = roll["fillings"]
		for k in fills.size():
			var fy := n.position.y + n.size.y * 0.7 - k * 16.0
			if fy < cut_y:
				Art.rrect(self, Rect2(n.position.x + 20, fy, n.size.x - 40, 14), FILL_COLS.get(fills[k], Color.WHITE), 6)
		if stage == 3:
			# El rollo que se va formando abajo
			var rh := 34.0 + rolled * 40.0
			Art.rrect(self, Rect2(n.position.x - 6, cut_y - rh * 0.5, n.size.x + 12, rh), Color("1d2a1e"), rh * 0.5)
			draw_line(Vector2(n.position.x, cut_y - rh * 0.25), Vector2(n.end.x, cut_y - rh * 0.25), Color(1, 1, 1, 0.12), 3)
			hint = "Enrollá: mantené apretado y deslizá hacia arriba (%d%%)" % int(rolled * 100.0)
		elif stage == 1:
			var cov := cells.filter(func(x): return x).size() / float(cells.size())
			hint = "Cubrí el alga de arroz: mantené apretado y frotá (%d%%)" % int(cov * 100.0)
		else:
			hint = "Tocá los rellenos que pidió (a la izquierda) y después ¡Enrollar!"
	else:
		# El rollo entero, cortado en piezas
		var cy := n.get_center().y
		var w := n.size.x
		var pieces: int = need_cuts + 1
		var cuts: int = roll["cuts"]
		var pw := w / pieces
		var x := n.position.x
		for k in pieces:
			var gap := 6.0 if k < cuts else 0.0
			var pr := Rect2(x + gap * 0.5, cy - 40, pw - gap, 80)
			Art.rrect(self, Rect2(pr.position + Vector2(3, 6), pr.size), Color(0, 0, 0, 0.18), 10)
			Art.rrect(self, pr, Color("1d2a1e"), 10)
			if k < cuts:
				# Pieza cortada: se ve el arroz y el relleno
				Art.ellipse(self, pr.get_center(), Vector2(pr.size.x * 0.4, 30), Color("fbfbf4"))
				var fills: Array = roll["fillings"]
				for f in fills.size():
					draw_circle(pr.get_center() + Vector2((f - (fills.size() - 1) / 2.0) * 11, 0), 6, FILL_COLS.get(fills[f], Color.WHITE))
			x += pw
		if cuts < need_cuts:
			var kx := n.position.x + pw * (cuts + 1)
			draw_dashed_line(Vector2(kx, cy - 56), Vector2(kx, cy + 56), Color(0.2, 0.1, 0.05, 0.5), 2.0, 8.0)
			var tip := Vector2(kx, cy + 30 - (1.0 - _tap) * 20.0)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-12, -70), tip + Vector2(10, -70), tip + Vector2(6, -6)]), Color("dfe3e8"))
			Art.rrect(self, Rect2(tip + Vector2(-9, -112), Vector2(16, 44)), Color("3a2a1a"), 5)
		hint = "Cortá en piezas: tocá el rollo (%d de %d)" % [cuts, need_cuts]
	Art.text(self, Vector2(0, size.y - 10), hint, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
