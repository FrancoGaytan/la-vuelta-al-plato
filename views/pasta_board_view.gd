extends Control
## Tabla de pasta fresca (Italia): volcán de harina, huevos, amasar, estirar con el palote y cortar.
## Recibe la harina y los huevos arrastrados (dropped). Mientras se mantiene apretado y se mueve
## encima de la masa avisa cuánto se frotó (worked), y en la etapa de cortar avisa cada toque (tapped).

signal dropped(data: Dictionary)
signal worked(dist: float)
signal tapped

const Art = preload("res://art.gd")
const DOUGH := Color("f1d27c")
const FLOUR := Color("f7f1e3")

var pasta = null          # null o {stage, knead, roll, cuts, need_cuts}
var _down := false
var _last := Vector2.ZERO
var _cursor := Vector2(-1000, -1000)
var _press := 0.0         # cuánto se está apretando la masa (se nota el aplastado)
var _tap := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_press = move_toward(_press, 1.0 if _down else 0.0, delta * 6.0)
	_tap = maxf(_tap - delta * 5.0, 0.0)
	queue_redraw()


func bump() -> void:
	_tap = 1.0


func _center() -> Vector2:
	return size / 2.0 + Vector2(0, -12)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") in ["harina", "huevo"]


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _working() -> bool:
	return pasta != null and int(pasta["stage"]) in [2, 3]


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_cursor = mb.position
		if mb.pressed:
			_down = true
			_last = mb.position
			if pasta == null or not _working():
				tapped.emit()
		else:
			_down = false
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_cursor = mm.position
		if _down and _working():
			var d := mm.position.distance_to(_last)
			_last = mm.position
			# Solo cuenta si se frota encima de la masa
			if mm.position.distance_to(_center()) < _work_radius() + 40.0:
				worked.emit(minf(d, 80.0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false
		_cursor = Vector2(-1000, -1000)


func _work_radius() -> float:
	if pasta == null:
		return 80.0
	if int(pasta["stage"]) >= 3:
		return 90.0 + 80.0 * float(pasta["roll"])
	return 80.0


func _draw() -> void:
	var c := _center()
	# Tabla de madera enharinada
	var board := Rect2(Vector2(10, 10), size - Vector2(20, 60))
	Art.rrect(self, Rect2(board.position + Vector2(5, 8), board.size), Color(0, 0, 0, 0.25), 14)
	Art.wood(self, board, Color("c9965a"), 34.0)
	Art.rrect(self, board, Color(0, 0, 0, 0), 14, Color("8a5a2b"), 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 90:
		var p := Vector2(rng.randf_range(board.position.x + 10, board.end.x - 10), rng.randf_range(board.position.y + 10, board.end.y - 10))
		draw_circle(p, rng.randf_range(0.8, 2.2), Color(1, 1, 1, 0.45))
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if _can_drop_data(Vector2.ZERO, dd):
			Art.rrect(self, board.grow(4), Color(0, 0, 0, 0), 16, Color(1, 0.85, 0.3, 0.6 + 0.3 * sin(Time.get_ticks_msec() / 150.0)), 5)
	if pasta == null:
		Art.text(self, Vector2(0, c.y), "Arrastrá la harina a la tabla", 20, Color(0.25, 0.15, 0.08), HORIZONTAL_ALIGNMENT_CENTER, size.x)
		return
	var stage: int = pasta["stage"]
	var hint := ""
	match stage:
		1:
			_draw_flour(c, 1.0, false)
			hint = "Ahora los huevos, en el medio del volcán"
		2:
			var k: float = pasta["knead"]
			_draw_flour(c, 1.0 - k, k < 0.15)
			if k > 0.0:
				_draw_dough_ball(c, k)
			hint = "Amasá: mantené apretado y frotá la masa (%d%%)" % int(k * 100.0)
			if _down:
				_draw_hands(_cursor)
		3:
			var r: float = pasta["roll"]
			_draw_sheet(c, r, 0)
			hint = "Estirala: apretá y pasá el palote arriba y abajo (%d%%)" % int(r * 100.0)
			var py := clampf(_cursor.y, board.position.y + 20, board.end.y - 20) if _cursor.x > -500 else c.y + 60
			_draw_pin(Vector2(c.x, py), _down)
		4:
			_draw_sheet(c, 1.0, int(pasta["cuts"]))
			var n: int = pasta["need_cuts"]
			hint = "Cortá las tiras: tocá la masa (%d de %d)" % [int(pasta["cuts"]), n]
			if int(pasta["cuts"]) < n:
				var sw := _sheet_size(1.0)
				var x := c.x - sw.x / 2.0 + sw.x * (int(pasta["cuts"]) + 1) / float(n + 1)
				draw_dashed_line(Vector2(x, c.y - sw.y / 2.0 - 6), Vector2(x, c.y + sw.y / 2.0 + 6), Color(0.3, 0.2, 0.1, 0.5), 2.0, 8.0)
				_draw_knife(Vector2(x, c.y + sw.y / 2.0 - 6.0 - (1.0 - _tap) * 20.0))
	Art.text(self, Vector2(0, size.y - 16), hint, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


## Volcán de harina (amount = cuánta queda suelta mientras se amasa) y, si hay, los huevos en el medio
func _draw_flour(c: Vector2, amount: float, eggs: bool) -> void:
	if amount <= 0.02:
		return
	var r := 120.0 * sqrt(amount)
	Art.ellipse(self, c + Vector2(0, 8), Vector2(r * 1.05, r * 0.62), Color(0, 0, 0, 0.12))
	Art.ellipse(self, c, Vector2(r, r * 0.6), FLOUR.darkened(0.05))
	Art.ellipse(self, c + Vector2(-r * 0.1, -r * 0.08), Vector2(r * 0.85, r * 0.48), FLOUR)
	if pasta["stage"] == 1 or eggs:
		Art.ellipse(self, c, Vector2(r * 0.45, r * 0.26), Color("e2d8c2"))
	if eggs or (int(pasta["stage"]) == 2 and float(pasta["knead"]) < 0.15):
		for k in 3:
			var p := c + Vector2((k - 1) * 22.0, (k % 2) * 8.0 - 4.0)
			Art.ellipse(self, p, Vector2(20, 14), Color(1, 1, 0.95, 0.85))
			draw_circle(p + Vector2(1, -1), 9.0, Color("f2a81d"))
			draw_circle(p + Vector2(-2, -4), 3.0, Color(1, 1, 1, 0.5))


## La masa: al principio grumosa y pálida, al final lisa y amarilla
func _draw_dough_ball(c: Vector2, k: float) -> void:
	var r := 46.0 + 30.0 * k
	var col := FLOUR.lerp(DOUGH, clampf(k * 1.3, 0.0, 1.0))
	var push := Vector2.ZERO
	if _down and _cursor.x > -500:
		push = ((_cursor - c).limit_length(40.0)) * 0.35 * _press
	var pts := PackedVector2Array()
	var rough := (1.0 - k) * 0.22
	for i in 36:
		var a := TAU * i / 36.0
		var nz := sin(a * 7.0 + 1.3) * 0.5 + sin(a * 13.0 + 0.4) * 0.5
		var rr := r * (1.0 + nz * rough)
		var d := Vector2(cos(a) * rr * (1.0 + 0.18 * _press), sin(a) * rr * 0.78 * (1.0 - 0.1 * _press))
		# Se estira hacia donde empuja la mano
		d += push * maxf(0.0, d.normalized().dot(push.normalized()))
		pts.append(c + d)
	var sh := pts.duplicate()
	for i in sh.size():
		sh[i] += Vector2(4, 8)
	draw_colored_polygon(sh, Color(0, 0, 0, 0.15))
	draw_colored_polygon(pts, col)
	Art.ellipse(self, c + Vector2(-r * 0.3, -r * 0.3), Vector2(r * 0.35, r * 0.18), Color(1, 1, 1, 0.25 * k))
	# Pliegues de amasar
	for i in 3:
		draw_arc(c + Vector2(r * 0.15 * (i - 1), r * 0.1), r * (0.35 + i * 0.12), 0.2, 1.4, 10, Color(col.darkened(0.12), 0.6 * (1.0 - k * 0.6)), 2.0)
	if k < 0.6:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in int(16 * (1.0 - k)):
			draw_circle(c + Vector2.from_angle(rng.randf() * TAU) * r * rng.randf_range(0.3, 0.95), rng.randf_range(2, 5), FLOUR)


func _sheet_size(r: float) -> Vector2:
	return Vector2(lerpf(150.0, 380.0, r), lerpf(120.0, 250.0, r))


## La lámina estirada; con cortes, separada en tiras
func _draw_sheet(c: Vector2, r: float, cuts: int) -> void:
	var sz := _sheet_size(r)
	var col := DOUGH.lerp(Color("f6e2a4"), r)
	var rect := Rect2(c - sz / 2.0, sz)
	if cuts <= 0:
		Art.rrect(self, Rect2(rect.position + Vector2(4, 7), sz), Color(0, 0, 0, 0.15), lerpf(60.0, 14.0, r))
		Art.rrect(self, rect, col, lerpf(60.0, 14.0, r))
		Art.rrect(self, rect.grow(-sz.y * 0.12), Color(1, 1, 1, 0.08), 10)
		return
	var n: int = pasta["need_cuts"] + 1
	var w := sz.x / n
	for i in n:
		var cut_left := i <= cuts
		var gap := 3.0 if i < cuts or (i == cuts and cuts > 0) else 0.0
		var sr := Rect2(rect.position.x + i * w + gap, rect.position.y, w - gap * 2.0, sz.y)
		if not cut_left:
			sr.size.x = rect.end.x - sr.position.x
		Art.rrect(self, Rect2(sr.position + Vector2(3, 6), sr.size), Color(0, 0, 0, 0.12), 6)
		Art.rrect(self, sr, col if cut_left else col, 6)
		draw_line(sr.position + Vector2(sr.size.x * 0.3, 6), sr.position + Vector2(sr.size.x * 0.3, sz.y - 6), Color(1, 1, 1, 0.15), 2.0)
		if not cut_left:
			break


func _draw_pin(p: Vector2, pressing: bool) -> void:
	var len := 300.0
	var y := p.y + (3.0 if pressing else 0.0)
	Art.rrect(self, Rect2(p.x - len / 2.0 + 6, y - 8, len, 26), Color(0, 0, 0, 0.18), 13)
	Art.rrect(self, Rect2(p.x - len / 2.0, y - 14, len, 26), Color("d9ae76"), 13)
	draw_line(Vector2(p.x - len / 2.0 + 12, y - 8), Vector2(p.x + len / 2.0 - 12, y - 8), Color(1, 1, 1, 0.3), 3.0)
	for side in [-1, 1]:
		Art.rrect(self, Rect2(p.x + side * (len / 2.0 + 30) - 30, y - 9, 60, 16), Color("a8763f"), 8)


func _draw_hands(p: Vector2) -> void:
	if p.x < -500:
		return
	for side in [-1, 1]:
		var hp := p + Vector2(side * 26, 10)
		Art.ellipse(self, hp + Vector2(3, 5), Vector2(26, 20), Color(0, 0, 0, 0.12))
		Art.ellipse(self, hp, Vector2(26, 20), Color("f1c19a"))
		Art.ellipse(self, hp + Vector2(-side * 6, -8), Vector2(14, 7), Color(1, 1, 1, 0.2))


func _draw_knife(tip: Vector2) -> void:
	var blade := PackedVector2Array([tip, tip + Vector2(-14, -70), tip + Vector2(10, -70), tip + Vector2(6, -6)])
	draw_colored_polygon(blade, Color("dfe3e8"))
	draw_line(tip + Vector2(-12, -66), tip, Color(1, 1, 1, 0.6), 2.0)
	Art.rrect(self, Rect2(tip + Vector2(-10, -116), Vector2(18, 48)), Color("5a3a22"), 5)
