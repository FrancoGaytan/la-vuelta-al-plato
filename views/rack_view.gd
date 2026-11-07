extends Control
## Escurridor: recibe lo que se lavó (y vuelve al stock limpio).
## Los platos quedan parados entre los alambres; lo demás, apoyado. Todo gotea un rato.

signal dropped(data: Dictionary)

const Art = preload("res://art.gd")

var recent: Array = []     # [{kind, t}] lo último que se puso a secar


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "clean"


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _draw() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if dd is Dictionary and dd.get("kind", "") == "clean":
			Art.rrect(self, Rect2(Vector2(-6, -6), size + Vector2(12, 12)), Color(0.4, 1, 0.4, 0.12), 12, Color("5ee06a"), 3)
	# Bandeja de goteo con un charquito
	Art.rrect(self, Rect2(Vector2(-4, size.y - 12), Vector2(size.x + 8, 14)), Color("7d8790"), 5)
	var wet := 0.0
	for r in recent:
		wet = maxf(wet, 1.0 - (now - r["t"]) / 25.0)
	if wet > 0.0:
		Art.ellipse(self, Vector2(size.x / 2.0, size.y - 6), Vector2(size.x * 0.4, 4), Color(0.62, 0.8, 0.95, 0.45 * wet))
	# Atrás: los platos de canto. Adelante: lo demás.
	var plates := recent.filter(func(r): return r["kind"] == "plato")
	var others := recent.filter(func(r): return r["kind"] != "plato")
	for k in plates.size():
		var x := 26.0 + k * 28.0
		var pr := Rect2(Vector2(x - 40, 12), Vector2(80, size.y - 44))
		Art.draw_plate_edge(self, pr)
		_drips(Vector2(x, size.y - 30), now, plates[k]["t"], k)
	Art.draw_rack(self, Rect2(Vector2.ZERO, size))
	for k in others.size():
		var w := (size.x - 20) / 3.0
		var r := Rect2(Vector2(size.x - 10 - (k + 1) * w, size.y * 0.42), Vector2(w, size.y * 0.5))
		Art.draw_tool(self, r, others[k]["kind"], 0.0, 0.0, false)
		_drips(Vector2(r.get_center().x, r.end.y - 8), now, others[k]["t"], k + 7)
	Art.text(self, Vector2(0, size.y + 22), "Escurridor", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


## Gotitas que caen (cada vez menos, a medida que se seca)
func _drips(p: Vector2, now: float, t0: float, k: int) -> void:
	var wet := 1.0 - (now - t0) / 20.0
	if wet <= 0.0:
		return
	var ph := fmod(now * (0.8 + 0.6 * wet) + k * 0.31, 1.0)
	draw_circle(p + Vector2(0, ph * 16), 2.0, Color(0.7, 0.88, 1.0, wet * (1.0 - ph)))
