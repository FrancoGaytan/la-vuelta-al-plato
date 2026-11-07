extends Control
## Mesa de pizza (Italia): acá se estira la masa y se le pone salsa e ingredientes antes del horno.
## Recibe el bollo de masa y la salsa arrastrados (dropped), y avisa cuando se la toca (tapped) para estirarla.

signal dropped(data: Dictionary)
signal tapped

const Art = preload("res://art.gd")

var pizza = null          # null o {stretch, sauce, sprinkles, plate_toppings}
var _tap := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_tap = maxf(_tap - delta * 5.0, 0.0)
	queue_redraw()


func bump() -> void:
	_tap = 1.0


func _rect() -> Rect2:
	var side := minf(size.x, size.y) * 0.86
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))


## Radio de la zona donde se desparraman los ingredientes (igual que en Art.draw_pizza con la masa estirada)
func food_radius() -> float:
	return _rect().size.x * 0.48 * 0.72


func rel_point(local: Vector2) -> Vector2:
	return (local - _rect().get_center()) / food_radius()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") in ["sauce", "dough"]


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit()


func _draw() -> void:
	var r := _rect()
	var c := r.get_center()
	# Mármol enharinado
	draw_circle(c + Vector2(4, 8), r.size.x * 0.56, Color(0, 0, 0, 0.25))
	draw_circle(c, r.size.x * 0.56, Color("e9e6e0"))
	for k in 6:
		draw_arc(c + Vector2(k * 9 - 20, k * 7 - 18), r.size.x * (0.2 + k * 0.05), k, k + 1.4, 12, Color(0.55, 0.55, 0.6, 0.18), 1.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 60:
		var a := rng.randf() * TAU
		draw_circle(c + Vector2.from_angle(a) * sqrt(rng.randf()) * r.size.x * 0.52, rng.randf_range(0.8, 2.0), Color(1, 1, 1, 0.7))
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if dd is Dictionary and dd.get("kind", "") in ["sauce", "dough"]:
			draw_arc(c, r.size.x * 0.55, 0, TAU, 48, Color(1, 0.85, 0.3, 0.6 + 0.3 * sin(Time.get_ticks_msec() / 150.0)), 5)
	if pizza == null:
		Art.text(self, Vector2(0, c.y + 6), "Arrastrá un bollo de masa", 20, Color(0.35, 0.3, 0.25), HORIZONTAL_ALIGNMENT_CENTER, size.x)
		return
	# Al tocarla, la masa se aplasta un poquito (se nota el golpe)
	var grow := r.size.x * 0.03 * _tap
	Art.draw_pizza(self, r.grow(grow), pizza)
	if pizza["stretch"] < 1.0:
		Art.text(self, Vector2(0, r.end.y + 4), "Tocá la masa para estirarla (%d de 6)" % int(round(pizza["stretch"] * 6.0)),
			16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
