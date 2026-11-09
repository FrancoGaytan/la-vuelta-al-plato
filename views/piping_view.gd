extends Control
## Manga pastelera (Francia): sobre el éclair hay una guía punteada en zigzag. Manteniendo apretado
## se va dejando el glaseado por donde pasa la mano: cuanto más se cubre la guía (y menos se ensucia), mejor.
## Modifica directamente el diccionario `pipe` {flavor, pts, covered, mess}.

signal changed

const Art = preload("res://art.gd")
const COVER_R := 18.0

var pipe = null
var color := Color("4a2412")
var _down := false
var _last := Vector2.ZERO
var _cursor := Vector2(-1000, -1000)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _shell() -> Rect2:
	return Rect2(Vector2(50, size.y / 2.0 - 70), Vector2(size.x - 100, 130))


## Puntos de la guía: un zigzag a lo largo del éclair
func guide() -> PackedVector2Array:
	var r := _shell()
	var out := PackedVector2Array()
	var n := 41
	for i in n:
		var u := i / float(n - 1)
		var x := r.position.x + 40 + u * (r.size.x - 80)
		var y := r.get_center().y + sin(u * PI * 7.0) * 30.0
		out.append(Vector2(x, y))
	return out


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_down = mb.pressed
		_cursor = mb.position
		_last = mb.position
		if _down:
			_pipe_at(mb.position)
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_cursor = mm.position
		if _down and pipe != null:
			# Puntos intermedios para que la línea no quede cortada si se mueve rápido
			var d := mm.position.distance_to(_last)
			var steps := maxi(1, int(d / 6.0))
			for k in steps:
				_pipe_at(_last.lerp(mm.position, (k + 1) / float(steps)))
			_last = mm.position


func _pipe_at(p: Vector2) -> void:
	if pipe == null:
		return
	var pts: Array = pipe["pts"]
	if not pts.is_empty() and p.distance_to(pts.back()) < 3.0:
		return
	pts.append(p)
	var g := guide()
	var covered: Array = pipe["covered"]
	var near := false
	for i in g.size():
		var dd := g[i].distance_to(p)
		if dd < COVER_R:
			covered[i] = true
		if dd < COVER_R * 1.8:
			near = true
	if not near:
		pipe["mess"] = float(pipe["mess"]) + 1.0     # glaseado fuera de la guía
	changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false
		_cursor = Vector2(-1000, -1000)


func _draw() -> void:
	var r := _shell()
	# Plato de servicio alargado y el éclair horneado
	Art.rrect(self, r.grow(30), Color("f6f4ee"), 60, Color("d8d2c4"), 3)
	Art.rrect(self, Rect2(r.position + Vector2(6, 12), r.size), Color(0, 0, 0, 0.15), 65)
	Art.rrect(self, r, Color("d9944a"), 65, Color("a8661e"), 3)
	Art.rrect(self, r.grow(-14), Color("e6a85e"), 52)
	for k in 6:
		draw_line(r.position + Vector2(60 + k * (r.size.x - 120) / 5.0, 20), r.position + Vector2(50 + k * (r.size.x - 120) / 5.0, r.size.y - 20), Color(0.6, 0.35, 0.1, 0.25), 3)
	if pipe == null:
		Art.text(self, Vector2(0, r.end.y + 70), "Elegí el sabor de la manga", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
		return
	# La guía punteada (lo que falta) y el glaseado que ya se puso
	var g := guide()
	var covered: Array = pipe["covered"]
	for i in g.size() - 1:
		if not (covered[i] and covered[i + 1]):
			draw_dashed_line(g[i], g[i + 1], Color(1, 1, 1, 0.85), 3.0, 7.0)
	var pts: Array = pipe["pts"]
	if pts.size() >= 2:
		var line := PackedVector2Array(pts)
		draw_polyline(line, color.darkened(0.25), 17.0, true)
		draw_polyline(line, color, 13.0, true)
		draw_polyline(line, Color(color.lightened(0.45), 0.6), 3.0, true)
	elif pts.size() == 1:
		draw_circle(pts[0], 7.0, color)
	# La manga
	if _cursor.x > -500:
		var tip := _cursor
		var bag := PackedVector2Array([tip + Vector2(-4, -10), tip + Vector2(4, -10), tip + Vector2(46, -96), tip + Vector2(10, -116)])
		draw_colored_polygon(bag, Color(0.95, 0.95, 0.97, 0.92))
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5, -12), tip + Vector2(5, -12)]), Color("9aa3ab"))
		draw_line(tip + Vector2(14, -60), tip + Vector2(30, -90), Color(color, 0.6), 8)
	var n_cov := covered.filter(func(x): return x).size()
	Art.text(self, Vector2(0, size.y - 10), "Seguí la línea punteada manteniendo apretado (%d%%)" % int(100.0 * n_cov / covered.size()),
		17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
