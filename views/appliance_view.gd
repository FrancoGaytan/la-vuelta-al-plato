extends Control
## Un aparato de cocina (olla, plancha, freidora u horno) con sus lugares de cocción.
## Tamaño de diseño: 236 x 330. Avisa con slot_clicked(index) cuando tocan un lugar ocupado.

signal slot_clicked(index: int)
signal ingredient_dropped(item_id: String)

const Art = preload("res://art.gd")
const Data = preload("res://data.gd")

var kind := "olla"
var slots: Array = []       # referencia a main.cookers[kind]: null o {item, t, target, burn}
var show_zone := true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(236, 330)


func _process(_delta: float) -> void:
	# Animación de la pala al girar una pizza
	for s in slots:
		if s != null and s.has("rot"):
			s["rot_vis"] = lerpf(s.get("rot_vis", 0.0), s["rot"], 0.25)
		if s != null and s.get("flip_vis", 0.0) > 0.0:
			s["flip_vis"] = maxf(0.0, s["flip_vis"] - _delta * 4.0)
	queue_redraw()


# --- Geometría de cada aparato ---

func _center(i: int) -> Vector2:
	match kind:
		"olla":
			if slots.size() >= 4:
				return [Vector2(62, 88), Vector2(174, 88), Vector2(62, 226), Vector2(174, 226)][i]
			return [Vector2(62, 88), Vector2(174, 88), Vector2(118, 226)][i]
		"plancha":
			return [Vector2(64, 76), Vector2(172, 76), Vector2(64, 210), Vector2(172, 210)][i]
		"freidora":
			return Vector2(_vat_x(i), _basket_y(i) + 40)
		"horno_lena":
			return [Vector2(44, 236), Vector2(118, 246), Vector2(192, 236)][i]
		"comal":
			return [Vector2(72, 92), Vector2(164, 92), Vector2(72, 206), Vector2(164, 206)][i]
		"licuadora":
			return [Vector2(62, 150), Vector2(174, 150)][i]
		"crepera":
			return [Vector2(118, 82), Vector2(118, 222)][i]
	return Vector2(64, 108 + i * 84)


# Freidora: 2 cubas con 2 canastos cada una
func _vat_x(i: int) -> float:
	return 64.0 + (i / 2) * 108.0


func _basket_y(i: int) -> float:
	return 18.0 + (i % 2) * 114.0


func _food_rect(i: int) -> Rect2:
	var c := _center(i)
	match kind:
		"crepera":
			return Rect2(c - Vector2(54, 54), Vector2(108, 108))
		"licuadora":
			return Rect2(c - Vector2(40, 60), Vector2(80, 120))
		"comal":
			return Rect2(c - Vector2(40, 40), Vector2(80, 80))
		"olla":
			return Rect2(c - Vector2(30, 30), Vector2(60, 60))
		"plancha":
			return Rect2(c - Vector2(40, 40), Vector2(80, 80))
		"freidora":
			return Rect2(c - Vector2(36, 32), Vector2(72, 64))
	if kind == "horno_lena":
		return Rect2(c - Vector2(34, 34), Vector2(68, 68))
	return Rect2(c - Vector2(34, 32), Vector2(68, 64))


func _chip_rect(i: int) -> Rect2:
	var c := _center(i)
	match kind:
		"crepera":
			return Rect2(c.x + 30, c.y + 34, 88, 28)
		"licuadora":
			return Rect2(c.x - 52, 290, 104, 30)
		"comal":
			return Rect2(c.x - 44, c.y + 40, 88, 28)
		"olla":
			return Rect2(c.x - 50, c.y + 54, 100, 30)
		"plancha":
			return Rect2(c.x - 50, c.y + 44, 100, 30)
		"freidora":
			return Rect2(c.x - 50, _basket_y(i) + 76, 100, 28)
	if kind == "horno_lena":
		return Rect2(c.x - 37, 282, 74, 30)
	return Rect2(108, c.y - 15, 104, 30)


func _hit_rect(i: int) -> Rect2:
	match kind:
		"crepera":
			return Rect2(_center(i) - Vector2(66, 66), Vector2(184, 132))
		"licuadora":
			return Rect2(_center(i).x - 54, 30, 108, 292)
		"comal":
			return Rect2(_center(i) - Vector2(46, 44), Vector2(92, 112))
		"olla":
			return Rect2(_center(i) - Vector2(54, 54), Vector2(108, 140))
		"plancha":
			return Rect2(_center(i) - Vector2(50, 48), Vector2(100, 124))
		"freidora":
			return Rect2(_vat_x(i) - 52, _basket_y(i), 104, 108)
	if kind == "horno_lena":
		return Rect2(_center(i).x - 37, 198, 74, 116)
	return Rect2(20, _center(i).y - 40, 196, 82)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		var mm := event as InputEventMouseMotion
		if mm != null:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _slot_at(mm.position) >= 0 else Control.CURSOR_ARROW
		return
	var i := _slot_at(mb.position)
	if i >= 0:
		accept_event()
		if kind == "horno_lena" and not _chip_rect(i).has_point(mb.position):
			# Tocar la pizza: se gira con la pala (la otra mitad pasa a mirar al fuego)
			var s: Dictionary = slots[i]
			var ta: float = s["ta"]
			s["ta"] = s["tb"]
			s["tb"] = ta
			s["rot"] = s.get("rot", 0.0) + PI
			return
		if kind in ["comal", "crepera"] and not _chip_rect(i).has_point(mb.position):
			# Tocar la tortilla: se da vuelta (el lado cocido queda arriba)
			var st: Dictionary = slots[i]
			var a: float = st["ta"]
			st["ta"] = st["tb"]
			st["tb"] = a
			st["flip_vis"] = 1.0
			return
		slot_clicked.emit(i)


## Lugar ocupado que está debajo del mouse (lo usa el salero)
func slot_under_mouse() -> int:
	return _slot_at(get_local_mouse_position())


func _slot_at(p: Vector2) -> int:
	for i in slots.size():
		if slots[i] != null and _hit_rect(i).has_point(p):
			return i
	return -1


# --- Dibujo ---

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	match kind:
		"olla": _draw_stove(t)
		"plancha": _draw_griddle(t)
		"freidora": _draw_fryer(t)
		"horno": _draw_oven(t)
		"horno_lena": _draw_wood_oven(t)
		"comal": _draw_comal(t)
		"licuadora": _draw_blenders(t)
		"crepera": _draw_crepera(t)
	for i in slots.size():
		if slots[i] != null:
			_draw_chip(_chip_rect(i), slots[i], t)
	# Mientras se arrastra un ingrediente, el aparato donde va se ilumina
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if dd is Dictionary and dd.get("kind", "") == "raw" and Data.ITEMS[dd["item"]].get("where", "") == kind:
			var pulse := 0.5 + 0.5 * sin(t * 8.0)
			Art.rrect(self, Rect2(-4, -4, size.x + 8, size.y + 8), Color(0.4, 1, 0.4, 0.1 + 0.1 * pulse), 14, Color("5ee06a"), 4)
			Art.text(self, Vector2(0, size.y / 2.0), "Soltalo acá", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 5)


func _food(i: int, s) -> void:
	var rect := _food_rect(i)
	if s.get("flip", false):
		# Tortilla: se ve el lado de arriba; el borde muestra cómo va el de abajo. Al darla vuelta se aplana y gira.
		var fv: float = s.get("flip_vis", 0.0)
		var sy := absf(cos(fv * PI))
		var ctr := rect.get_center()
		draw_set_transform(ctr - Vector2(0, sin(fv * PI) * 18.0), 0.0, Vector2(1.0, maxf(sy, 0.08)))
		var lr := Rect2(-rect.size / 2.0, rect.size)
		Art.draw_cooking(self, s["item"], lr, s["tb"], s["target"], s["burn"])
		draw_arc(Vector2.ZERO, rect.size.x * 0.41, 0, TAU, 36, Color(Art._crust_color(s["ta"], s["target"], s["burn"]), 0.85), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	Art.draw_cooking(self, s["item"], rect, s["t"], s["target"], s["burn"])
	# Granitos de sal encima (en la olla se disuelven: brillan un rato)
	var pts: Array = s.get("salt_pts", [])
	for k in pts.size():
		var p: Vector2 = rect.get_center() + pts[k] * rect.size * 0.5
		if kind == "olla":
			var a := clampf(1.0 - (k + 1) / float(pts.size() + 1), 0.0, 1.0) * 0.6
			draw_circle(p, 1.2, Color(1, 1, 1, a))
		else:
			draw_circle(p, 1.3, Color(1, 1, 1, 0.9))
			draw_circle(p + Vector2(0.5, 0.5), 0.6, Color(0.7, 0.75, 0.8, 0.8))
	var info: Dictionary = Data.ITEMS[s["item"]]
	if info.has("temps"):
		# Termómetro clavado en la carne
		var marks := []
		for dn in info.get("doneness_temp", {}):
			marks.append([info["doneness_temp"][dn], dn])
		if info.has("target_temp"):
			marks.append([info["target_temp"], ""])
		Art.draw_thermometer(self, rect.position + Vector2(rect.size.x - 2, 4), rect.get_center() + Vector2(-6, 8),
			Data.temp_at(s["item"], s["t"]), marks, show_zone)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "raw" and Data.ITEMS[data["item"]]["kind"] == "cook"


func _drop_data(_at: Vector2, data: Variant) -> void:
	ingredient_dropped.emit(data["item"])


func _burning(s) -> bool:
	if s.has("ta"):
		return maxf(s["ta"], s["tb"]) >= s["burn"] - 3.0
	return s["t"] >= s["burn"] - 3.0


## Horno de leña: cúpula de ladrillos, fuego a la izquierda y las pizzas sobre la piedra
func _draw_wood_oven(t: float) -> void:
	# Base de piedra
	Art.rrect(self, Rect2(0, 186, 236, 144), Color("8d8478"), 10, Color("6b6358"), 3)
	for k in 6:
		draw_line(Vector2(6, 210 + k * 20), Vector2(230, 210 + k * 20), Color(0, 0, 0, 0.12), 2)
	# Cúpula de ladrillos
	var dome := PackedVector2Array()
	for k in 33:
		var a := PI + PI * k / 32.0
		dome.append(Vector2(118, 196) + Vector2(cos(a) * 116, sin(a) * 170))
	draw_colored_polygon(dome, Color("b35a3a"))
	for row in 8:
		var y := 196.0 - row * 21.0
		var half := sqrt(maxf(0.0, 1.0 - pow((196.0 - y) / 170.0, 2.0))) * 116.0
		draw_line(Vector2(118 - half, y), Vector2(118 + half, y), Color("8a3e26"), 2)
		var off := 0.0 if row % 2 == 0 else 13.0
		var x := 118 - half + off
		while x < 118 + half:
			draw_line(Vector2(x, y), Vector2(x, y - 21), Color("8a3e26"), 2)
			x += 26.0
	draw_polyline(dome, Color("6a2e1c"), 3, true)
	# Chimenea con humo
	draw_rect(Rect2(150, 8, 28, 40), Color("7a3a24"))
	draw_rect(Rect2(146, 4, 36, 8), Color("5a2a1a"))
	Art.steam(self, Vector2(164, 0), t, 1.0, 3, Color(0.75, 0.75, 0.75))
	# Boca del horno: arco oscuro con el fuego adentro, a la izquierda
	var mouth := PackedVector2Array()
	for k in 25:
		var a := PI + PI * k / 24.0
		mouth.append(Vector2(118, 196) + Vector2(cos(a) * 92, sin(a) * 96))
	draw_colored_polygon(mouth, Color("1d1410"))
	var any_on := false
	for s in slots:
		if s != null:
			any_on = true
	var glow := 0.25 + 0.08 * sin(t * 6.0) + (0.12 if any_on else 0.0)
	draw_circle(Vector2(58, 168), 70, Color(1.0, 0.45, 0.1, glow * 0.5))
	# Leños y llamas (el lado izquierdo es el que más calienta)
	for k in 3:
		Art.rrect(self, Rect2(Vector2(30 + k * 14, 172 - k * 4), Vector2(46, 11)), Color("5a3a22"), 5)
	for k in 9:
		var fx := 36.0 + k * 7.0
		var h := 30.0 + 18.0 * absf(sin(t * 7.0 + k * 1.3))
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 7, 176), Vector2(fx, 176 - h), Vector2(fx + 7, 176)]), Color(1.0, 0.5 + 0.1 * sin(k), 0.1, 0.85))
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 3, 176), Vector2(fx, 176 - h * 0.55), Vector2(fx + 3, 176)]), Color(1.0, 0.9, 0.4, 0.9))
	for k in 10:
		draw_circle(Vector2(40 + fmod(k * 37.0, 120.0), 186 - fmod(t * 40.0 + k * 17.0, 60.0)), 1.4, Color(1.0, 0.6, 0.2, 0.8))
	draw_polyline(mouth, Color("e0a070"), 4, true)
	# Piso de piedra donde van las pizzas (la luz del fuego le pega del lado izquierdo)
	Art.grad_rect(self, Rect2(6, 200, 224, 76), Color("cbbfa8"), Color("9a8e78"))
	draw_rect(Rect2(6, 200, 100, 76), Color(1.0, 0.5, 0.15, 0.12 + 0.04 * sin(t * 6.0)))
	for i in slots.size():
		var s = slots[i]
		if s == null:
			Art.ellipse(self, _center(i) + Vector2(0, 4), Vector2(30, 10), Color(0, 0, 0, 0.12))
			continue
		var rect := _food_rect(i)
		var rv: float = s.get("rot_vis", 0.0)
		Art.draw_pizza(self, rect, s.get("pizza", {}), s["ta"], s["tb"], s["target"], s["burn"], rv)
		Art.steam(self, rect.get_center() + Vector2(0, -18), t, 0.6 if not _burning(s) else 1.5, i + 4,
			Color.WHITE if maxf(s["ta"], s["tb"]) < s["burn"] else Color(0.3, 0.3, 0.3))


func _draw_stove(t: float) -> void:
	Art.rrect(self, Rect2(0, 0, 236, 330), Color("2b2d31"), 12, Color("9aa3ab"), 4)
	for k in 2:
		var kx := 22.0 + k * 192.0
		draw_circle(Vector2(kx, 306), 11, Color("c5ccd2"))
		draw_line(Vector2(kx, 306), Vector2(kx, 297), Color("3a3f45"), 3)
	# Brillo del esmalte negro de la cocina
	Art.grad_rect(self, Rect2(6, 6, 224, 120), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0))
	for i in slots.size():
		var c := _center(i)
		var s = slots[i]
		# Quemador: tapa de bronce y anillo
		draw_circle(c, 50, Color("151618"))
		draw_circle(c, 30, Color("3a2f22"))
		draw_arc(c, 30, 0, TAU, 32, Color("b08a4a"), 3)
		draw_circle(c, 18, Color("7a6440"))
		if s != null:
			Art.flames(self, c, 46, t)
			draw_circle(c, 52, Color(1.0, 0.45, 0.1, 0.08 + 0.03 * sin(t * 9.0 + i)))
		# Parrilla de hierro fundido: marco cuadrado y dedos hacia el centro
		var hot := Color("5a3a2a") if s != null else Color("3c3f44")
		draw_rect(Rect2(c - Vector2(52, 52), Vector2(104, 104)), hot, false, 5)
		draw_rect(Rect2(c - Vector2(52, 52), Vector2(104, 3)), Color(1, 1, 1, 0.1))
		for a in 8:
			var d := Vector2.from_angle(a * PI / 4.0)
			var reach := 52.0 if a % 2 == 0 else 72.0
			draw_line(c + d * 22, c + d * reach, hot, 5)
			draw_line(c + d * 22, c + d * reach, Color(1, 1, 1, 0.08), 1.5)
		_draw_pot(i, c, s, t)


## Olla de acero vista desde arriba, con agua que hierve y la comida adentro.
func _draw_pot(i: int, c: Vector2, s, t: float) -> void:
	var r := 46.0
	var on: bool = s != null
	# Manijas: soporte de acero con remaches y grip de goma
	for side in [-1, 1]:
		var bx: float = c.x + side * 44.0
		Art.rrect(self, Rect2(Vector2(bx - (16 if side < 0 else 0), c.y - 9), Vector2(16, 18)), Color("9aa5ae"), 4, Color("6f7b85"), 1)
		draw_circle(Vector2(bx + side * 4, c.y - 4), 1.8, Color("e6ebef"))
		draw_circle(Vector2(bx + side * 4, c.y + 4), 1.8, Color("e6ebef"))
		var gx: float = c.x + side * 55.0 - (15 if side < 0 else 0)
		Art.rrect(self, Rect2(Vector2(gx, c.y - 8), Vector2(15, 16)), Color("23252a"), 7)
		draw_line(Vector2(gx + 3, c.y - 5), Vector2(gx + 12, c.y - 5), Color(1, 1, 1, 0.18), 2)
	# Cuerpo: sombra, pared exterior, borde enrollado, pared interna con sombreado y fondo
	draw_circle(c + Vector2(3, 5), r + 1, Color(0, 0, 0, 0.45))
	draw_circle(c, r, Color("6f7b85"))
	for k in 6:
		var f := float(k) / 5.0
		draw_circle(c + Vector2(-1.5, -1.5) * f, r - 0.5 - k * 0.6, Color("8d98a3").lerp(Color("eef2f5"), f))
	draw_arc(c, r - 1.5, PI * 0.85, PI * 1.65, 24, Color(1, 1, 1, 0.95), 2.5)
	draw_arc(c, r - 1.5, PI * 1.9, PI * 2.2, 10, Color(1, 1, 1, 0.5), 1.5)
	# Pared interna: más oscura abajo a la derecha (la luz viene de arriba a la izquierda)
	for k in 5:
		var f := float(k) / 4.0
		draw_circle(c + Vector2(1.5, 2.5) * f, r - 5.0 - k * 0.8, Color("aab4bc").lerp(Color("66727c"), f))
	var wr := r - 9.0
	var heat := clampf(s["t"] / 2.0, 0.0, 1.0) if on else 0.0
	var p := clampf(s["t"] / s["target"], 0.0, 1.0) if on else 0.0
	# Agua: se pone turbia con el almidón de la pasta
	var water := Color("5f93a6").lerp(Color("a9c3c6"), p * 0.7)
	draw_circle(c, wr, water)
	draw_circle(c + Vector2(-wr * 0.2, -wr * 0.2), wr * 0.7, Color(1, 1, 1, 0.06))
	if on:
		_draw_pot_food(s, c, wr - 3.0, t, true)
	# Capa de agua por encima: lo de adentro se ve sumergido
	draw_circle(c, wr, Color(water, 0.38))
	# Reflejos de luz que se mueven en el agua y el reflejo del borde de la olla
	for k in 4:
		var a := t * (0.4 + k * 0.13) + k * 1.7 + i
		var p0 := c + Vector2(cos(a), sin(a * 1.3)) * wr * 0.45
		draw_arc(p0, wr * (0.12 + 0.04 * k), a, a + 1.6, 8, Color(1, 1, 1, 0.13), 1.6)
	draw_arc(c, wr - 1.5, PI * 1.05, PI * 1.55, 16, Color(1, 1, 1, 0.35), 2.0)
	if on:
		# Ondas de la superficie y hervor
		for k in 3:
			var ph := fmod(t * 0.9 + k / 3.0 + i * 0.2, 1.0)
			draw_arc(c + Vector2(sin(k * 2.0 + i) * 8, cos(k * 1.7) * 6), wr * (0.2 + 0.7 * ph), 0, TAU, 28,
				Color(1, 1, 1, (1.0 - ph) * 0.22 * heat), 1.5)
		Art.bubbles(self, c, wr * 0.95, t * (0.8 + heat), Color(1, 1, 1, 0.9), int(6 + 16 * heat), i)
		_draw_pot_food(s, c, wr - 3.0, t, false)
		# Espuma blanca del almidón en el borde
		if p > 0.3:
			for k in 16:
				var a := TAU * k / 16.0 + t * 0.2
				draw_circle(c + Vector2.from_angle(a) * (wr - 4.0), 3.0 + 1.5 * sin(t * 3.0 + k), Color(1, 1, 1, 0.45 * minf(p, 1.0)))
		Art.steam(self, c + Vector2(0, -26), t, (0.4 + 0.8 * heat) if not _burning(s) else 1.6, i,
			Color.WHITE if s["t"] < s["burn"] else Color(0.35, 0.35, 0.35))
	Art.ellipse(self, c + Vector2(-wr * 0.35, -wr * 0.45), Vector2(wr * 0.35, wr * 0.12), Color(1, 1, 1, 0.16))


## Comida dentro de la olla. `under` = la parte sumergida; si no, lo que flota o asoma.
func _draw_pot_food(s, c: Vector2, wr: float, t: float, under: bool) -> void:
	var item: String = s["item"]
	var ct: float = s["t"]
	var p := clampf(ct / s["target"], 0.0, 1.0)
	match item:
		"spaghetti":
			var col := Color("eccf82").lerp(Color("f7e2a2"), p)
			if ct > s["target"]:
				col = col.lerp(Color("ece6d2"), clampf((ct - s["target"]) / (s["burn"] - s["target"]), 0.0, 1.0))
			if ct >= s["burn"]:
				col = Color("6b4a2a")
			if p < 0.35:
				# Fideos secos apoyados en la olla, asomando por el borde; se van hundiendo
				if not under:
					var out := wr * (1.7 - 2.6 * p)
					for k in 16:
						var a := -0.55 + k * 0.07
						var d := Vector2.from_angle(a)
						var base := c + Vector2(-wr * 0.3, wr * 0.3) + Vector2(0, k - 8) * 0.8
						draw_line(base, base + d * out, col.darkened(0.1), 2.6)
						draw_line(base, base + d * out, col, 1.6)
			elif under:
				# Fideos blandos sueltos en el agua: curvas al azar que se mueven con el hervor
				var rng := RandomNumberGenerator.new()
				rng.seed = 77
				var soft := clampf((p - 0.35) / 0.65, 0.0, 1.0)
				for k in 22:
					var pos := c + Vector2.from_angle(rng.randf() * TAU) * wr * 0.75 * sqrt(rng.randf())
					var dir := rng.randf() * TAU + sin(t * 0.7 + k) * 0.3
					var bend := rng.randf_range(-0.5, 0.5) * (0.4 + soft)
					var pts := PackedVector2Array()
					for j in 14:
						pts.append(pos)
						dir += bend + 0.25 * sin(j * 0.9 + t * 1.8 + k) * soft
						pos += Vector2.from_angle(dir) * 4.5
						if pos.distance_to(c) > wr:
							pos = c + (pos - c).limit_length(wr)
							dir += PI * 0.6
					draw_polyline(pts, col.darkened(0.15), 3.0, true)
					draw_polyline(pts, col, 1.8, true)
		"noquis", "ravioles":
			# Crudos quedan quietos en el fondo; cocidos suben y flotan (como en la realidad)
			var floating := p >= 0.85
			if under == floating:
				return
			var n := 8 if item == "noquis" else 6
			var sz := 22.0 if item == "noquis" else 26.0
			for k in n:
				var rr := wr * (0.25 + 0.5 * fmod(k * 0.618, 1.0))
				var a := k * TAU / n + t * 0.6 * p
				var pos := c + Vector2.from_angle(a) * rr + Vector2(0, sin(t * 3.0 + k) * 1.5 * p)
				Art.draw_cooking(self, item, Rect2(pos - Vector2.ONE * sz / 2.0, Vector2.ONE * sz), ct, s["target"], s["burn"])
		"arroz":
			if not under:
				return
			var col := Color("f1ede0").lerp(Color("ffffff"), p)
			if ct >= s["burn"]:
				col = Color("7a5a3a")
			var rng := RandomNumberGenerator.new()
			rng.seed = 31
			for k in 80:
				var rr := wr * 0.9 * sqrt(rng.randf())
				var a := rng.randf() * TAU + t * 0.3 * p * (1.0 - rr / wr)
				var pos := c + Vector2.from_angle(a) * rr + Vector2(sin(t * 2.0 + k), cos(t * 1.7 + k)) * 1.2 * p
				draw_set_transform(pos, a, Vector2.ONE)
				Art.ellipse(self, Vector2.ZERO, Vector2(3.0 + p, 1.4 + 0.4 * p), col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_:
			if under:
				Art.draw_cooking(self, item, Rect2(c - Vector2(28, 28), Vector2(56, 56)), ct, s["target"], s["burn"])


func _draw_griddle(t: float) -> void:
	# Cuerpo de acero cepillado
	Art.rrect(self, Rect2(0, 0, 236, 330), Color("7d8790"), 12, Color("aab3ba"), 4)
	for k in 46:
		draw_line(Vector2(5 + k * 5, 4), Vector2(5 + k * 5, 326), Color(1, 1, 1, 0.03 + 0.02 * (k % 3)), 1)
	# Respaldo y bordes elevados de la plancha
	Art.grad_rect(self, Rect2(6, 6, 224, 12), Color("c5ccd2"), Color("8d98a3"))
	var surf := Rect2(12, 18, 212, 268)
	Art.rrect(self, surf.grow(3), Color("2b2d31"), 4)
	Art.grad_rect(self, surf, Color("454b52"), Color("2c3035"))
	# Estrías de la plancha
	for y in range(int(surf.position.y) + 8, int(surf.end.y), 12):
		draw_line(Vector2(surf.position.x, y), Vector2(surf.end.x, y), Color(0, 0, 0, 0.35), 3)
		draw_line(Vector2(surf.position.x, y - 2), Vector2(surf.end.x, y - 2), Color(1, 1, 1, 0.05), 1)
	# Manchas de curado y charquitos de grasa (siempre en el mismo lugar)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for k in 14:
		var p := surf.position + Vector2(rng.randf() * surf.size.x, rng.randf() * surf.size.y)
		Art.ellipse(self, p, Vector2(rng.randf_range(8, 22), rng.randf_range(5, 12)), Color(0.12, 0.08, 0.04, 0.18))
	for k in 6:
		var p := surf.position + Vector2(rng.randf() * surf.size.x, rng.randf() * surf.size.y)
		Art.ellipse(self, p, Vector2(rng.randf_range(4, 9), rng.randf_range(2, 4)), Color(1, 0.95, 0.8, 0.08 + 0.04 * sin(t * 2.0 + k)))
	draw_line(Vector2(surf.position.x + 10, surf.position.y + 6), Vector2(surf.end.x - 60, surf.position.y + 6), Color(1, 1, 1, 0.1), 3)
	# Frente: perillas, luz piloto y bandeja de goteo con grasa
	var any_on := false
	for s in slots:
		if s != null:
			any_on = true
	Art.rrect(self, Rect2(10, 292, 150, 30), Color("2b2d31"), 6)
	Art.rrect(self, Rect2(16, 298, 138, 14), Color("1d1f22"), 4)
	Art.ellipse(self, Vector2(70, 306), Vector2(40, 4), Color(0.75, 0.55, 0.2, 0.55))
	for kx in [184.0, 214.0]:
		draw_circle(Vector2(kx, 306), 11, Color("1d1f22"))
		draw_circle(Vector2(kx, 305), 9, Color("3a3f45"))
		draw_line(Vector2(kx, 305), Vector2(kx + 5, 298), Color("e3e8ec"), 2)
	draw_circle(Vector2(170, 296), 3.5, Color("ff4a2a") if any_on else Color("5a2a22"))
	for i in 4:
		var s = slots[i]
		if s == null:
			continue
		var c := _center(i)
		# Grasa dorada que se forma alrededor de la comida y sombra de contacto
		Art.ellipse(self, c + Vector2(0, 3), Vector2(46, 40), Color(0.6, 0.4, 0.12, 0.28))
		Art.ellipse(self, c + Vector2(0, 4), Vector2(40, 34), Color(0.1, 0.06, 0.03, 0.45))
		_food(i, s)
		# Aire caliente que ondula arriba de la comida
		for w in 3:
			var pts := PackedVector2Array()
			for j in 8:
				var y := c.y - 10 - j * 5.0 - fmod(t * 30.0 + w * 13.0, 15.0)
				pts.append(Vector2(c.x - 18 + w * 18 + sin(j * 0.9 + t * 6.0 + w) * 3.0, y))
			draw_polyline(pts, Color(1, 1, 1, 0.06), 2.0, true)
		Art.sizzle(self, c, 40, t, i)
		# Salpicaduras de aceite
		for k in 3:
			var ph := fmod(t * 2.5 + k * 0.33 + i * 0.21, 1.0)
			var a := k * 2.1 + i + floorf(t * 2.5 + k * 0.33) * 1.3
			draw_circle(c + Vector2.from_angle(a) * (30 + ph * 26), 1.8 * (1.0 - ph) + 0.4, Color(1, 0.9, 0.6, 0.8 * (1.0 - ph)))
		Art.steam(self, c + Vector2(0, -20), t, 0.7 if not _burning(s) else 1.6, i + 3,
			Color.WHITE if s["t"] < s["burn"] else Color(0.3, 0.3, 0.3))


func _draw_fryer(t: float) -> void:
	Art.rrect(self, Rect2(0, 0, 236, 330), Color("aeb7bf"), 12, Color("7d8790"), 4)
	Art.grad_rect(self, Rect2(6, 254, 224, 70), Color("c5ccd2"), Color("9aa3ab"))
	for v in 2:
		var kx := 64.0 + v * 108.0
		var on: bool = slots[v * 2] != null or slots[v * 2 + 1] != null
		draw_circle(Vector2(kx, 290), 15, Color("2b2d31"))
		draw_line(Vector2(kx, 290), Vector2(kx + 9, 279), Color("e3e8ec"), 3)
		draw_circle(Vector2(kx + 32, 272), 5, Color("ff4a2a") if on else Color("5a2a22"))
		# Cuba de aceite
		var vat := Rect2(kx - 52, 10, 104, 238)
		Art.rrect(self, vat, Color("2f3439"), 8)
		Art.grad_rect(self, vat.grow(-6), Color("c98a22"), Color("7a4808"))
		for k in 5:
			var ph := fmod(t * 0.3 + k * 0.2, 1.0)
			draw_line(Vector2(vat.position.x + 10, vat.position.y + 10 + ph * 220), Vector2(vat.end.x - 10, vat.position.y + 14 + ph * 220),
				Color(1, 0.95, 0.75, 0.08 * (1.0 - absf(ph - 0.5) * 2.0)), 3)
		if not on:
			draw_rect(Rect2(vat.position + Vector2(10, 12), Vector2(84, 5)), Color(1, 1, 1, 0.25))
	for i in 4:
		var s = slots[i]
		if s == null:
			continue
		var basket := Rect2(_vat_x(i) - 44, _basket_y(i) + 4, 88, 72)
		# Aceite agitado alrededor de la comida
		Art.ellipse(self, basket.get_center(), Vector2(46, 38), Color(1.0, 0.8, 0.4, 0.18))
		_food(i, s)
		# Capa de aceite por encima: la comida está sumergida y burbujea
		Art.rrect(self, basket, Color(0.85, 0.55, 0.12, 0.12), 6)
		Art.bubbles(self, basket.get_center(), 40, t * 2.2, Color(1, 0.97, 0.8), 22, i)
		Art.sizzle(self, basket.get_center(), 34, t, i + 2)
		# Canasto de alambre
		for gx in 7:
			var x := basket.position.x + gx * basket.size.x / 6.0
			draw_line(Vector2(x, basket.position.y), Vector2(x, basket.end.y), Color(0.25, 0.25, 0.27, 0.3), 1.2)
		for gy in 6:
			var y := basket.position.y + gy * basket.size.y / 5.0
			draw_line(Vector2(basket.position.x, y), Vector2(basket.end.x, y), Color(0.25, 0.25, 0.27, 0.3), 1.2)
		draw_rect(basket, Color("4a5056"), false, 3)
		Art.steam(self, basket.get_center() + Vector2(0, -24), t, 0.8 if not _burning(s) else 1.6, i + 7,
			Color.WHITE if s["t"] < s["burn"] else Color(0.3, 0.3, 0.3))


func _draw_oven(t: float) -> void:
	Art.rrect(self, Rect2(0, 0, 236, 330), Color("c5ccd2"), 12, Color("7d8790"), 4)
	Art.rrect(self, Rect2(8, 8, 220, 46), Color("2b2d31"), 6)
	Art.rrect(self, Rect2(84, 16, 68, 30), Color("0f1a12"), 4)
	var any_on := false
	for s in slots:
		if s != null:
			any_on = true
	Art.text(self, Vector2(84, 38), "180°" if any_on else "--", 18, Color("7fe0a0") if any_on else Color("2f5a3a"), HORIZONTAL_ALIGNMENT_CENTER, 68)
	for k in 2:
		var kx := 36.0 + k * 164.0
		draw_circle(Vector2(kx, 31), 14, Color("e3e8ec"))
		draw_line(Vector2(kx, 31), Vector2(kx, 20), Color("2b2d31"), 3)
	Art.rrect(self, Rect2(30, 60, 176, 9), Color("8d98a3"), 4)
	var glass := Rect2(14, 74, 208, 246)
	Art.rrect(self, glass, Color("1d1f22"), 10, Color("7d8790"), 3)
	if any_on:
		Art.rrect(self, glass.grow(-6), Color(1.0, 0.45, 0.1, 0.18 + 0.04 * sin(t * 2.0)), 8)
	for i in 3:
		var y := _center(i).y + 36
		draw_line(Vector2(22, y), Vector2(214, y), Color("6b737b"), 3)
		var s = slots[i]
		if s != null:
			Art.rrect(self, Rect2(26, y - 8, 80, 8), Color("8d98a3"), 2)
			_food(i, s)
			if _burning(s):
				Art.steam(self, _center(i) + Vector2(0, -20), t, 1.2, i, Color(0.35, 0.35, 0.35))
	draw_line(Vector2(24, 312), Vector2(212, 312), Color(1.0, 0.4, 0.1, 0.8 if any_on else 0.2), 3)


func _draw_chip(rect: Rect2, s, time: float) -> void:
	if s.has("ta"):
		_draw_pizza_chip(rect, s, time)
		return
	var t: float = s["t"]
	var target: float = s["target"]
	var burn: float = s["burn"]
	var border := Color(0, 0, 0, 0)
	if t >= burn - 3.0:
		border = Color(1, 0.25, 0.15, 0.6 + 0.4 * sin(time * 12.0))
	elif show_zone and absf(t - target) <= Data.ZONE:
		border = Color("5ee06a")
	Art.rrect(self, rect, Color(0, 0, 0, 0.75), 7, border, 2 if border.a > 0 else 0)
	Art.text(self, rect.position + Vector2(6, 14), Data.ITEMS[s["item"]]["name"], 11, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 52)
	var reading := "%.1fs" % (t * Data.COOK_SLOW)   # segundos reales
	if Data.ITEMS[s["item"]].has("temps"):
		reading = "%d°C" % int(Data.temp_at(s["item"], t))   # las carnes se miden con el termómetro
	Art.text(self, rect.position + Vector2(0, 14), reading, 13, Color("ffd166"), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 6)
	var bar := Rect2(rect.position.x + 6, rect.position.y + 19, rect.size.x - 12, 6)
	draw_rect(bar, Color("1e1916"))
	var px := bar.size.x / burn
	draw_rect(Rect2(bar.position, Vector2(minf(t, burn) * px, bar.size.y)), Color("f5d7a1").lerp(Color("8b4a1c"), minf(t / burn, 1.0)))
	if show_zone:
		draw_rect(Rect2(bar.position.x + maxf(target - Data.ZONE, 0.0) * px, bar.position.y - 1, Data.ZONE * 2.0 * px, bar.size.y + 2), Color(0.4, 1, 0.4), false, 1.5)
	# Indicador de sal ("S"): gris sin sal, naranja le falta, verde bien, rojo se pasó
	if kind in ["plancha", "olla"]:
		var salt: float = s.get("salt", 0.0)
		var needs: bool = Data.ITEMS[s["item"]].get("salt", false)
		var col := Color("7d8790")
		if needs:
			if salt >= Data.SALT_OK.x and salt <= Data.SALT_OK.y:
				col = Color("3fae4a")
			elif salt > Data.SALT_OK.y:
				col = Color("d0281a")
			elif salt > 0.0:
				col = Color("e08a1a")
		elif salt > 0.3:
			col = Color("d0281a")
		var sc := Vector2(rect.end.x - 2, rect.position.y - 2)
		draw_circle(sc, 8, Color(0, 0, 0, 0.5))
		draw_circle(sc, 7, col)
		Art.text(self, sc + Vector2(-7, 4.5), "S", 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 14)


## Cartel de la pizza: cómo va cada mitad; tocarlo la saca del horno
func _draw_pizza_chip(rect: Rect2, s, time: float) -> void:
	var ta: float = s["ta"]
	var tb: float = s["tb"]
	var target: float = s["target"]
	var burn: float = s["burn"]
	var border := Color(0, 0, 0, 0)
	if maxf(ta, tb) >= burn - 3.0:
		border = Color(1, 0.25, 0.15, 0.6 + 0.4 * sin(time * 12.0))
	elif show_zone and absf(ta - target) <= Data.ZONE and absf(tb - target) <= Data.ZONE:
		border = Color("5ee06a")
	Art.rrect(self, rect, Color(0, 0, 0, 0.78), 7, border, 2 if border.a > 0 else 0)
	var uneven := absf(ta - tb) > 2.0
	var label := "¡girala!" if uneven else "sacar"
	if kind in ["comal", "crepera"]:
		# Tortilla o crêpe: primero un lado, vuelta, después el otro
		uneven = ta >= target * 0.8 and tb < target * 0.6
		label = "¡dala vuelta!" if uneven else ("sacar" if minf(ta, tb) >= target * 0.8 else "cocinando...")
	Art.text(self, rect.position + Vector2(0, 12), label, 11,
		Color("ffd166") if uneven else Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	# Una barrita por mitad (la de arriba es la que mira al fuego)
	for h in 2:
		var tt := ta if h == 0 else tb
		var bar := Rect2(rect.position.x + 6, rect.position.y + 16 + h * 6, rect.size.x - 12, 4)
		draw_rect(bar, Color("1e1916"))
		var px := bar.size.x / burn
		draw_rect(Rect2(bar.position, Vector2(minf(tt, burn) * px, bar.size.y)), Art._crust_color(tt, target, burn))
		if show_zone:
			draw_rect(Rect2(bar.position.x + maxf(target - Data.ZONE, 0.0) * px, bar.position.y - 1, Data.ZONE * 2.0 * px, bar.size.y + 2), Color(0.4, 1, 0.4), false, 1.0)


## Comal (México): disco de hierro negro sobre un fogón de adobe, con hasta 4 tortillas
func _draw_comal(t: float) -> void:
	# Fogón de adobe
	Art.rrect(self, Rect2(0, 20, 236, 310), Color("b0643a"), 14, Color("7a3e1e"), 3)
	for k in 7:
		draw_line(Vector2(6, 60 + k * 40), Vector2(230, 60 + k * 40), Color(0, 0, 0, 0.1), 2)
	# Boca del fuego, abajo
	Art.rrect(self, Rect2(70, 284, 96, 40), Color("2a1208"), 18)
	var any_on := false
	for s in slots:
		if s != null:
			any_on = true
	# Brasas de leña
	for k in 7:
		var fl := 0.6 + 0.4 * sin(t * 7.0 + k * 1.7)
		Art.ellipse(self, Vector2(82 + k * 12, 312 - fl * 6.0), Vector2(7, 9 + fl * (8.0 if any_on else 4.0)), Color(1.0, 0.45 + 0.25 * fl, 0.1, 0.85))
		Art.ellipse(self, Vector2(82 + k * 12, 314), Vector2(6, 4), Color("ffd27a"))
	# Disco del comal
	var c := Vector2(118, 150)
	draw_circle(c + Vector2(4, 8), 116, Color(0, 0, 0, 0.3))
	draw_circle(c, 116, Color("1c1a19"))
	draw_circle(c, 108, Color("2d2a28"))
	draw_arc(c, 112, PI * 1.1, PI * 1.6, 24, Color(1, 1, 1, 0.12), 3)
	# Brillo del calor y marcas de uso
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for k in 10:
		var p := c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 96)
		Art.ellipse(self, p, Vector2(rng.randf_range(8, 18), rng.randf_range(4, 9)), Color(0.5, 0.35, 0.2, 0.12))
	draw_circle(c, 70, Color(1, 0.4, 0.1, 0.04 + 0.03 * sin(t * 2.0)))
	for i in slots.size():
		var s = slots[i]
		if s == null:
			continue
		var p := _center(i)
		Art.ellipse(self, p + Vector2(0, 4), Vector2(42, 40), Color(0, 0, 0, 0.35))
		_food(i, s)
		# Se infla y humea cuando el lado de abajo ya se cocinó
		if s["ta"] > s["target"] * 0.8:
			Art.steam(self, p + Vector2(0, -16), t, 0.6 if not _burning(s) else 1.6, i + 7,
				Color.WHITE if maxf(s["ta"], s["tb"]) < s["burn"] else Color(0.3, 0.3, 0.3))


const SHAKE_COLS := {"malteada_choco": Color("6e3a1e"), "malteada_frutilla": Color("f28aa8"), "malteada_vainilla": Color("f6e6b4")}


## Licuadoras (EE.UU.): dos vasos sobre su motor; el helado se licúa y, si se pasa, queda aguado
func _draw_blenders(t: float) -> void:
	Art.rrect(self, Rect2(0, 250, 236, 80), Color("c8ccd0"), 10, Color("9aa3ab"), 3)
	for i in 2:
		var c := _center(i)
		var s = slots[i]
		# Motor
		Art.rrect(self, Rect2(c.x - 44, 220, 88, 64), Color("d23a3a"), 12, Color("9a2222"), 2)
		draw_circle(Vector2(c.x, 262), 9, Color("2a2a2a"))
		draw_circle(Vector2(c.x, 262), 6, Color("4caf50") if s != null else Color("555555"))
		# Vaso
		var jar := PackedVector2Array([Vector2(c.x - 40, 40), Vector2(c.x + 40, 40), Vector2(c.x + 30, 214), Vector2(c.x - 30, 214)])
		draw_colored_polygon(jar, Color(0.85, 0.93, 0.97, 0.35))
		if s != null:
			var col: Color = SHAKE_COLS.get(s["item"], Color.WHITE)
			var p := clampf(s["t"] / s["target"], 0.0, 1.6)
			# Aguada: se aclara y pierde cuerpo
			if s["t"] > s["target"]:
				col = col.lerp(Color(1, 1, 1, 0.6), clampf((s["t"] - s["target"]) / (s["burn"] - s["target"]), 0.0, 1.0) * 0.6)
			var level := 214.0 - lerpf(70.0, 150.0, minf(p, 1.0))
			var spin := t * 18.0
			var liq := PackedVector2Array()
			for k in 13:
				var x := c.x - 38 + 76.0 * k / 12.0
				var dip := 14.0 * (1.0 - absf(k - 6) / 6.0)   # remolino en el medio
				liq.append(Vector2(clampf(x, c.x - 30 - (214 - level) * 0.057 - 8, c.x + 38), level + dip + sin(spin + k) * 2.0))
			liq.append(Vector2(c.x + 30, 214))
			liq.append(Vector2(c.x - 30, 214))
			draw_colored_polygon(liq, col)
			# Bochas de helado sin licuar al principio
			if p < 0.6:
				for k in 3:
					draw_circle(Vector2(c.x - 14 + k * 14 + sin(spin * 0.3 + k) * 6, 190 - k * 8), 12.0 * (1.0 - p / 0.6) + 2, col.lightened(0.15))
			for k in 4:
				var a := spin + k * PI / 2.0
				draw_line(Vector2(c.x + cos(a) * 20, level + 30 + k * 12), Vector2(c.x + cos(a + 0.6) * 24, level + 34 + k * 12), Color(1, 1, 1, 0.25), 2)
		draw_polyline(PackedVector2Array([Vector2(c.x - 40, 40), Vector2(c.x - 30, 214), Vector2(c.x + 30, 214), Vector2(c.x + 40, 40)]), Color(0.7, 0.8, 0.85, 0.9), 3)
		draw_line(Vector2(c.x - 30, 60), Vector2(c.x - 24, 200), Color(1, 1, 1, 0.4), 3)
		Art.rrect(self, Rect2(c.x - 44, 28, 88, 16), Color("2a2a2a"), 6)
		# Mango
		draw_polyline(PackedVector2Array([Vector2(c.x + 40, 70), Vector2(c.x + 52, 74), Vector2(c.x + 50, 150), Vector2(c.x + 34, 156)]), Color(0.7, 0.8, 0.85, 0.9), 5)


## Crepera (Francia): dos discos de hierro negro sobre un cuerpo de acero, con perillas
func _draw_crepera(t: float) -> void:
	Art.rrect(self, Rect2(0, 0, 236, 330), Color("8d969e"), 12, Color("aab3ba"), 4)
	for k in 46:
		draw_line(Vector2(5 + k * 5, 4), Vector2(5 + k * 5, 326), Color(1, 1, 1, 0.03 + 0.02 * (k % 3)), 1)
	for i in 2:
		var c := _center(i)
		draw_circle(c + Vector2(3, 5), 64, Color(0, 0, 0, 0.3))
		draw_circle(c, 64, Color("1c1d20"))
		draw_circle(c, 58, Color("2c2e32"))
		draw_arc(c, 61, PI * 1.1, PI * 1.6, 20, Color(1, 1, 1, 0.12), 3)
		var on: bool = slots[i] != null
		draw_circle(Vector2(20, c.y + 52), 5, Color("ff4a2a") if on else Color("5a2a22"))
		draw_circle(Vector2(214, c.y - 50), 11, Color("1d1f22"))
		draw_line(Vector2(214, c.y - 50), Vector2(219, c.y - 57), Color("e3e8ec"), 2)
		var s = slots[i]
		if s != null:
			_food(i, s)
			if s["ta"] > s["target"] * 0.8:
				Art.steam(self, c + Vector2(0, -20), t, 0.6 if not _burning(s) else 1.6, i + 11,
					Color.WHITE if maxf(s["ta"], s["tb"]) < s["burn"] else Color(0.3, 0.3, 0.3))
