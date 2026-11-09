extends Control
## Molcajete (México): con los ingredientes adentro, se muele haciendo círculos con el tejolote
## (mantener apretado y girar). Avisa cuántas vueltas se dieron (ground) y cada toque (tapped).

signal ground(turns: float)
signal tapped

const Art = preload("res://art.gd")
const SAUCE_COLS := {"Salsa verde": Color("6a9a2a"), "Salsa roja": Color("b8281a"), "Guacamole": Color("8ab83a")}

var bowl = null           # null o {sauce, ground, items}
var _down := false
var _last_a := 0.0
var _cursor := Vector2(-1000, -1000)
var _spin := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _center() -> Vector2:
	return Vector2(size.x / 2.0, size.y / 2.0 - 10)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_down = mb.pressed
		_cursor = mb.position
		_last_a = (mb.position - _center()).angle()
		if mb.pressed and bowl == null:
			tapped.emit()
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_cursor = mm.position
		if _down and bowl != null:
			var rel := mm.position - _center()
			if rel.length() < 30.0 or rel.length() > 200.0:
				_last_a = rel.angle()
				return
			var a := rel.angle()
			var da := wrapf(a - _last_a, -PI, PI)
			_last_a = a
			_spin += da
			ground.emit(absf(da) / TAU)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false
		_cursor = Vector2(-1000, -1000)


func _draw() -> void:
	var c := _center()
	var R := 150.0
	# Patas y cuerpo de piedra volcánica
	for k in 3:
		var lx := c.x + (k - 1) * 110.0
		Art.rrect(self, Rect2(lx - 22, c.y + 70, 44, 70), Color("3a3634"), 12)
	Art.ellipse(self, c + Vector2(6, 64), Vector2(R + 16, 70), Color(0, 0, 0, 0.25))
	var body := PackedVector2Array()
	for k in 25:
		var a := PI * k / 24.0
		body.append(c + Vector2(cos(a) * R, sin(a) * 100.0))
	draw_colored_polygon(body, Color("4a4542"))
	Art.ellipse(self, c, Vector2(R, 56), Color("5a5450"))
	Art.ellipse(self, c + Vector2(0, 6), Vector2(R - 18, 44), Color("2f2b29"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 70:
		var a := rng.randf() * PI
		var p := c + Vector2(cos(a) * R * rng.randf_range(0.2, 0.98), sin(a) * 95.0 * rng.randf_range(0.2, 0.95))
		draw_circle(p, rng.randf_range(1.0, 2.6), Color(0, 0, 0, 0.35))
	if bowl == null:
		Art.text(self, Vector2(0, c.y + 8), "Elegí una salsa de la izquierda", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
		return
	var g: float = bowl["ground"]
	var col: Color = SAUCE_COLS.get(bowl["sauce"], Color("a0522d"))
	# La salsa que se va formando
	if g > 0.02:
		Art.ellipse(self, c + Vector2(0, 8), Vector2((R - 26) * (0.5 + 0.5 * g), 36 * (0.5 + 0.5 * g)), col.darkened(0.15))
		Art.ellipse(self, c + Vector2(0, 6), Vector2((R - 34) * (0.45 + 0.5 * g), 30 * (0.45 + 0.5 * g)), col)
		for k in int(10 * g):
			var a := k * 2.3 + _spin * 0.5
			Art.ellipse(self, c + Vector2(cos(a) * 60.0 * g, sin(a) * 18.0 * g + 6), Vector2(8, 3), Color(1, 1, 1, 0.12))
	# Los ingredientes enteros, que se achican al moler
	var items: Array = bowl["items"]
	var k_left := 1.0 - g
	if k_left > 0.05:
		for i in 9:
			var id: String = items[i % items.size()]
			var a := TAU * i / 9.0 + i * 0.4 + _spin * 0.3
			var p := c + Vector2(cos(a) * 62.0, sin(a) * 18.0 + 4)
			_draw_piece(id, p, 16.0 * k_left + 2.0, i)
	# El tejolote, siguiendo la mano
	var tp := _cursor if _cursor.x > -500 else c + Vector2(70, -60)
	Art.ellipse(self, tp + Vector2(6, 10), Vector2(26, 12), Color(0, 0, 0, 0.25))
	Art.rrect(self, Rect2(tp.x - 22, tp.y - 70, 44, 80), Color("4f4946"), 20)
	Art.ellipse(self, tp, Vector2(22, 10), Color("3d3835"))
	Art.ellipse(self, tp + Vector2(-8, -50), Vector2(6, 16), Color(1, 1, 1, 0.08))
	var hint := "Mantené apretado y hacé círculos para moler (%d%%)" % int(g * 100.0)
	Art.text(self, Vector2(0, size.y - 12), hint, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


static func piece_color(id: String) -> Color:
	match id:
		"tomatillo": return Color("8fbf3a")
		"chile": return Color("c8281a")
		"cilantro": return Color("3f8f2f")
		"tomate": return Color("d93a2a")
		"ajo": return Color("f6f0e0")
		"palta": return Color("6a9a2a")
		"cebolla": return Color("f4ece0")
		"limon": return Color("b6d23a")
	return Color.WHITE


func _draw_piece(id: String, p: Vector2, r: float, i: int) -> void:
	var col := piece_color(id)
	match id:
		"chile":
			draw_set_transform(p, i * 0.7, Vector2.ONE)
			Art.ellipse(self, Vector2.ZERO, Vector2(r * 1.4, r * 0.45), col)
			draw_line(Vector2(r * 1.3, 0), Vector2(r * 1.8, -r * 0.3), Color("3f8f2f"), maxf(1.5, r * 0.2))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"cilantro":
			for k in 3:
				draw_circle(p + Vector2.from_angle(k * 2.1 + i) * r * 0.45, r * 0.45, col)
		"palta":
			Art.ellipse(self, p, Vector2(r, r * 0.8), Color("2f4a1a"))
			Art.ellipse(self, p, Vector2(r * 0.85, r * 0.68), Color("cfe08a"))
			draw_circle(p + Vector2(0, r * 0.1), r * 0.35, Color("7a4a24"))
		"limon":
			draw_circle(p, r, Color("8fae2a"))
			draw_circle(p, r * 0.85, col)
			for k in 6:
				draw_line(p, p + Vector2.from_angle(k * TAU / 6.0) * r * 0.8, Color(1, 1, 1, 0.5), 1.0)
		"cebolla", "ajo":
			draw_circle(p, r, col.darkened(0.08))
			draw_arc(p, r * 0.6, 0, TAU, 16, Color(0.8, 0.75, 0.7, 0.6), 1.2)
		_:
			draw_circle(p, r, col)
			draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.3, Color(1, 1, 1, 0.3))
