extends Control
## Un plato visto desde arriba con lo que tiene servido.
## Con accept_drops = true recibe lo que se arrastra encima y avisa con `dropped(data)`.

signal dropped(data: Dictionary)

const Art = preload("res://art.gd")

var items: Array = []        # preparaciones {item, t, vtarget, burn, chopped, ...}
var sauce := ""
var toppings: Array = []
var sprinkles: Dictionary = {}   # toppings desparramados a mano: {nombre: {amount, pts}}
var seed := 1
var gold := false                # vajilla con borde dorado (mejora)
var accept_drops := false:
	set(value):
		accept_drops = value
		mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

var _splash := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_splash = maxf(_splash - delta * 2.5, 0.0)
	if accept_drops:
		queue_redraw()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return accept_drops and data is Dictionary and data.has("kind") and data["kind"] != "plate"


## El plato entero se puede arrastrar (por ejemplo, al cesto de basura)
func _get_drag_data(_at: Vector2) -> Variant:
	if not accept_drops or (items.is_empty() and sprinkles.is_empty() and sauce == ""):
		return null
	var ghost = get_script().new()
	ghost.items = items
	ghost.sauce = sauce
	ghost.sprinkles = sprinkles
	ghost.seed = seed
	ghost.size = Vector2(150, 150)
	ghost.position = -ghost.size / 2.0
	ghost.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()
	holder.add_child(ghost)
	set_drag_preview(holder)
	return {"kind": "plate"}


func _drop_data(_at: Vector2, data: Variant) -> void:
	_splash = 1.0
	dropped.emit(data)


## Radio de la zona de comida (donde se desparraman los toppings), en píxeles del control.
func food_radius() -> float:
	return _plate_rect().size.x * 0.3


## Punto local -> posición relativa a la comida (largo 1 = borde de la zona de comida)
func rel_point(local: Vector2) -> Vector2:
	return (local - _plate_rect().get_center()) / food_radius()


func _plate_rect() -> Rect2:
	var side := minf(size.x, size.y)
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))


func _draw() -> void:
	var rect := _plate_rect()
	var c := rect.get_center()
	if accept_drops and get_viewport().gui_is_dragging():
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		draw_circle(c, rect.size.x * 0.52, Color(1.0, 0.85, 0.3, 0.18 + 0.12 * pulse))
		Art.text(self, Vector2(0, rect.position.y + 4), "Soltalo en el plato", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	Art.draw_tex(self, Art.tex("kitchen/plate"), rect)
	if gold:
		draw_arc(c, rect.size.x * 0.455, 0, TAU, 64, Color("d9a520"), maxf(3.0, rect.size.x * 0.012))
		draw_arc(c, rect.size.x * 0.43, 0, TAU, 64, Color(0.85, 0.65, 0.13, 0.5), 1.5)
	var inner := rect.size.x * 0.34
	var n := items.size()
	var item_size := inner * (1.15 if n <= 1 else (0.95 if n == 2 else 0.8))
	var spots := _spots(n, inner * 0.5)
	for i in n:
		var p: Vector2 = c + spots[i]
		Art.ellipse(self, p + Vector2(3, 6) * item_size / 100.0, Vector2(item_size * 0.42, item_size * 0.36), Color(0, 0, 0, 0.16))
		Art.draw_entry(self, items[i], Rect2(p - Vector2.ONE * item_size / 2.0, Vector2.ONE * item_size))
	if sauce != "":
		var sp: Vector2 = c + (spots[0] if n > 0 else Vector2.ZERO)
		Art.draw_sauce(self, sp, item_size * 0.22, Art.SAUCE_COLORS.get(sauce, Color.WHITE), seed)
	if not sprinkles.is_empty():
		Art.draw_sprinkles(self, c, food_radius(), sprinkles)
	if _splash > 0.0:
		draw_arc(c, rect.size.x * (0.3 + 0.25 * (1.0 - _splash)), 0, TAU, 40, Color(1, 1, 1, _splash * 0.8), 4)


func _spots(n: int, r: float) -> Array:
	match n:
		0, 1:
			return [Vector2.ZERO]
		2:
			return [Vector2(-r * 0.75, 0), Vector2(r * 0.75, 0)]
		3:
			return [Vector2(0, -r * 0.7), Vector2(-r * 0.8, r * 0.5), Vector2(r * 0.8, r * 0.5)]
	var out := []
	for i in n:
		var a := -PI / 2.0 + TAU * i / n
		out.append(Vector2(cos(a), sin(a)) * r)
	return out
