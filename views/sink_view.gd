extends Control
## Pileta de la Bacha. Se arrastra algo sucio, se le pone detergente a la esponja, se friegan las
## manchas (salen sólo donde pasa la esponja), se enjuaga bajo el chorro y se lleva al escurridor.
## La pieza en la pileta es un diccionario de main: {kind, seed, spots, bubbles, dirt, foam}.

signal faucet_pressed
signal dropped(data: Dictionary)

const Art = preload("res://art.gd")
const S := 160.0                     # tamaño de referencia de la pieza (unidades de las manchas)
const STREAM_OFF := Vector2(52.0 / S, 0.0)   # el chorro cae a la derecha del centro de la pieza
const SPONGE_R := 0.17               # radio de la esponja en unidades de S (grande: agarra varias manchas)
const SCRUB_PX := 95.0               # px de frotado (con detergente) para sacar una mancha
const SOAP_ITEMS := 2.0              # una carga de detergente alcanza para lavar 2 cosas enteras
const MAX_STACK := 5                 # cuántas piezas del mismo tipo entran juntas en la pileta

var item = null
var flow := 0.0          # 0-1, cuánto agua sale
var pool := 0.0          # agua acumulada en el fondo
var soap := 0.0          # detergente en la esponja (sólo para los carteles)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _basin() -> Rect2:
	return Rect2(Vector2(0, size.y * 0.25), Vector2(size.x, size.y * 0.75))


func item_rect() -> Rect2:
	var c := _basin().get_center() + Vector2(0, -6)
	return Rect2(c - Vector2(90, 80), Vector2(180, 160))


## Zona de la palanca del grifo
func faucet_rect() -> Rect2:
	var piv := Vector2(size.x / 2.0, _basin().position.y + 6) + Vector2(-40, -14)
	return Rect2(piv + Vector2(-40, -34), Vector2(60, 54))


## Punto local -> coordenadas de la pieza (centro = 0, unidades de S)
func to_item(local: Vector2) -> Vector2:
	return (local - item_rect().get_center()) / S


func is_over_item(local: Vector2) -> bool:
	return item != null and item_rect().grow(20).has_point(local)


func is_clean() -> bool:
	return item != null and item["dirt"] <= 0.0 and item["bubbles"].is_empty()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if faucet_rect().has_point(mb.position):
			accept_event()
			faucet_pressed.emit()
	var mm := event as InputEventMouseMotion
	if mm != null:
		var hand := faucet_rect().has_point(mm.position) or (is_clean() and item_rect().has_point(mm.position))
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hand else Control.CURSOR_ARROW


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "dirty" and can_stack(item, data.get("tool", ""))


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _get_drag_data(at: Vector2) -> Variant:
	if not is_clean() or not item_rect().has_point(at):
		return null
	var k: String = item["kind"]
	var cnt: int = item.get("count", 1)
	var p = load("res://views/painter.gd").new()
	p.size = Vector2(110, 100)
	p.position = Vector2(-55, -50)
	p.animate = true
	p.fn = func(ci, t):
		for j in range(cnt - 1, 0, -1):
			Art.draw_tool(ci, Rect2(-5.0 * j, 4.0 * j, 110, 100), k, 0.0, 0.0, false)
		Art.draw_tool(ci, Rect2(0, 0, 110, 100), k, 0.0, 0.0, true)
		if cnt > 1:
			Art.text(ci, Vector2(70, 10), "x%d" % cnt, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		for d in 3:      # gotea mientras se lleva
			var ph := fmod(t * 1.6 + d * 0.33, 1.0)
			ci.draw_circle(Vector2(40 + d * 15, 84 + ph * 40), 2.2, Color(0.7, 0.88, 1.0, 1.0 - ph))
	var ghost := Control.new()
	ghost.add_child(p)
	set_drag_preview(ghost)
	return {"kind": "clean", "tool": k, "count": cnt}


# ---------------------------------------------------------------------
# Lógica (estática: main la usa aunque no se esté mirando la Bacha)
# ---------------------------------------------------------------------

static func new_item(kind: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return {"kind": kind, "seed": seed, "spots": Art.make_dirt(kind, rng), "bubbles": [], "dirt": 1.0, "foam": 0.0, "count": 1}


## ¿Se puede sumar otra pieza de este tipo a la pileta? (sólo del mismo tipo, hasta MAX_STACK)
static func can_stack(it, kind: String) -> bool:
	return it == null or (it["kind"] == kind and it.get("count", 1) < MAX_STACK)


## Suma una pieza sucia a la pila: la mugre se reparte (la pila queda más sucia en promedio)
static func add_to_stack(it: Dictionary) -> void:
	var n: int = it.get("count", 1)
	for sp in it["spots"]:
		sp["hp"] = minf(1.0, (sp["hp"] * n + 1.0) / (n + 1))
	it["count"] = n + 1
	_recalc(it)


## Frotar con la esponja en off (unidades de S), habiéndola movido moved px.
## soap > 0: la pieza tiene detergente (una carga de la esponja alcanza para SOAP_ITEMS piezas enteras).
static func scrub(it: Dictionary, off: Vector2, moved: float, soap: float, rng: RandomNumberGenerator) -> void:
	var eff := 1.0 if soap > 0.0 else 0.15         # sin detergente la grasa casi no sale
	for sp in it["spots"]:
		if sp["hp"] > 0.0 and (sp["o"] - off).length() < SPONGE_R + sp["r"]:
			sp["hp"] -= moved / SCRUB_PX * eff / it.get("count", 1)   # varias juntas: tarda proporcional
			if sp["hp"] < 0.04:
				sp["hp"] = 0.0
	if soap > 0.0 and off.length() < 0.5:
		var bubbles: Array = it["bubbles"]
		var n := int(moved / 7.0)
		for k in n:
			if bubbles.size() >= 120:
				# Ya está llena de espuma: se refresca la que está bajo la esponja
				var b: Dictionary = bubbles[rng.randi() % bubbles.size()]
				b["life"] = 1.0
				continue
			bubbles.append({"o": off + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * SPONGE_R,
				"r": rng.randf_range(3.0, 8.0), "life": 1.0})
	_recalc(it)


## Enjuague: el chorro se lleva la espuma (rápido donde cae, más lento alrededor; la esponja bajo el agua ayuda)
static func rinse(it: Dictionary, delta: float, flow: float, sponge = null) -> void:
	if flow <= 0.0:
		_recalc(it)
		return
	# Ya fregado y bajo el chorro: queda limpio en el acto (no hace falta esperar)
	if it["dirt"] <= 0.0 and flow >= 0.5:
		it["bubbles"] = []
		_recalc(it)
		return
	var keep := []
	for b in it["bubbles"]:
		var d: Vector2 = b["o"] - STREAM_OFF
		var near := maxf(0.0, 1.0 - d.length() / 0.2)
		var speed := flow * (0.7 + 4.0 * near)
		if sponge != null and (b["o"] - sponge).length() < SPONGE_R * 1.4:
			speed += flow * 3.5
		b["life"] -= delta * speed
		# El agua empuja la espuma hacia afuera y para abajo
		b["o"] += (d.normalized() * 0.18 + Vector2(0, 0.08)) * delta * flow
		if b["o"].length() > 0.5:
			b["life"] -= delta * 2.0
		if b["life"] > 0.0:
			keep.append(b)
	it["bubbles"] = keep
	# El agua sola ablanda un poquito la mugre
	for sp in it["spots"]:
		if sp["hp"] > 0.0:
			sp["hp"] = maxf(0.0, sp["hp"] - delta * 0.02 * flow)
	_recalc(it)


static func _recalc(it: Dictionary) -> void:
	var total := 0.0
	for sp in it["spots"]:
		total += sp["hp"]
	it["dirt"] = total / maxf(1.0, it["spots"].size())
	if it["dirt"] < 0.005:
		it["dirt"] = 0.0
	it["foam"] = minf(1.0, it["bubbles"].size() / 40.0)


# ---------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var soapy: bool = item != null and not item["bubbles"].is_empty()
	Art.draw_sink(self, Rect2(Vector2.ZERO, size), flow, t, pool, soapy or pool > 0.3)
	var ir := item_rect()
	var hint := "Arrastrá algo sucio a la pileta"
	if item != null:
		var cnt: int = item.get("count", 1)
		for j in range(cnt - 1, 0, -1):     # las de abajo de la pila, corridas
			Art.draw_tool(self, Rect2(ir.position + Vector2(-7.0 * j, 6.0 * j), ir.size), item["kind"], minf(1.0, item["dirt"] * 1.3), 0.0, false, item["seed"] + j)
		Art.draw_tool(self, ir, item["kind"], 0.0, 0.0, is_clean())
		if cnt > 1:
			Art.rrect(self, Rect2(ir.end.x - 44, ir.position.y - 4, 46, 26), Color(0.12, 0.09, 0.07, 0.85), 8)
			Art.text(self, Vector2(ir.end.x - 44, ir.position.y + 16), "x%d" % cnt, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 46)
		Art.draw_dirt_spots(self, ir, item["spots"])
		Art.draw_bubbles(self, ir, item["bubbles"])
		if is_clean():
			# Mojado: gotitas que brillan
			for k in 6:
				var p := ir.get_center() + Vector2(sin(k * 2.4) * 50, cos(k * 1.7) * 40)
				draw_circle(p, 2.5, Color(0.8, 0.92, 1.0, 0.8))
				draw_circle(p + Vector2(-0.8, -0.8), 1.0, Color(1, 1, 1, 0.9))
		if item["dirt"] > 0.0:
			hint = "Tocá el detergente para cargar la esponja" if soap <= 0.0 else "Frotá las manchas con la esponja"
		elif not item["bubbles"].is_empty():
			hint = "Enjuagando... pasá la esponja bajo el chorro" if flow > 0.5 else "Levantá la palanca del grifo para enjuagar"
		else:
			hint = "¡Limpio! Arrastralo al escurridor" + ("  (y cerrá el grifo)" if flow > 0.5 else "")
		# Barrita de limpieza
		var bar := Rect2(ir.position.x + 20, ir.end.y + 8, ir.size.x - 40, 8)
		Art.rrect(self, bar.grow(2), Color(0, 0, 0, 0.5), 4)
		var clean_frac: float = (1.0 - item["dirt"]) * (0.8 if not item["bubbles"].is_empty() else 1.0)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clean_frac, bar.size.y)), Color("5ec8e0"))
	# Chorro: cae hasta la pieza (o el fondo) y salpica
	if flow > 0.02:
		var mouth := Art.sink_stream(Rect2(Vector2.ZERO, size))
		var bottom: float = ir.get_center().y + 10.0 if item != null else _basin().end.y - 40.0
		var w := 1.5 + 3.5 * flow
		for k in 4:
			var x := mouth.x - w + k * w * 0.66 + sin(t * 30.0 + k) * 0.8
			draw_line(Vector2(x, mouth.y), Vector2(x, bottom), Color(0.72, 0.88, 1.0, 0.35 + 0.3 * flow), 2.0)
		draw_line(Vector2(mouth.x - w * 0.4, mouth.y), Vector2(mouth.x - w * 0.4, bottom), Color(1, 1, 1, 0.45 * flow), 1.0)
		for k in 7:
			var ph := fmod(t * 2.2 + k / 7.0, 1.0)
			draw_arc(Vector2(mouth.x, bottom), 5 + ph * 34 * flow, PI * 1.05, PI * 1.95, 10, Color(1, 1, 1, 0.5 * (1.0 - ph)), 1.5)
		for k in 6:
			var ph := fmod(t * 3.1 + k / 6.0, 1.0)
			var dir := Vector2(sin(k * 2.9) * 40.0, -30.0 - 20.0 * fmod(k * 0.37, 1.0))
			var p := Vector2(mouth.x, bottom) + dir * ph + Vector2(0, 60.0 * ph * ph)
			draw_circle(p, 1.8, Color(0.8, 0.92, 1.0, 0.8 * (1.0 - ph)))
	Art.text(self, Vector2(0, size.y - 8), hint, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 5)
