extends RefCounted
## Arte del juego.
## - Ilustraciones en assets/ (SVG). Para reemplazar un dibujo, cambiá el archivo manteniendo el nombre.
## - Dibujos hechos por código: personajes, fondos, salsas, toppings, vapor y fuego.

const SVG_SCALE := 3.0
static var _cache := {}

const INK := Color("3b2414")

const SAUCE_COLORS := {
	"Fileto": Color("c8341f"), "Bolognesa": Color("8a2a16"), "Crema": Color("f4ecd2"),
	"Pesto": Color("4f8a2a"), "Cuatro quesos": Color("f2d16b"), "Mixta": Color("e07a5a"),
	"Chimichurri": Color("6b7a2a"), "Criolla": Color("d9572b"), "Limón y hierbas": Color("e6e08a"),
	"Ketchup": Color("c4161c"), "Mayonesa": Color("fff2c2"), "Mostaza": Color("e8b923"),
	"Oliva y limón": Color("d6cf5a"), "Vinagreta": Color("b88a3c"), "Oliva": Color("a8a53a"),
	"Salsa de soja": Color("3b2414"),
}

# shape: cómo se dibuja cada topping sobre el plato
const TOPPINGS := {
	"Queso rallado": {"color": Color("f7e08a"), "shape": "flake"},
	"Albahaca": {"color": Color("3f8f2f"), "shape": "leaf"},
	"Perejil": {"color": Color("4a9a36"), "shape": "flake"},
	"Limón": {"color": Color("f4e04d"), "shape": "slice"},
	"Huevo frito": {"color": Color("ffffff"), "shape": "egg"},
	"Cheddar": {"color": Color("f29b1d"), "shape": "square"},
	"Panceta": {"color": Color("c25a4e"), "shape": "strip"},
	"Pepinos": {"color": Color("7da84a"), "shape": "slice"},
	"Huevo duro": {"color": Color("ffffff"), "shape": "egg_half"},
	"Queso": {"color": Color("f5d76e"), "shape": "cube"},
	"Croutons": {"color": Color("d9a35a"), "shape": "cube"},
	"Queso de cabra": {"color": Color("fbf8ee"), "shape": "dot"},
	"Semillas": {"color": Color("e8d9a8"), "shape": "seed"},
	"Verdeo": {"color": Color("6fbf4a"), "shape": "ring"},
	"Dulce de leche": {"color": Color("8a4b1f"), "shape": "drizzle"},
	"Crema": {"color": Color("fffaf0"), "shape": "dollop"},
	"Azúcar": {"color": Color("ffffff"), "shape": "sugar"},
}

const SKINS := [Color("f9d7b9"), Color("f1c19a"), Color("d9a074"), Color("b97a4f"), Color("8d5a3b"), Color("6b4228")]
const HAIRS := [Color("2b1d14"), Color("4a3020"), Color("7a4a24"), Color("c48a3a"), Color("e8c86a"),
	Color("a8a8a8"), Color("b6402a"), Color("1d1d26")]
const SHIRTS := [Color("3d7ab8"), Color("d9534a"), Color("4caf6a"), Color("e6a33a"), Color("8a5cb8"),
	Color("2f9c9c"), Color("e57aa0"), Color("5a6470"), Color("f2e3c6")]


# =====================================================================
# Iluminación: luz cálida desde arriba y bordes más oscuros (da profundidad)
# =====================================================================

static var _vignette: GradientTexture2D = null
static var _warm: GradientTexture2D = null


static func _radial(from: Vector2, to: Vector2, inner: Color, outer: Color, mid := -1.0) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	if mid > 0.0:
		g.add_point(mid, inner)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = from
	t.fill_to = to
	t.width = 256
	t.height = 256
	return t


static func draw_lighting(ci: CanvasItem, rect: Rect2, strength := 1.0) -> void:
	if _warm == null:
		_warm = _radial(Vector2(0.5, -0.1), Vector2(0.5, 0.95), Color(1.0, 0.86, 0.6, 0.16), Color(1.0, 0.86, 0.6, 0.0))
		_vignette = _radial(Vector2(0.5, 0.42), Vector2(1.1, 1.05), Color(0, 0, 0, 0.0), Color(0.05, 0.02, 0.0, 0.45), 0.5)
	ci.draw_texture_rect(_warm, rect, false, Color(1, 1, 1, strength))
	ci.draw_texture_rect(_vignette, rect, false, Color(1, 1, 1, strength))


# =====================================================================
# Texturas
# =====================================================================

static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var full := "res://assets/%s.svg" % path
	var t: Texture2D = null
	var src := FileAccess.get_file_as_string(full)
	if src != "":
		var img := Image.new()
		if img.load_svg_from_string(src, SVG_SCALE) == OK:
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
	if t == null and ResourceLoader.exists(full):
		t = load(full)
	_cache[path] = t
	return t


static func food(id: String) -> Texture2D:
	return tex("food/" + id)


static func fit_rect(t: Texture2D, rect: Rect2) -> Rect2:
	var ts := t.get_size()
	var s := minf(rect.size.x / ts.x, rect.size.y / ts.y)
	var sz := ts * s
	return Rect2(rect.position + (rect.size - sz) / 2.0, sz)


static func draw_tex(ci: CanvasItem, t: Texture2D, rect: Rect2, mod := Color.WHITE) -> void:
	if t == null:
		ci.draw_rect(rect, Color(1, 0, 1, 0.4))
		return
	ci.draw_texture_rect(t, fit_rect(t, rect), false, mod)


static func draw_tex_rot(ci: CanvasItem, t: Texture2D, center: Vector2, sz: Vector2, angle: float, mod := Color.WHITE) -> void:
	ci.draw_set_transform(center, angle, Vector2.ONE)
	ci.draw_texture_rect(t, Rect2(-sz / 2.0, sz), false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Dibuja un ingrediente. `chopped` lo muestra en trozos.
static func draw_food(ci: CanvasItem, id: String, rect: Rect2, tint := Color.WHITE, chopped := false) -> void:
	var t := food(id)
	if t == null:
		return
	if not chopped:
		draw_tex(ci, t, rect, tint)
		return
	# Cortado: rodajas (tiras de la imagen) desparramadas
	var c := rect.get_center()
	var full := fit_rect(t, rect.grow(-rect.size.x * 0.08))
	var ts := t.get_size()
	var n := 5
	var offs := [Vector2(-0.24, -0.1), Vector2(-0.1, 0.12), Vector2(0.04, -0.12), Vector2(0.16, 0.1), Vector2(0.26, -0.06)]
	var angs := [-0.35, 0.25, -0.15, 0.4, -0.25]
	for k in n:
		var src := Rect2(ts.x * k / n, 0, ts.x / n, ts.y)
		var sz := Vector2(full.size.x / n, full.size.y)
		ci.draw_set_transform(c + offs[k] * rect.size, angs[k], Vector2.ONE)
		ci.draw_texture_rect_region(t, Rect2(-sz / 2.0, sz), src, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func food_raw(id: String) -> Texture2D:
	var t := tex("food/raw/" + id)
	return t if t != null else food(id)


## Dibuja algo que se está cocinando: el dibujo crudo se transforma en el cocido,
## después se oscurece si se pasa y queda negro si se quema.
static func draw_cooking(ci: CanvasItem, id: String, rect: Rect2, t: float, target: float, burn: float) -> void:
	var raw := tex("food/raw/" + id)
	var cooked := food(id)
	var p := clampf(t / target, 0.0, 1.0)
	if raw != null and p < 1.0:
		draw_tex(ci, raw, rect, Color(1, 1, 1, clampf((1.0 - p) * 1.8, 0.0, 1.0)))
	var tint := Color.WHITE
	if t >= burn:
		tint = Color(0.2, 0.18, 0.17)
	elif t > target:
		tint = Color.WHITE.lerp(Color(0.5, 0.36, 0.28), (t - target) / (burn - target))
	elif raw == null:
		tint = Color(1.35, 1.25, 1.25).lerp(Color.WHITE, p)
	if raw != null:
		tint.a = clampf(p * 1.8 - 0.3, 0.0, 1.0)
	draw_tex(ci, cooked, rect, tint)


## Dibuja una preparación (cocida, cortada o de la despensa).
static func draw_entry(ci: CanvasItem, e: Dictionary, rect: Rect2) -> void:
	if e.get("t", -1.0) >= 0.0:
		draw_cooking(ci, e["item"], rect, e["t"], e["vtarget"], e["burn"])
	else:
		draw_food(ci, e["item"], rect, Color.WHITE, e.get("chopped", false))


# =====================================================================
# Primitivas
# =====================================================================

static func rrect(ci: CanvasItem, rect: Rect2, color: Color, radius := 8.0, border := Color(0, 0, 0, 0), bw := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, rect)


static func grad_rect(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	var p := PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0),
		rect.end, rect.position + Vector2(0, rect.size.y)])
	ci.draw_polygon(p, PackedColorArray([top, top, bottom, bottom]))


static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in 28:
		var a := TAU * k / 28.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(pts, color)


static func text(ci: CanvasItem, pos: Vector2, s: String, fsize := 16, color := Color.WHITE,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0, outline_color := Color(0, 0, 0, 0.8)) -> void:
	var font := ThemeDB.fallback_font
	if outline > 0:
		ci.draw_string_outline(font, pos, s, align, width, fsize, outline, outline_color)
	ci.draw_string(font, pos, s, align, width, fsize, color)


static func bubble(ci: CanvasItem, tip: Vector2, s: String, fsize := 16) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + 24
	var h := fsize + 18.0
	var r := Rect2(tip.x - w / 2.0, tip.y - h - 12, w, h)
	rrect(ci, Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.25), 12)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-10, -14), tip + Vector2(10, -14)]), Color.WHITE)
	rrect(ci, r, Color.WHITE, 12)
	text(ci, Vector2(r.position.x, r.position.y + fsize + 6), s, fsize, INK, HORIZONTAL_ALIGNMENT_CENTER, w)


# =====================================================================
# Efectos
# =====================================================================

static func steam(ci: CanvasItem, base: Vector2, time: float, strength := 1.0, seed := 0, color := Color.WHITE) -> void:
	for i in 4:
		var ph := fmod(time * 0.55 + i * 0.25 + seed * 0.137, 1.0)
		var p := base + Vector2(sin(ph * 6.0 + i * 1.7 + seed) * 9.0, -ph * 70.0)
		var c := color
		c.a = (1.0 - ph) * 0.35 * strength
		ci.draw_circle(p, 7.0 + ph * 14.0, c)


static func flames(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	var n := 16
	for i in n:
		var a := TAU * i / n
		var flick := 0.75 + 0.25 * sin(time * 22.0 + i * 1.9)
		var dir := Vector2(cos(a), sin(a))
		var base := center + dir * radius
		var side := Vector2(-dir.y, dir.x) * 5.0
		var tip := base + dir * 7.0 * flick
		ci.draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), Color(0.25, 0.45, 1.0, 0.8))
		var tip2 := base + dir * 4.0 * flick
		ci.draw_colored_polygon(PackedVector2Array([base - side * 0.5, tip2, base + side * 0.5]), Color(0.7, 0.9, 1.0, 0.95))


static func bubbles(ci: CanvasItem, center: Vector2, radius: float, time: float, color: Color, count := 8, seed := 0) -> void:
	for i in count:
		var ph := fmod(time * 1.3 + i * 0.37 + seed * 0.21, 1.0)
		var a := i * 2.399 + seed
		var rr := radius * (0.25 + 0.65 * fmod(i * 0.618, 1.0))
		var p := center + Vector2(cos(a), sin(a)) * rr
		ci.draw_arc(p, 1.5 + ph * 4.0, 0, TAU, 12, Color(color, 1.0 - ph), 1.5)


static func sizzle(ci: CanvasItem, center: Vector2, radius: float, time: float, seed := 0) -> void:
	for i in 10:
		var ph := fmod(time * 3.0 + i * 0.31 + seed * 0.4, 1.0)
		var a := i * 2.1 + seed + time
		var p := center + Vector2(cos(a), sin(a)) * radius * (0.8 + ph * 0.5)
		ci.draw_circle(p, 1.6, Color(1, 1, 0.9, 1.0 - ph))


# =====================================================================
# Salsas, toppings y envases
# =====================================================================

static func draw_sauce(ci: CanvasItem, center: Vector2, radius: float, color: Color, seed := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pts := PackedVector2Array()
	var n := 20
	for k in n:
		var a := TAU * k / n
		var r := radius * (0.82 + rng.randf() * 0.26)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, Color(color, 0.93))
	for k in 4:
		var a := rng.randf() * TAU
		ci.draw_circle(center + Vector2(cos(a), sin(a)) * radius * 1.02, radius * 0.12, Color(color, 0.93))
	ellipse(ci, center + Vector2(-radius * 0.3, -radius * 0.32), Vector2(radius * 0.28, radius * 0.14), Color(1, 1, 1, 0.3))


# --- Toppings desparramados a mano ---

## Cada cuánto cae una pieza y cuántas como máximo, según la forma del topping.
static func sprinkle_rate(name: String) -> Array:
	var shape: String = TOPPINGS.get(name, {"shape": "dot"})["shape"]
	match shape:
		"leaf":
			return [0.14, 16]
		"slice", "square", "strip":
			return [0.32, 6]
		"egg":
			return [0.9, 1]
		"egg_half":
			return [0.7, 2]
		"dollop":
			return [0.5, 3]
		"drizzle":
			return [0.02, 200]
	return [0.04, 70]


## Dibuja los toppings que se desparramaron. sprinkles = {nombre: {amount, pts}}; pts relativos (radio 1 = la comida).
static func draw_sprinkles(ci: CanvasItem, center: Vector2, radius: float, sprinkles: Dictionary) -> void:
	var idx := 0
	for name in sprinkles:
		idx += 1
		var info: Dictionary = TOPPINGS.get(name, {"color": Color.WHITE, "shape": "dot"})
		var pts: Array = sprinkles[name]["pts"]
		var k := radius / 95.0      # piezas chicas: un desparramado delicado
		if info["shape"] == "drizzle":
			var line := PackedVector2Array()
			for j in pts.size():
				var p: Vector2 = center + pts[j] * radius
				if not line.is_empty() and p.distance_to(line[-1]) > radius * 0.5:
					_drizzle_line(ci, line, info["color"], k)
					line = PackedVector2Array()
				line.append(p)
			_drizzle_line(ci, line, info["color"], k)
			continue
		for j in pts.size():
			var rng := RandomNumberGenerator.new()
			rng.seed = idx * 1009 + j * 31
			draw_topping_piece(ci, center + pts[j] * radius, k, info["color"], info["shape"], rng)


## Hilo fino de dulce de leche: se afina en las puntas y tiene un brillo encima.
static func _drizzle_line(ci: CanvasItem, line: PackedVector2Array, col: Color, k: float) -> void:
	if line.size() < 2:
		return
	var n := line.size()
	for j in n - 1:
		var taper := minf(1.0, minf(j + 1, n - 1 - j) / 4.0)   # más finito en las puntas
		var w := (1.2 + 1.6 * taper) * k
		ci.draw_line(line[j], line[j + 1], col.darkened(0.15), w + 0.8)
		ci.draw_line(line[j], line[j + 1], col, w)
	var shine := PackedVector2Array()
	for j in n:
		shine.append(line[j] + Vector2(-0.6, -0.6) * k)
	ci.draw_polyline(shine, Color(1, 0.92, 0.75, 0.45), maxf(0.8, 0.6 * k), true)


static func draw_topping_piece(ci: CanvasItem, p: Vector2, k: float, col: Color, shape: String, rng: RandomNumberGenerator) -> void:
	var v := rng.randf_range(0.75, 1.15)        # cada pieza de un tamaño apenas distinto
	var tone := col.darkened(rng.randf_range(0.0, 0.12))
	match shape:
		"flake":
			# Hebras finitas de queso rallado
			ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
			ci.draw_rect(Rect2(-3.2 * k * v, -0.6 * k, 6.4 * k * v, 1.2 * k), tone)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"leaf":
			ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
			ellipse(ci, Vector2.ZERO, Vector2(6, 2.8) * k * v, tone)
			ci.draw_line(Vector2(-5, 0) * k * v, Vector2(5, 0) * k * v, tone.darkened(0.3), 0.8)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"slice":
			ci.draw_circle(p, 7.5 * k * v, tone.darkened(0.15))
			ci.draw_circle(p, 6 * k * v, tone.lightened(0.35))
			for s in 6:
				var a := TAU * s / 6.0
				ci.draw_line(p, p + Vector2(cos(a), sin(a)) * 5.2 * k * v, tone.darkened(0.05), 0.8)
		"egg":
			draw_sauce(ci, p, 17 * k, Color.WHITE, rng.randi())
			ci.draw_circle(p + Vector2(1.5, -1.5) * k, 7 * k, Color("f6b21a"))
			ci.draw_circle(p + Vector2(-1, -4) * k, 2.2 * k, Color(1, 1, 1, 0.6))
		"egg_half":
			ellipse(ci, p, Vector2(9, 7) * k, Color.WHITE)
			ci.draw_circle(p, 4.2 * k, Color("f6c22a"))
		"square":
			ci.draw_set_transform(p, rng.randf() * 0.8, Vector2.ONE)
			ci.draw_rect(Rect2(-6 * k * v, -6 * k * v, 12 * k * v, 12 * k * v), tone)
			ci.draw_rect(Rect2(-6 * k * v, -6 * k * v, 12 * k * v, 12 * k * v), tone.darkened(0.2), false, 0.8)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"strip":
			var d := Vector2.from_angle(rng.randf() * TAU) * 9 * k * v
			ci.draw_line(p - d, p + d, tone, 4.5 * k)
			ci.draw_line(p - d * 0.9, p + d * 0.9, Color("f2c9b8"), 1.3 * k)
		"cube":
			ci.draw_set_transform(p, rng.randf() * 1.5, Vector2.ONE)
			ci.draw_rect(Rect2(-3 * k * v, -3 * k * v, 6 * k * v, 6 * k * v), tone)
			ci.draw_rect(Rect2(-3 * k * v, -3 * k * v, 6 * k * v, 2 * k * v), tone.lightened(0.3))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"seed":
			ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
			ellipse(ci, Vector2.ZERO, Vector2(1.8, 0.9) * k * v, tone)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"ring":
			ci.draw_arc(p, 2.6 * k * v, 0, TAU, 10, tone, 1.1 * k)
		"dollop":
			ci.draw_circle(p, 11 * k * v, col.darkened(0.05))
			ci.draw_circle(p + Vector2(0, -3.5) * k, 7.5 * k * v, col)
			ci.draw_circle(p + Vector2(0, -7) * k, 4 * k * v, col.lightened(0.1))
		"sugar":
			for s in 4:
				ci.draw_circle(p + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)) * k, 0.8 * k, Color(col, 0.9))
		_:
			ci.draw_circle(p, (1.8 + rng.randf() * 1.4) * k, tone)


# --- Termómetro de carne ---

## Termómetro de aguja clavado en la carne. marks = [[°C, letra], ...] (puntos de cocción a marcar)
static func draw_thermometer(ci: CanvasItem, dial: Vector2, tip: Vector2, temp: float, marks: Array, show_marks: bool) -> void:
	ci.draw_line(dial, tip, Color("6b757e"), 3.5)
	ci.draw_line(dial, tip, Color("dfe5ea"), 1.8)
	var r := 15.0
	ci.draw_circle(dial + Vector2(1, 2), r + 2, Color(0, 0, 0, 0.35))
	ci.draw_circle(dial, r + 2, Color("8d98a3"))
	ci.draw_circle(dial, r, Color("fbfbf8"))
	var a0 := PI * 0.75
	var sweep := PI * 1.5
	var to_angle := func(c: float) -> float: return a0 + sweep * clampf(c / 100.0, 0.0, 1.0)
	# Escala de color: frío -> crudo -> jugoso -> a punto -> bien -> quemado
	var bands := [[0, 40, Color("6fa8dc")], [40, 55, Color("e06a7a")], [55, 65, Color("c8505a")],
		[65, 80, Color("9a5a3a")], [80, 100, Color("3a3030")]]
	for b in bands:
		ci.draw_arc(dial, r - 3, to_angle.call(b[0]), to_angle.call(b[1]), 8, b[2], 3.0)
	if show_marks:
		for m in marks:
			var a: float = to_angle.call(m[0])
			ci.draw_line(dial + Vector2.from_angle(a) * (r - 6), dial + Vector2.from_angle(a) * r, Color("2b2d31"), 1.5)
	var na: float = to_angle.call(temp)
	ci.draw_line(dial, dial + Vector2.from_angle(na) * (r - 3), Color("d0281a"), 2.0)
	ci.draw_circle(dial, 2.5, Color("2b2d31"))
	text(ci, dial + Vector2(-24, r + 14), "%d°C" % int(temp), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 48, 4)


static func draw_toppings(ci: CanvasItem, center: Vector2, radius: float, names: Array, seed := 1) -> void:
	for idx in names.size():
		var info: Dictionary = TOPPINGS.get(names[idx], {"color": Color.WHITE, "shape": "dot"})
		var rng := RandomNumberGenerator.new()
		rng.seed = seed * 31 + idx * 977
		_draw_topping(ci, center, radius, info["color"], info["shape"], rng)


static func _rand_point(center: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector2:
	var a := rng.randf() * TAU
	var r := sqrt(rng.randf()) * radius
	return center + Vector2(cos(a), sin(a)) * r


static func _draw_topping(ci: CanvasItem, center: Vector2, radius: float, col: Color, shape: String, rng: RandomNumberGenerator) -> void:
	var k := radius / 60.0
	match shape:
		"flake":
			for i in 26:
				var p := _rand_point(center, radius, rng)
				ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
				ci.draw_rect(Rect2(-4 * k, -1.2 * k, 8 * k, 2.4 * k), col)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"leaf":
			for i in 5:
				var p := _rand_point(center, radius * 0.8, rng)
				ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
				ellipse(ci, Vector2.ZERO, Vector2(10, 5) * k, col)
				ci.draw_line(Vector2(-8, 0) * k, Vector2(8, 0) * k, col.darkened(0.3), 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"slice":
			for i in 3:
				var p := _rand_point(center, radius * 0.75, rng)
				ci.draw_circle(p, 10 * k, col.darkened(0.15))
				ci.draw_circle(p, 8 * k, col.lightened(0.35))
				for s in 6:
					var a := TAU * s / 6.0
					ci.draw_line(p, p + Vector2(cos(a), sin(a)) * 7 * k, col.darkened(0.05), 1.0)
		"egg":
			var p := _rand_point(center, radius * 0.3, rng)
			draw_sauce(ci, p, 22 * k, Color.WHITE, rng.randi())
			ci.draw_circle(p + Vector2(2, -2) * k, 9 * k, Color("f6b21a"))
			ci.draw_circle(p + Vector2(-1, -5) * k, 3 * k, Color(1, 1, 1, 0.6))
		"egg_half":
			for i in 2:
				var p := _rand_point(center, radius * 0.6, rng)
				ellipse(ci, p, Vector2(12, 9) * k, Color.WHITE)
				ci.draw_circle(p, 5.5 * k, Color("f6c22a"))
		"square":
			for i in 3:
				var p := _rand_point(center, radius * 0.6, rng)
				ci.draw_set_transform(p, rng.randf() * 0.8, Vector2.ONE)
				ci.draw_rect(Rect2(-9 * k, -9 * k, 18 * k, 18 * k), col)
				ci.draw_rect(Rect2(-9 * k, -9 * k, 18 * k, 18 * k), col.darkened(0.2), false, 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"strip":
			for i in 3:
				var p := _rand_point(center, radius * 0.6, rng)
				var d := Vector2.from_angle(rng.randf() * TAU) * 13 * k
				ci.draw_line(p - d, p + d, col, 7 * k)
				ci.draw_line(p - d * 0.9, p + d * 0.9, Color("f2c9b8"), 2 * k)
		"cube":
			for i in 9:
				var p := _rand_point(center, radius, rng)
				ci.draw_set_transform(p, rng.randf() * 1.5, Vector2.ONE)
				ci.draw_rect(Rect2(-4 * k, -4 * k, 8 * k, 8 * k), col)
				ci.draw_rect(Rect2(-4 * k, -4 * k, 8 * k, 3 * k), col.lightened(0.3))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"dot":
			for i in 12:
				ci.draw_circle(_rand_point(center, radius, rng), (3 + rng.randf() * 2) * k, col)
		"seed":
			for i in 28:
				var p := _rand_point(center, radius, rng)
				ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
				ellipse(ci, Vector2.ZERO, Vector2(2.6, 1.4) * k, col)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"ring":
			for i in 10:
				ci.draw_arc(_rand_point(center, radius, rng), 3.5 * k, 0, TAU, 10, col, 1.8 * k)
		"drizzle":
			var pts := PackedVector2Array()
			for i in 9:
				var x := -radius * 0.8 + radius * 1.6 * i / 8.0
				pts.append(center + Vector2(x, (radius * 0.45) * (1 if i % 2 == 0 else -1) + rng.randf_range(-5, 5)))
			ci.draw_polyline(pts, col, 5 * k, true)
		"dollop":
			var p := center + Vector2(radius * 0.35, -radius * 0.3)
			ci.draw_circle(p, 16 * k, col.darkened(0.05))
			ci.draw_circle(p + Vector2(0, -5) * k, 11 * k, col)
			ci.draw_circle(p + Vector2(0, -10) * k, 6 * k, col.lightened(0.1))
		"sugar":
			for i in 50:
				ci.draw_circle(_rand_point(center, radius, rng), 1.4 * k, col)


static func draw_bottle(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	var w := minf(rect.size.x * 0.55, rect.size.y * 0.42)
	var h := rect.size.y * 0.78
	var body := Rect2(rect.get_center().x - w / 2.0, rect.end.y - h, w, h)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(body.get_center().x - 4, body.position.y - 16), Vector2(body.get_center().x + 4, body.position.y - 16),
		Vector2(body.get_center().x + 9, body.position.y + 2), Vector2(body.get_center().x - 9, body.position.y + 2)]), Color("e8e8e8"))
	rrect(ci, body, color, w * 0.3, color.darkened(0.3), 2)
	rrect(ci, Rect2(body.position + Vector2(w * 0.15, h * 0.35), Vector2(w * 0.7, h * 0.3)), Color(1, 1, 1, 0.85), 4)
	ci.draw_rect(Rect2(body.position + Vector2(w * 0.12, 6), Vector2(4, h * 0.5)), Color(1, 1, 1, 0.35))


static func draw_bowl(ci: CanvasItem, rect: Rect2, topping: String) -> void:
	var c := rect.get_center() + Vector2(0, rect.size.y * 0.04)
	var r := minf(rect.size.x, rect.size.y) * 0.47
	ci.draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.2))
	ci.draw_circle(c, r, Color("d9dfe4"))
	ci.draw_circle(c, r * 0.86, Color("f7f9fa"))
	# Un poquito del topping en el fondo y el dibujo grande en el medio
	draw_toppings(ci, c, r * 0.62, [topping], 7)
	ci.draw_circle(c, r * 0.6, Color(1, 1, 1, 0.55))
	draw_topping_icon(ci, c, r * 1.25, topping)


## Ícono grande y reconocible de cada topping. s = tamaño aproximado del dibujo.
static func draw_topping_icon(ci: CanvasItem, c: Vector2, s: float, name: String) -> void:
	var u := s / 40.0
	var P := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * u
	match name:
		"Queso rallado":
			# Cuña de queso con agujeros y unas hebras al lado
			var wedge := PackedVector2Array([P.call(-15, 8), P.call(13, 8), P.call(13, -8), P.call(-15, 2)])
			ci.draw_colored_polygon(wedge, Color("f5c842"))
			ci.draw_colored_polygon(PackedVector2Array([P.call(-15, 2), P.call(13, -8), P.call(16, -10), P.call(-12, -1)]), Color("ffe28a"))
			ci.draw_polyline(PackedVector2Array([P.call(-15, 8), P.call(13, 8), P.call(13, -8), P.call(-15, 2), P.call(-15, 8)]), Color("c9961a"), 1.2, true)
			for h in [[-6, 5, 2.2], [4, 3, 2.8], [9, -2, 1.8], [-1, 0, 1.5]]:
				ci.draw_circle(P.call(h[0], h[1]), h[2] * u, Color("d9a92a"))
			for k in 4:
				ci.draw_set_transform(P.call(-12 + k * 5, 14 + (k % 2) * 2), 0.4 * (k - 1.5), Vector2.ONE)
				ci.draw_rect(Rect2(-3 * u, -0.6 * u, 6 * u, 1.2 * u), Color("f5d263"))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"Albahaca":
			_leaf_icon(ci, P.call(0, 0), 15 * u, -0.5, Color("3f8f2f"))
		"Perejil":
			ci.draw_line(P.call(0, 14), P.call(0, -2), Color("3f7f25"), 1.6 * u)
			for l in [[-7, -6, -0.9], [7, -6, 0.9], [0, -12, 0.0], [-6, 3, -1.2], [6, 3, 1.2]]:
				_leaf_icon(ci, P.call(l[0], l[1]), 6.5 * u, l[2], Color("4a9a36"))
		"Limón":
			ci.draw_circle(c, 14 * u, Color("e0c020"))
			ci.draw_circle(c, 12 * u, Color("fff6b0"))
			for k in 8:
				var a := TAU * k / 8.0
				var a2 := a + TAU / 8.0
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2.from_angle(a + 0.08) * 2 * u,
					c + Vector2.from_angle(a + 0.12) * 10.5 * u, c + Vector2.from_angle(a2 - 0.12) * 10.5 * u]), Color("f6e05a"))
		"Huevo frito":
			draw_sauce(ci, c + Vector2(0.5, 1) * u, 15.5 * u, Color("c9ced3"), 3)
			draw_sauce(ci, c, 14 * u, Color.WHITE, 3)
			ci.draw_circle(c + Vector2(2, -1) * u, 6.5 * u, Color("e08a10"))
			ci.draw_circle(c + Vector2(2, -1) * u, 5.8 * u, Color("f6a81a"))
			ci.draw_circle(c + Vector2(0, -3) * u, 2 * u, Color(1, 1, 1, 0.7))
		"Huevo duro":
			for side in [-1, 1]:
				var e: Vector2 = P.call(side * 7, 0)
				ellipse(ci, e + Vector2(0.6, 0.8) * u, Vector2(8, 11) * u, Color("b8bfc6"))
				ellipse(ci, e, Vector2(7, 10) * u, Color.WHITE)
				ci.draw_circle(e + Vector2(0, 1) * u, 4.4 * u, Color("e0a810"))
				ci.draw_circle(e + Vector2(0, 1) * u, 3.8 * u, Color("f6c22a"))
		"Cheddar":
			ci.draw_colored_polygon(PackedVector2Array([P.call(-13, -11), P.call(12, -13), P.call(14, 10), P.call(-11, 12)]), Color("f29b1d"))
			ci.draw_colored_polygon(PackedVector2Array([P.call(-11, 12), P.call(14, 10), P.call(6, 15)]), Color("c97a10"))
			ci.draw_circle(P.call(-3, -2), 2 * u, Color("d9841a"))
			ci.draw_circle(P.call(5, 4), 1.5 * u, Color("d9841a"))
		"Panceta":
			for stripe in [[Color("c25a4e"), 3.5], [Color("f2c9b8"), 1.2]]:
				var pts := PackedVector2Array()
				for k in 9:
					pts.append(P.call(-15 + k * 3.8, sin(k * 1.3) * 4.0))
				ci.draw_polyline(pts, stripe[0], stripe[1] * u, true)
		"Pepinos":
			for k in 3:
				var p: Vector2 = P.call(-8 + k * 8, -4 + (k % 2) * 8)
				ci.draw_circle(p, 7 * u, Color("5f8a2a"))
				ci.draw_circle(p, 5.5 * u, Color("c8d98a"))
				for sd in 4:
					ci.draw_circle(p + Vector2.from_angle(sd * TAU / 4.0) * 2.5 * u, 0.9 * u, Color("8aa84a"))
		"Queso":
			for q in [[-8, 3], [6, 4], [-1, -7]]:
				var p: Vector2 = P.call(q[0], q[1])
				ci.draw_rect(Rect2(p - Vector2(6, 6) * u, Vector2(12, 12) * u), Color("f5d76e"))
				ci.draw_rect(Rect2(p - Vector2(6, 6) * u, Vector2(12, 4) * u), Color("fff0a8"))
				ci.draw_circle(p + Vector2(2, 2) * u, 1.3 * u, Color("d9b84a"))
		"Croutons":
			for q in [[-8, 3, 0.2], [6, 5, -0.3], [-1, -7, 0.5]]:
				ci.draw_set_transform(P.call(q[0], q[1]), q[2], Vector2.ONE)
				rrect(ci, Rect2(Vector2(-6, -6) * u, Vector2(12, 12) * u), Color("d9a35a"), 2 * u)
				rrect(ci, Rect2(Vector2(-4, -4) * u, Vector2(8, 8) * u), Color("f0cc8a"), 1.5 * u)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"Queso de cabra":
			ci.draw_circle(c + Vector2(0.8, 1.2) * u, 13.5 * u, Color("b8b09a"))
			ci.draw_circle(c, 13 * u, Color("d8cfb4"))
			ci.draw_circle(c, 11 * u, Color("fbf8ee"))
			for d in [[-4, -3], [4, 2], [-1, 5], [5, -5]]:
				ci.draw_circle(P.call(d[0], d[1]), 1.3 * u, Color("cfc6ab"))
			# Unas hierbas en el borde, como un queso de cabra de verdad
			for a in 10:
				ci.draw_circle(c + Vector2.from_angle(a * TAU / 10.0) * 12 * u, 1.0 * u, Color("6a8a3a"))
		"Semillas":
			var rng := RandomNumberGenerator.new()
			rng.seed = 4
			for k in 14:
				ci.draw_set_transform(c + Vector2(rng.randf_range(-11, 11), rng.randf_range(-8, 8)) * u, rng.randf() * TAU, Vector2.ONE)
				ellipse(ci, Vector2.ZERO, Vector2(2.8, 1.5) * u, Color("eadbaa"))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"Verdeo":
			ci.draw_line(P.call(-14, 10), P.call(12, -12), Color("6fbf4a"), 3.5 * u)
			ci.draw_line(P.call(-14, 10), P.call(-8, 5), Color("f2f4e0"), 3.5 * u)
			for k in 3:
				ci.draw_arc(P.call(4 + k * 5, 8 - k * 2), 2.6 * u, 0, TAU, 12, Color("6fbf4a"), 1.4 * u)
		"Dulce de leche":
			# Frasco con una cuchara chorreando
			rrect(ci, Rect2(P.call(-10, -6), Vector2(20, 20) * u), Color("8a4b1f"), 4 * u)
			rrect(ci, Rect2(P.call(-11, -10), Vector2(22, 6) * u), Color("d9534a"), 2 * u)
			rrect(ci, Rect2(P.call(-7, 0), Vector2(14, 8) * u), Color("f4ead0"), 2 * u)
			ci.draw_line(P.call(8, -16), P.call(2, -4), Color("c5ccd2"), 2.2 * u)
			ci.draw_line(P.call(10, -10), P.call(10, -2), Color("8a4b1f"), 1.8 * u)
		"Crema":
			# Copo de crema batida con sombra para que se vea sobre el bowl blanco
			for t in [[0, 6, 11], [0, -1, 8], [0, -7, 5]]:
				ci.draw_circle(P.call(t[0] + 0.8, t[1] + 1.2), (t[2] + 0.8) * u, Color("cdbf9e"))
			for t in [[0, 6, 11], [0, -1, 8], [0, -7, 5]]:
				ci.draw_circle(P.call(t[0], t[1]), t[2] * u, Color("fff8e6"))
				ci.draw_arc(P.call(t[0], t[1]), t[2] * u, PI * 0.1, PI * 0.9, 10, Color("d6c9a6"), 1.4 * u)
			ci.draw_line(P.call(0, -12), P.call(1, -15), Color("fff8e6"), 2.5 * u)
			ci.draw_circle(P.call(-3, 3), 2 * u, Color(1, 1, 1, 0.9))
		"Azúcar":
			# Terrones con su cara de sombra y polvito
			for q in [[-6, 4], [5, 5], [0, -5]]:
				var p: Vector2 = P.call(q[0], q[1])
				ci.draw_rect(Rect2(p - Vector2(5, 5) * u + Vector2(1.5, 1.5) * u, Vector2(10, 10) * u), Color("aab3bb"))
				ci.draw_rect(Rect2(p - Vector2(5, 5) * u, Vector2(10, 10) * u), Color("ffffff"))
				ci.draw_rect(Rect2(p + Vector2(2, -5) * u, Vector2(3, 10) * u), Color("dfe5ea"))
				ci.draw_rect(Rect2(p - Vector2(5, 5) * u, Vector2(10, 10) * u), Color("9aa3ab"), false, 1.2)
			for k in 10:
				ci.draw_circle(c + Vector2(-12 + k * 2.6, 13 + (k % 2)) * u, 0.9 * u, Color("b8c0c8"))
		_:
			text(ci, c + Vector2(-s, 4), name.left(1), int(s * 0.6), INK, HORIZONTAL_ALIGNMENT_CENTER, s * 2)


static func _leaf_icon(ci: CanvasItem, p: Vector2, length: float, angle: float, col: Color) -> void:
	ci.draw_set_transform(p, angle, Vector2.ONE)
	var pts := PackedVector2Array()
	for k in 13:
		var t := float(k) / 12.0
		pts.append(Vector2(lerpf(-length, length, t), -sin(t * PI) * length * 0.45))
	for k in range(11, 0, -1):
		var t := float(k) / 12.0
		pts.append(Vector2(lerpf(-length, length, t), sin(t * PI) * length * 0.45))
	ci.draw_colored_polygon(pts, col)
	ci.draw_line(Vector2(-length * 1.2, 0), Vector2(length * 0.9, 0), col.darkened(0.35), maxf(1.0, length * 0.08))
	for k in 3:
		var x := -length * 0.5 + k * length * 0.45
		ci.draw_line(Vector2(x, 0), Vector2(x + length * 0.25, -length * 0.25), col.darkened(0.25), 1.0)
		ci.draw_line(Vector2(x, 0), Vector2(x + length * 0.25, length * 0.25), col.darkened(0.25), 1.0)
	ci.draw_circle(Vector2(-length * 0.3, -length * 0.15), length * 0.12, Color(1, 1, 1, 0.2))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func draw_none(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.32
	ci.draw_arc(c, r, 0, TAU, 32, Color(1, 1, 1, 0.8), 4)
	ci.draw_line(c + Vector2(-r, r) * 0.7, c + Vector2(r, -r) * 0.7, Color(1, 1, 1, 0.8), 4)


# =====================================================================
# Fondos
# =====================================================================

static func tiles(ci: CanvasItem, rect: Rect2, tile: Vector2, color: Color, grout: Color, brick := true) -> void:
	ci.draw_rect(rect, grout)
	var rows := int(ceil(rect.size.y / tile.y))
	var cols := int(ceil(rect.size.x / tile.x)) + 1
	for r in rows:
		var off := (tile.x / 2.0) if (brick and r % 2 == 1) else 0.0
		for c in cols:
			var p := rect.position + Vector2(c * tile.x - off, r * tile.y)
			var tr := Rect2(p + Vector2(1.5, 1.5), tile - Vector2(3, 3)).intersection(rect)
			if tr.size.x <= 0 or tr.size.y <= 0:
				continue
			ci.draw_rect(tr, color)
			ci.draw_rect(Rect2(tr.position, Vector2(tr.size.x, 3)), color.lightened(0.25))


static func wood(ci: CanvasItem, rect: Rect2, base: Color, plank := 26.0, vertical := false) -> void:
	ci.draw_rect(rect, base.darkened(0.25))
	var n := int(ceil((rect.size.x if vertical else rect.size.y) / plank))
	for i in n:
		var shade := base.darkened(0.06 * (i % 3))
		var r: Rect2
		if vertical:
			r = Rect2(rect.position.x + i * plank + 1, rect.position.y, plank - 2, rect.size.y)
		else:
			r = Rect2(rect.position.x, rect.position.y + i * plank + 1, rect.size.x, plank - 2)
		r = r.intersection(rect)
		ci.draw_rect(r, shade)
		var grain := shade.darkened(0.12)
		for g in 3:
			if vertical:
				var x := r.position.x + r.size.x * (0.25 + g * 0.25)
				ci.draw_line(Vector2(x, r.position.y), Vector2(x + 3, r.end.y), grain, 1.0)
			else:
				var y := r.position.y + r.size.y * (0.25 + g * 0.25)
				ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y + 2), grain, 1.0)


static func lamp(ci: CanvasItem, x: float, top: float, length: float, time: float) -> void:
	ci.draw_line(Vector2(x, top), Vector2(x, top + length), Color("3a3330"), 2.0)
	var y := top + length
	var glow := 0.18 + 0.02 * sin(time * 2.0 + x)
	ci.draw_circle(Vector2(x, y + 16), 70, Color(1.0, 0.85, 0.5, glow * 0.5))
	ci.draw_circle(Vector2(x, y + 16), 40, Color(1.0, 0.85, 0.5, glow))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, y), Vector2(x + 8, y), Vector2(x + 26, y + 20), Vector2(x - 26, y + 20)]), Color("2f5d50"))
	ci.draw_circle(Vector2(x, y + 21), 7, Color("fff3c4"))


static func plant(ci: CanvasItem, base: Vector2) -> void:
	for l in [[-26, -60, 22], [10, -76, 24], [30, -50, 20], [-8, -40, 20], [-30, -30, 16], [24, -28, 16]]:
		ci.draw_circle(base + Vector2(l[0], l[1]), l[2], Color("4f9a48").darkened(0.1 if l[0] < 0 else 0.0))
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-26, -14), base + Vector2(26, -14),
		base + Vector2(20, 26), base + Vector2(-20, 26)]), Color("c0643a"))
	ci.draw_rect(Rect2(base + Vector2(-29, -18), Vector2(58, 9)), Color("a8522c"))


## Texto curvado sobre un arco (letra por letra). angle = centro del texto (radianes, -PI/2 = arriba).
static func arc_text(ci: CanvasItem, c: Vector2, radius: float, s: String, fsize: int, color: Color, angle: float,
		outline := 0, outline_color := Color(0, 0, 0, 0.6), inside := false) -> void:
	var font := ThemeDB.fallback_font
	var widths := []
	var total := 0.0
	for ch in s:
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		widths.append(w)
		total += w
	var span := total / radius
	var a := angle - span / 2.0 if not inside else angle + span / 2.0
	for k in s.length():
		var w: float = widths[k]
		var step := w / radius
		var mid := a + (step / 2.0 if not inside else -step / 2.0)
		var p := c + Vector2.from_angle(mid) * radius
		var rot := mid + PI / 2.0 if not inside else mid - PI / 2.0
		ci.draw_set_transform(p, rot, Vector2.ONE)
		if outline > 0:
			ci.draw_string_outline(font, Vector2(-w / 2.0, fsize * 0.35), s[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, outline, outline_color)
		ci.draw_string(font, Vector2(-w / 2.0, fsize * 0.35), s[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, color)
		a += step if not inside else -step
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Logo de "La Vuelta al Plato": un plato-globo terráqueo que gira, con gorro de chef,
## cubiertos cruzados, vapor y una cinta con el nombre en curva.
static func draw_logo(ci: CanvasItem, c: Vector2, s: float, time: float) -> void:
	# Cubiertos cruzados detrás del plato
	for side in [-1, 1]:
		ci.draw_set_transform(c, side * 0.55, Vector2.ONE)
		var steel := Color("dfe5ea")
		rrect(ci, Rect2(Vector2(-7, 40) * s, Vector2(14, 120) * s), Color("6e4527"), 6 * s)
		if side < 0:
			# Tenedor
			rrect(ci, Rect2(Vector2(-14, -150) * s, Vector2(28, 40) * s), steel, 6 * s)
			for k in 4:
				rrect(ci, Rect2(Vector2(-14 + k * 8, -196) * s, Vector2(5, 52) * s), steel, 2 * s)
			ci.draw_rect(Rect2(Vector2(-4, -112) * s, Vector2(8, 154) * s), steel)
		else:
			# Cuchillo
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, -196) * s, Vector2(10, -170) * s, Vector2(10, 40) * s,
				Vector2(-6, 40) * s]), steel)
			ci.draw_line(Vector2(-2, -180) * s, Vector2(-2, 30) * s, Color(1, 1, 1, 0.8), 2 * s)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Plato
	var r := 118.0 * s
	ci.draw_circle(c + Vector2(4, 8) * s, r, Color(0, 0, 0, 0.3))
	ci.draw_circle(c, r, Color("dfe5ea"))
	ci.draw_circle(c, r * 0.96, Color("fbfcfd"))
	ci.draw_arc(c, r * 0.9, 0, TAU, 64, Color("2f6f8f"), 3 * s)
	# Globo terráqueo que gira dentro del plato
	var g := r * 0.74
	ci.draw_circle(c, g, Color("3f8fbf"))
	ci.draw_circle(c + Vector2(-g * 0.25, -g * 0.25), g * 0.7, Color(1, 1, 1, 0.08))
	var spin := fmod(time * 0.08, 1.0)
	var blobs := [[0.0, -0.35, 0.32, 0.2], [0.18, 0.15, 0.22, 0.35], [0.45, -0.25, 0.4, 0.22], [0.62, 0.3, 0.16, 0.2],
		[0.78, -0.1, 0.24, 0.3], [0.9, 0.45, 0.2, 0.12]]
	for b in blobs:
		var u: float = fmod(b[0] + spin, 1.0) * 2.0 - 1.0     # -1..1 de izquierda a derecha
		if absf(u) > 0.95:
			continue
		var squash := sqrt(maxf(0.0, 1.0 - u * u))         # se achican hacia los bordes (efecto esfera)
		var pos := c + Vector2(u * g * 0.85, b[1] * g)
		ellipse(ci, pos, Vector2(b[2] * g * squash, b[3] * g), Color("8fcf6a"))
		ellipse(ci, pos + Vector2(-2, -2) * s, Vector2(b[2] * g * squash * 0.6, b[3] * g * 0.5), Color("a9df82"))
	for m in 3:
		var u2: float = fmod(m / 3.0 + spin, 1.0) * 2.0 - 1.0
		ci.draw_arc(c + Vector2(u2 * g * 0.0, 0), g, 0, TAU, 48, Color(1, 1, 1, 0.0), 1)
		var rx := absf(g * (1.0 - absf(u2)))
		if rx > 2.0:
			var pts := PackedVector2Array()
			for k in 25:
				var a := -PI / 2.0 + PI * k / 24.0
				pts.append(c + Vector2(cos(a) * rx * signf(u2 + 0.0001), sin(a) * g))
			ci.draw_polyline(pts, Color(1, 1, 1, 0.25), 1.5 * s, true)
	ci.draw_line(c + Vector2(-g, 0), c + Vector2(g, 0), Color(1, 1, 1, 0.25), 1.5 * s)
	ci.draw_arc(c, g, 0, TAU, 64, Color("2a6a92"), 3 * s)
	ci.draw_arc(c, g * 0.98, PI * 1.05, PI * 1.5, 16, Color(1, 1, 1, 0.5), 3 * s)
	# Vapor que sale del plato
	for k in 3:
		var ph := fmod(time * 0.5 + k / 3.0, 1.0)
		var sx := c.x + (k - 1) * 40 * s + sin(ph * 6.0 + k) * 8 * s
		ci.draw_arc(Vector2(sx, c.y - r - 20 * s - ph * 50 * s), 10 * s, PI * 0.5, PI * 1.5, 10, Color(1, 1, 1, 0.6 * (1.0 - ph)), 4 * s)
	# Gorro de chef ladeado sobre el globo
	ci.draw_set_transform(c + Vector2(30, -g - 6 * s), 0.25, Vector2.ONE)
	var hat := Color("fbfbf8")
	rrect(ci, Rect2(Vector2(-42, -6) * s, Vector2(84, 22) * s), hat, 4 * s, Color("d8d8d0"), 1)
	ci.draw_circle(Vector2(-26, -26) * s, 26 * s, hat)
	ci.draw_circle(Vector2(26, -26) * s, 26 * s, hat)
	ci.draw_circle(Vector2(0, -40) * s, 30 * s, hat)
	ci.draw_arc(Vector2(0, -40) * s, 30 * s, PI * 1.1, PI * 1.6, 10, Color("e6e6de"), 3 * s)
	ci.draw_line(Vector2(-14, -2) * s, Vector2(-14, 14) * s, Color("e6e6de"), 2 * s)
	ci.draw_line(Vector2(14, -2) * s, Vector2(14, 14) * s, Color("e6e6de"), 2 * s)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Cinta roja con el nombre, en curva
	var rib_r := r * 1.18
	var a0 := PI * 0.18
	var a1 := PI * 0.82
	var band := PackedVector2Array()
	for k in 33:
		var a := a0 + (a1 - a0) * k / 32.0
		band.append(c + Vector2.from_angle(a) * (rib_r + 24 * s))
	for k in range(32, -1, -1):
		var a := a0 + (a1 - a0) * k / 32.0
		band.append(c + Vector2.from_angle(a) * (rib_r - 24 * s))
	for side in [a0, a1]:
		var p: Vector2 = c + Vector2.from_angle(side) * rib_r
		var out := Vector2.from_angle(side + (-0.25 if side == a0 else 0.25))
		var tail := p + Vector2(-46 * s if side == a1 else 46 * s, 14 * s)
		ci.draw_colored_polygon(PackedVector2Array([p - out * 24 * s, tail - Vector2(0, 22 * s), tail + Vector2(-12 * s if side == a1 else 12 * s, 0), tail + Vector2(0, 22 * s), p + out * 24 * s]), Color("9a2a20"))
	ci.draw_colored_polygon(band, Color("c8463c"))
	ci.draw_polyline(band, Color("8a2018"), 2 * s, true)
	arc_text(ci, c, rib_r - 9 * s, "LA VUELTA AL PLATO", int(30 * s), Color("fdf6e3"), PI / 2.0, int(3 * s), Color("6a1a12"), true)


## Bandera simplificada que flamea. flag = [tipo, colores] (ver Data.COUNTRIES)
static func draw_flag(ci: CanvasItem, r: Rect2, flag: Array, t: float) -> void:
	var kind: String = flag[0]
	var cols: Array = flag[1]
	r.position.y += sin(t * 5.0) * 1.0
	match kind:
		"h":
			for s in cols.size():
				ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * s / cols.size(), r.size.x, r.size.y / cols.size()), cols[s])
		"v":
			for s in cols.size():
				ci.draw_rect(Rect2(r.position.x + r.size.x * s / cols.size(), r.position.y, r.size.x / cols.size(), r.size.y), cols[s])
		"circulo":
			ci.draw_rect(r, cols[0])
			ci.draw_circle(r.get_center(), r.size.y * 0.3, cols[1])
		"barras":
			for s in 5:
				ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * s / 5.0, r.size.x, r.size.y / 5.0), cols[s % 2])
			ci.draw_rect(Rect2(r.position, r.size * Vector2(0.45, 0.55)), cols[2])
	ci.draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)


## Estrella de 5 puntas (dibujada: en la web no hay fuente con el símbolo ★)
static func star(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.45))
	if filled:
		ci.draw_colored_polygon(pts, Color("f2b632"))
		pts.append(pts[0])
		ci.draw_polyline(pts, Color("b07a10"), maxf(1.0, r * 0.1), true)
	else:
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(0.6, 0.5, 0.35, 0.8), maxf(1.0, r * 0.1), true)


## n estrellas llenas de 3, centradas en c
static func stars(ci: CanvasItem, c: Vector2, r: float, n: int) -> void:
	for k in 3:
		star(ci, c + Vector2((k - 1) * r * 2.3, 0), r, k < n)


## Lata o botella de bebida
static func draw_drink(ci: CanvasItem, rect: Rect2, name: String, drinks: Dictionary) -> void:
	var d: Dictionary = drinks.get(name, {"color": Color.WHITE, "label": Color.GRAY, "kind": "lata"})
	var c := rect.get_center()
	var h := rect.size.y * 0.9
	var w := minf(rect.size.x * 0.55, h * 0.42)
	ellipse(ci, Vector2(c.x + 2, c.y + h / 2.0), Vector2(w * 0.6, 4), Color(0, 0, 0, 0.22))
	if d["kind"] == "lata":
		var body := Rect2(c.x - w / 2.0, c.y - h * 0.38, w, h * 0.84)
		rrect(ci, body, Color("c5ccd2"), 4)
		rrect(ci, body.grow_individual(0, -5, 0, -5), d["color"], 3)
		ci.draw_rect(Rect2(body.position.x, body.get_center().y - 6, w, 12), d["label"])
		ci.draw_rect(Rect2(body.position.x + w * 0.15, body.position.y + 6, 3, body.size.y - 12), Color(1, 1, 1, 0.35))
		ellipse(ci, Vector2(c.x, body.position.y + 2), Vector2(w / 2.0, 3), Color("e3e8ec"))
		ci.draw_circle(Vector2(c.x + w * 0.15, body.position.y + 2), 2, Color("9aa3ab"))
	else:
		var body := Rect2(c.x - w / 2.0, c.y - h * 0.2, w, h * 0.68)
		var neck := Rect2(c.x - w * 0.2, c.y - h * 0.44, w * 0.4, h * 0.26)
		rrect(ci, neck, Color(d["color"], 0.85), 3)
		rrect(ci, body, Color(d["color"], 0.85), w * 0.3)
		rrect(ci, Rect2(c.x - w * 0.22, c.y - h * 0.48, w * 0.44, 6), d["label"], 2)
		ci.draw_rect(Rect2(body.position.x, body.get_center().y - 5, w, 12), d["label"])
		ci.draw_rect(Rect2(body.position.x + w * 0.18, body.position.y + 5, 3, body.size.y - 14), Color(1, 1, 1, 0.45))


## Salero de vidrio con tapa de metal. tilt en radianes; con `pouring` caen granitos.
static func salt_shaker(ci: CanvasItem, c: Vector2, s: float, tilt: float, pouring: bool, time: float) -> void:
	ci.draw_set_transform(c, tilt, Vector2.ONE)
	rrect(ci, Rect2(Vector2(-11, -6) * s, Vector2(22, 30) * s), Color(0.9, 0.95, 1.0, 0.55), 6 * s, Color(1, 1, 1, 0.8), 1)
	rrect(ci, Rect2(Vector2(-9, 6) * s, Vector2(18, 16) * s), Color("fbfbf8"), 4 * s)
	rrect(ci, Rect2(Vector2(-11, -15) * s, Vector2(22, 11) * s), Color("aab3ba"), 4 * s, Color("7d8790"), 1)
	for k in 3:
		ci.draw_circle(Vector2(-5 + k * 5, -15) * s, 1.1 * s, Color("3a3f45"))
	ci.draw_rect(Rect2(Vector2(-8, -3) * s, Vector2(2.5, 22) * s), Color(1, 1, 1, 0.5))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if pouring:
		var mouth := c + Vector2(0, -18 * s).rotated(tilt)
		for k in 7:
			var ph := fmod(time * 3.0 + k / 7.0, 1.0)
			ci.draw_circle(mouth + Vector2(sin(k * 2.1) * 4.0, ph * 34.0) * s / 1.2, 1.0 * s, Color(1, 1, 1, 1.0 - ph))


## Intro del día: la persiana del local sube, el cartel pasa a ABIERTO y aparece el nombre del día.
## p = progreso de 0 a 1.
static func draw_day_intro(ci: CanvasItem, rect: Rect2, p: float, title: String, subtitle: String, time: float) -> void:
	draw_dining(ci, rect, [], time)
	draw_counter(ci, rect, rect.size.y - 250)
	# Persiana metálica que sube (de 0.1 a 0.55)
	var up := clampf((p - 0.1) / 0.45, 0.0, 1.0)
	up = up * up * (3.0 - 2.0 * up)
	var bottom := rect.size.y * (1.0 - up)
	if bottom > 2.0:
		grad_rect(ci, Rect2(rect.position, Vector2(rect.size.x, bottom)), Color("9aa3ab"), Color("6f7b85"))
		var y := bottom - 22.0
		while y > -22.0:
			ci.draw_rect(Rect2(rect.position.x, y, rect.size.x, 3), Color(1, 1, 1, 0.18))
			ci.draw_rect(Rect2(rect.position.x, y + 14, rect.size.x, 4), Color(0, 0, 0, 0.22))
			y -= 26.0
		ci.draw_rect(Rect2(rect.position.x, bottom - 14, rect.size.x, 14), Color("4a5057"))
		rrect(ci, Rect2(rect.get_center().x - 40, bottom - 30, 80, 14), Color("2b2d31"), 6)
	ci.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 16), Color("3a3f45"))
	# Cartel de la puerta: CERRADO -> ABIERTO (gira a la mitad)
	var flip := clampf((p - 0.55) / 0.12, 0.0, 1.0)
	var sx := absf(cos(flip * PI))
	var open := flip >= 0.5
	var sign := Rect2(rect.position + Vector2(58, 94), Vector2(94, 30))
	if up > 0.7:
		var sw := sign.size.x * maxf(sx, 0.05)
		var sr := Rect2(sign.get_center().x - sw / 2.0, sign.position.y, sw, sign.size.y)
		rrect(ci, sr, Color("2f6f4f") if open else Color("8a2a20"), 6, Color("e8e0c8"), 2)
		if sx > 0.3:
			text(ci, Vector2(sr.position.x, sr.position.y + 21), "ABIERTO" if open else "CERRADO", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, sr.size.x)
	# Título del día que entra desde arriba
	var t_in := clampf((p - 0.45) / 0.2, 0.0, 1.0)
	if t_in > 0.0:
		var banner := Rect2(rect.get_center().x - 330, rect.position.y - 140 + t_in * 330, 660, 150)
		rrect(ci, Rect2(banner.position + Vector2(5, 8), banner.size), Color(0, 0, 0, 0.35), 14)
		rrect(ci, banner, Color("fdf6e3"), 14, Color("c9a86a"), 4)
		text(ci, Vector2(banner.position.x, banner.position.y + 62), title, 40, INK, HORIZONTAL_ALIGNMENT_CENTER, banner.size.x)
		text(ci, Vector2(banner.position.x, banner.position.y + 110), subtitle, 22, Color("2f7a3a"), HORIZONTAL_ALIGNMENT_CENTER, banner.size.x)
		text(ci, Vector2(banner.position.x, banner.position.y + 172), "(tocá para saltear)", 14, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, banner.size.x, 4)


## Maceta colgante con hojas que caen. top = punto del techo.
static func hanging_plant(ci: CanvasItem, top: Vector2, k := 1.0) -> void:
	ci.draw_line(top, top + Vector2(0, 30) * k, Color("6b5a4a"), 1.5)
	for side in [-1, 1]:
		ci.draw_line(top + Vector2(0, 30) * k, top + Vector2(side * 16, 44) * k, Color("6b5a4a"), 1.2)
	for l in 9:
		var x := (l - 4) * 4.0
		var length := 20.0 + (l % 3) * 12.0
		for d in int(length / 6.0):
			ci.draw_circle(top + Vector2(x + sin(d * 0.8 + l) * 3.0, 56 + d * 6.0) * k, 4.2 * k, Color("4f9a48").darkened(0.1 * (d % 2)))
	ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-18, 42) * k, top + Vector2(18, 42) * k,
		top + Vector2(13, 60) * k, top + Vector2(-13, 60) * k]), Color("c0643a"))
	ci.draw_rect(Rect2(top + Vector2(-19, 40) * k, Vector2(38, 5) * k), Color("a8522c"))
	for l in 6:
		ci.draw_circle(top + Vector2(-14 + l * 5.6, 40) * k, 6 * k, Color("5fae52"))


## Ventilador de techo que gira. top = punto del techo.
static func ceiling_fan(ci: CanvasItem, top: Vector2, time: float, k := 1.0) -> void:
	var hub := top + Vector2(0, 26) * k
	ci.draw_line(top, hub, Color("3a3330"), 3 * k)
	for b in 4:
		var a := time * 5.0 + b * TAU / 4.0
		var d := Vector2(cos(a), sin(a) * 0.22)
		var n := Vector2(-d.y, d.x).normalized() * 6.0 * k
		ci.draw_colored_polygon(PackedVector2Array([hub + n * 0.5, hub + d * 70 * k + n, hub + d * 74 * k, hub + d * 70 * k - n, hub - n * 0.5]),
			Color("7a4a24").lightened(0.15 * (b % 2)))
	ci.draw_circle(hub, 8 * k, Color("c9a24a"))
	ci.draw_circle(hub + Vector2(0, 6) * k, 5 * k, Color("fff3c4"))


## Frasco de vidrio con caramelos de colores.
static func candy_jar(ci: CanvasItem, r: Rect2) -> void:
	var body := Rect2(r.position + Vector2(0, r.size.y * 0.22), Vector2(r.size.x, r.size.y * 0.78))
	rrect(ci, body, Color(0.85, 0.95, 1.0, 0.35), r.size.x * 0.25, Color(1, 1, 1, 0.7), 2)
	var cols := [Color("e74c3c"), Color("f1c40f"), Color("2ecc71"), Color("3498db"), Color("e67e22"), Color("9b59b6")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for k in 22:
		var p := body.position + Vector2(rng.randf_range(0.18, 0.82) * body.size.x, rng.randf_range(0.35, 0.9) * body.size.y)
		ci.draw_circle(p, r.size.x * 0.08, cols[k % cols.size()])
		ci.draw_circle(p + Vector2(-1, -1), r.size.x * 0.025, Color(1, 1, 1, 0.7))
	rrect(ci, Rect2(r.position + Vector2(r.size.x * 0.15, r.size.y * 0.1), Vector2(r.size.x * 0.7, r.size.y * 0.14)), Color("c0392b"), 4)
	ci.draw_rect(Rect2(body.position + Vector2(body.size.x * 0.15, 6), Vector2(4, body.size.y * 0.6)), Color(1, 1, 1, 0.45))


## Salón con ventana, puerta, pizarra con el menú y lámparas. decor = mejoras compradas que se ven.
static func draw_dining(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array = []) -> void:
	var o := rect.position
	grad_rect(ci, rect, Color("f1dfbd"), Color("e2c79c"))
	for i in int(rect.size.x / 48.0) + 1:
		ci.draw_rect(Rect2(o.x + i * 48, o.y, 24, rect.size.y), Color(1, 1, 1, 0.08))
	wood(ci, Rect2(o.x, o.y + 225, rect.size.x, rect.size.y - 225), Color("9a6a42"), 30, true)
	ci.draw_rect(Rect2(o.x, o.y + 220, rect.size.x, 8), Color("6e4527"))

	# Puerta
	var d := Rect2(o.x + 30, o.y + 30, 150, 300)
	ci.draw_rect(d.grow(8), Color("5a3a22"))
	ci.draw_rect(d, Color("8a5a34"))
	grad_rect(ci, Rect2(d.position + Vector2(18, 18), Vector2(114, 130)), Color("bfe3f2"), Color("e8f6fb"))
	ci.draw_line(d.position + Vector2(75, 18), d.position + Vector2(75, 148), Color("8a5a34"), 4)
	ci.draw_circle(d.position + Vector2(130, 170), 7, Color("e3c26a"))
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("2f6f4f"), 6, Color("e8e0c8"), 2)
	text(ci, d.position + Vector2(28, 85), "ABIERTO", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, 94)

	# Ventana con la calle
	var w := Rect2(o.x + 300, o.y + 36, 470, 170)
	ci.draw_rect(w.grow(10), Color("6e4527"))
	grad_rect(ci, w, Color("9fd3ee"), Color("dff1f8"))
	var bx := [0, 70, 120, 210, 260, 350, 400]
	var bh := [70, 110, 60, 95, 120, 80, 100]
	var bc := [Color("e9a27a"), Color("d6c7a5"), Color("b9cfd8"), Color("f0c987"), Color("c9a3b8"), Color("a9c79a"), Color("e3b090")]
	for i in bx.size():
		var b := Rect2(w.position.x + bx[i], w.end.y - bh[i], 64, bh[i])
		ci.draw_rect(b, bc[i])
		for wy in range(int(b.position.y) + 10, int(b.end.y) - 12, 22):
			ci.draw_rect(Rect2(b.position.x + 10, wy, 12, 10), Color(1, 1, 1, 0.6))
			ci.draw_rect(Rect2(b.position.x + 40, wy, 12, 10), Color(1, 1, 1, 0.6))
	ci.draw_circle(w.position + Vector2(390, 40), 22, Color(1, 1, 0.85, 0.9))
	ci.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("6e4527"), 6)
	# Toldo
	for i in 12:
		var sx := w.position.x - 10 + i * (w.size.x + 20) / 12.0
		var col := Color("c8463c") if i % 2 == 0 else Color("f4efe0")
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, w.position.y - 26), Vector2(sx + (w.size.x + 20) / 12.0, w.position.y - 26),
			Vector2(sx + (w.size.x + 20) / 12.0, w.position.y - 6), Vector2(sx, w.position.y - 6)]), col)

	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 22, 300, 196)
	ci.draw_rect(b.grow(9), Color("7a4a24"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "MENÚ DEL DÍA", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	ci.draw_line(b.position + Vector2(60, 40), b.position + Vector2(240, 40), Color(1, 1, 1, 0.5), 2)
	var cols := 2 if menu.size() > 6 else 1
	var per := int(ceil(menu.size() / float(cols)))
	for i in menu.size():
		var col_i := i / per
		var row := i % per
		var fs := 13 if cols == 2 else 15
		text(ci, b.position + Vector2(14 + col_i * 146, 62 + row * (fs + 7)), "• " + str(menu[i]), fs, Color("e9f0dc"),
			HORIZONTAL_ALIGNMENT_LEFT, 140 if cols == 2 else 280)

	# Luz que entra por la ventana
	ci.draw_colored_polygon(PackedVector2Array([w.position + Vector2(0, w.size.y), w.end,
		w.end + Vector2(160, 140), w.position + Vector2(90, w.size.y + 140)]), Color(1, 0.97, 0.85, 0.07))
	plant(ci, o + Vector2(820, 196))
	for x in [260, 640, 1220]:
		lamp(ci, o.x + x, o.y, 6, time)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(205, 0))
		hanging_plant(ci, o + Vector2(1245, 0), 0.9)
		hanging_plant(ci, o + Vector2(840, 0), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(450, 0), time)


## Frente del mostrador (tapa de mármol + frente de madera). `top` es la altura de la tapa.
static func draw_counter(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	ci.draw_rect(Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18), Color("6e4527"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in int(rect.size.x / 160.0) + 1:
		var pr := Rect2(rect.position.x + i * 160 + 12, y + 34, 136, rect.end.y - y - 50)
		grad_rect(ci, pr, Color("94623a"), Color("7e512d"))
		ci.draw_rect(Rect2(pr.position, Vector2(pr.size.x, 4)), Color("b07c4e"))
		ci.draw_rect(Rect2(pr.position + Vector2(0, pr.size.y - 3), Vector2(pr.size.x, 3)), Color(0, 0, 0, 0.25))
		var inner := pr.grow(-14)
		grad_rect(ci, inner, Color("7a4c2a"), Color("6a4022"))
		# Veta de la madera
		for g in 7:
			var gx := inner.position.x + rng.randf() * inner.size.x
			var pts := PackedVector2Array()
			for s in 8:
				pts.append(Vector2(gx + sin(s * 0.9 + g) * 3.0, inner.position.y + inner.size.y * s / 7.0))
			ci.draw_polyline(pts, Color(0.25, 0.13, 0.05, 0.25), 1.0, true)
		ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, 3)), Color(0, 0, 0, 0.2))
	# Tapa de mármol con vetas y brillo
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("f7f5f1"), Color("cfccc6"))
	for v in 14:
		var vx := rect.position.x + rng.randf() * rect.size.x
		ci.draw_line(Vector2(vx, y + 2), Vector2(vx + rng.randf_range(20, 70), y + 18), Color(0.5, 0.5, 0.55, 0.18), 1.0)
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.7))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


static func draw_kitchen_wall(ci: CanvasItem, rect: Rect2) -> void:
	tiles(ci, rect, Vector2(64, 30), Color("f3f5f6"), Color("c9d0d4"))
	grad_rect(ci, Rect2(rect.position.x, rect.end.y - 30, rect.size.x, 30), Color("aab3ba"), Color("7d8790"))


static func draw_wood_counter(ci: CanvasItem, rect: Rect2) -> void:
	tiles(ci, Rect2(rect.position, Vector2(rect.size.x, 40)), Vector2(64, 30), Color("f3f5f6"), Color("c9d0d4"))
	ci.draw_rect(Rect2(rect.position.x, rect.position.y + 40, rect.size.x, 8), Color("8d6440"))
	wood(ci, Rect2(rect.position.x, rect.position.y + 48, rect.size.x, rect.size.y - 48), Color("c08a58"), 34)


static func draw_marble(ci: CanvasItem, rect: Rect2) -> void:
	grad_rect(ci, rect, Color("eceae6"), Color("d8d5cf"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for v in 9:
		var pts := PackedVector2Array()
		var p := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var dir := Vector2.from_angle(rng.randf_range(-0.6, 0.6))
		for k in 14:
			pts.append(p)
			dir = dir.rotated(rng.randf_range(-0.5, 0.5))
			p += dir * rng.randf_range(20, 45)
		ci.draw_polyline(pts, Color(0.55, 0.55, 0.6, 0.25), rng.randf_range(1.0, 2.5), true)


## Vista del pase: pared de cocina con una ventana al salón y el estante de acero.
static func draw_pass(ci: CanvasItem, rect: Rect2, time: float) -> void:
	tiles(ci, rect, Vector2(64, 30), Color("f3f5f6"), Color("c9d0d4"))
	var win := Rect2(rect.position.x + 330, rect.position.y + 24, 620, 280)
	grad_rect(ci, win, Color("f1dfbd"), Color("e2c79c"))
	wood(ci, Rect2(win.position.x, win.position.y + 170, win.size.x, win.size.y - 170), Color("9a6a42"), 30, true)
	lamp(ci, win.position.x + 150, win.position.y, 4, time)
	lamp(ci, win.position.x + 470, win.position.y, 4, time)
	ci.draw_rect(win.grow(6), Color("9aa3ab"), false, 12)
	# Lámpara de calor
	grad_rect(ci, Rect2(win.position.x - 10, win.position.y - 14, win.size.x + 20, 20), Color("c5ccd2"), Color("8d98a3"))
	ci.draw_rect(Rect2(win.position.x + 20, win.position.y + 6, win.size.x - 40, 8), Color(1.0, 0.35, 0.15, 0.6 + 0.1 * sin(time * 3.0)))
	# Estante del pase
	grad_rect(ci, Rect2(rect.position.x, win.end.y - 6, rect.size.x, 36), Color("e1e6ea"), Color("9aa3ab"))
	grad_rect(ci, Rect2(rect.position.x, win.end.y + 30, rect.size.x, rect.end.y - win.end.y - 30), Color("8d98a3"), Color("6b757e"))


static func draw_paper(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.2))
	ci.draw_rect(rect, Color("fdf6e3"))
	for y in range(int(rect.position.y) + 48, int(rect.end.y) - 6, 22):
		ci.draw_line(Vector2(rect.position.x + 10, y), Vector2(rect.end.x - 10, y), Color(0.55, 0.7, 0.85, 0.35), 1.0)
	ci.draw_circle(Vector2(rect.get_center().x, rect.position.y + 10), 7, Color("d9534a"))
	ci.draw_circle(Vector2(rect.get_center().x - 2, rect.position.y + 8), 2.5, Color(1, 1, 1, 0.6))


# =====================================================================
# Personajes
# =====================================================================

static func random_look(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"skin": SKINS[rng.randi() % SKINS.size()],
		"hair": HAIRS[rng.randi() % HAIRS.size()],
		"style": rng.randi() % 7,
		"shirt": SHIRTS[rng.randi() % SHIRTS.size()],
		"cap": SHIRTS[rng.randi() % SHIRTS.size()],
		"acc": rng.randi() % 5,
		"w": rng.randf_range(0.88, 1.15),
		"seed": rng.randi() % 1000,
	}


## La moza del mostrador: uniforme, delantal, libreta y birome.
static func waiter_look() -> Dictionary:
	return {"skin": SKINS[2], "hair": HAIRS[2], "style": 3, "shirt": Color("2f5d50"), "cap": Color.WHITE,
		"acc": 3, "w": 0.98, "seed": 21, "apron": true, "notepad": true, "writing": false}


static func chef_look() -> Dictionary:
	return {"skin": SKINS[1], "hair": HAIRS[1], "style": 7, "shirt": Color("fbfbf8"), "cap": Color.WHITE,
		"acc": 2, "w": 1.12, "seed": 3}


## Dibuja un personaje (torso y cabeza). `pos` es el punto de abajo al centro.
## mood: 0 contento, 1 normal, 2 molesto, 3 enojado.
static func draw_character(ci: CanvasItem, look: Dictionary, pos: Vector2, s: float, mood: int, time: float,
		head_only := false, bob := 0.0) -> void:
	var sd: int = look.get("seed", 0)
	var breathe := sin(time * 2.2 + sd) * 1.2
	var w: float = look.get("w", 1.0)
	var skin: Color = look["skin"]
	var hair: Color = look["hair"]
	var shirt: Color = look["shirt"]
	var style: int = look["style"]
	var hc := pos + Vector2(0, -112 + breathe * 0.5 - bob) * s     # centro de la cabeza
	if head_only:
		hc = pos + Vector2(0, -34) * s

	if not head_only:
		var top := pos.y + (-82 + breathe - bob) * s
		var dark := shirt.darkened(0.06 if shirt.v > 0.9 else 0.18)
		rrect(ci, Rect2(pos.x - 50 * w * s, top + 8 * s, 18 * w * s, pos.y - top), dark, 9 * s)
		rrect(ci, Rect2(pos.x + 32 * w * s, top + 8 * s, 18 * w * s, pos.y - top), dark, 9 * s)
		rrect(ci, Rect2(pos.x - 38 * w * s, top, 76 * w * s, pos.y - top + 20 * s), shirt, 24 * s)
		# Volumen del torso: lado derecho en sombra y brillo en los hombros
		rrect(ci, Rect2(pos.x + 10 * w * s, top + 4 * s, 28 * w * s, pos.y - top + 16 * s), Color(shirt.darkened(0.16), 0.7), 20 * s)
		rrect(ci, Rect2(pos.x - 30 * w * s, top + 3 * s, 30 * w * s, 8 * s), Color(1, 1, 1, 0.12), 6 * s)
		if style == 7:
			for k in 3:
				for side in [-1, 1]:
					ci.draw_circle(Vector2(pos.x + side * 12 * s, top + (24 + k * 18) * s), 3 * s, Color("c9c9c0"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 14 * s, top), Vector2(pos.x + 14 * s, top),
				Vector2(pos.x, top + 12 * s)]), Color("d9534a"))
		else:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 11 * s, top), Vector2(pos.x + 11 * s, top),
				Vector2(pos.x, top + 16 * s)]), skin.darkened(0.08))
		ci.draw_rect(Rect2(hc.x - 9 * s, hc.y + 20 * s, 18 * s, top - hc.y - 18 * s), skin.darkened(0.12))
		ellipse(ci, hc + Vector2(0, 28) * s, Vector2(13, 5) * s, Color(skin.darkened(0.35), 0.6))   # sombra del mentón
		if look.get("apron", false):
			# Delantal con tiras al cuello y bolsillo
			rrect(ci, Rect2(pos.x - 26 * s, top + 22 * s, 52 * s, pos.y - top), Color("f4efe2"), 8 * s)
			ci.draw_line(Vector2(pos.x - 20 * s, top + 24 * s), Vector2(pos.x - 8 * s, top + 2 * s), Color("f4efe2"), 3 * s)
			ci.draw_line(Vector2(pos.x + 20 * s, top + 24 * s), Vector2(pos.x + 8 * s, top + 2 * s), Color("f4efe2"), 3 * s)
			rrect(ci, Rect2(pos.x - 12 * s, top + 52 * s, 24 * s, 14 * s), Color("e3dccb"), 3 * s)
			rrect(ci, Rect2(pos.x + 14 * s, top + 8 * s, 18 * s, 7 * s), Color("d9a520"), 2 * s)   # identificación
		if look.get("notepad", false):
			_draw_notepad(ci, pos, top, s, time, look.get("writing", false))

	# Pelo largo (atrás de la cabeza)
	if style == 1:
		rrect(ci, Rect2(hc.x - 35 * s, hc.y - 20 * s, 70 * s, 66 * s), hair, 28 * s)

	# Orejas y cabeza
	ci.draw_circle(hc + Vector2(-30, 2) * s, 7 * s, skin.darkened(0.08))
	ci.draw_circle(hc + Vector2(30, 2) * s, 7 * s, skin.darkened(0.08))
	# Cabeza con volumen: sombra abajo a la derecha, luz arriba a la izquierda
	ci.draw_circle(hc, 30 * s, skin.darkened(0.13))
	ci.draw_circle(hc + Vector2(-1.8, -1.8) * s, 28.2 * s, skin)
	ellipse(ci, hc + Vector2(-10, -14) * s, Vector2(9, 4.5) * s, Color(1, 1, 1, 0.16))
	if mood == 3:
		ci.draw_circle(hc, 30 * s, Color(1, 0.1, 0.05, 0.22))

	_draw_hair(ci, look, hc, s, time)

	# Cara
	var blink := fmod(time + sd * 0.37, 4.0) < 0.12
	for side in [-1, 1]:
		var e: Vector2 = hc + Vector2(side * 11, 0) * s
		if blink:
			ci.draw_line(e + Vector2(-3.5, 0) * s, e + Vector2(3.5, 0) * s, INK, 2.0 * s)
		else:
			ci.draw_circle(e, 3.8 * s, INK)
			ci.draw_circle(e + Vector2(-1.2, -1.2) * s, 1.3 * s, Color.WHITE)
		var b_in := Vector2(side * 6, -10) * s
		var b_out := Vector2(side * 16, -10) * s
		if mood == 3:
			b_in.y += 4 * s
			b_out.y -= 2 * s
		elif mood == 2:
			b_in.y -= 2 * s
			b_out.y += 2 * s
		ci.draw_line(hc + b_in, hc + b_out, hair.darkened(0.2), 2.6 * s)
	ci.draw_circle(hc + Vector2(0, 8) * s, 3.6 * s, skin.darkened(0.15))
	var mouth := hc + Vector2(0, 16) * s
	match mood:
		0:
			ci.draw_arc(mouth + Vector2(0, -4) * s, 9 * s, 0.15 * PI, 0.85 * PI, 14, INK, 2.6 * s)
			ci.draw_circle(hc + Vector2(-19, 10) * s, 5 * s, Color(1, 0.45, 0.45, 0.35))
			ci.draw_circle(hc + Vector2(19, 10) * s, 5 * s, Color(1, 0.45, 0.45, 0.35))
		1:
			ci.draw_line(mouth + Vector2(-7, 0) * s, mouth + Vector2(7, 0) * s, INK, 2.6 * s)
		_:
			ci.draw_arc(mouth + Vector2(0, 8) * s, 9 * s, 1.15 * PI, 1.85 * PI, 14, INK, 2.6 * s)

	# Accesorios
	match int(look.get("acc", 0)):
		1:
			for side in [-1, 1]:
				ci.draw_arc(hc + Vector2(side * 11, 0) * s, 8 * s, 0, TAU, 20, Color("2a2a2a"), 2.2 * s)
			ci.draw_line(hc + Vector2(-3, 0) * s, hc + Vector2(3, 0) * s, Color("2a2a2a"), 2.2 * s)
		2:
			ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(-13, 14) * s, hc + Vector2(-4, 10) * s,
				hc + Vector2(0, 12) * s, hc + Vector2(4, 10) * s, hc + Vector2(13, 14) * s, hc + Vector2(0, 16) * s]), hair.darkened(0.1))
		3:
			ci.draw_circle(hc + Vector2(-30, 10) * s, 3 * s, Color("e3c26a"))
			ci.draw_circle(hc + Vector2(30, 10) * s, 3 * s, Color("e3c26a"))
		4:
			for f in [Vector2(-18, 6), Vector2(-14, 9), Vector2(-20, 11), Vector2(18, 6), Vector2(14, 9), Vector2(20, 11)]:
				ci.draw_circle(hc + f * s, 1.2 * s, skin.darkened(0.35))

	if mood == 3:
		steam(ci, hc + Vector2(-26, -34) * s, time * 2.0, 1.4, 1, Color(0.9, 0.9, 0.9))
		steam(ci, hc + Vector2(26, -34) * s, time * 2.0, 1.4, 5, Color(0.9, 0.9, 0.9))


## Libreta en la mano izquierda y birome en la derecha; al escribir la birome va y viene por la hoja.
static func _draw_notepad(ci: CanvasItem, pos: Vector2, top: float, s: float, time: float, writing: bool) -> void:
	var pad := Rect2(pos.x - 30 * s, top + 26 * s, 30 * s, 38 * s)
	rrect(ci, Rect2(pad.position + Vector2(2, 3) * s, pad.size), Color(0, 0, 0, 0.25), 3 * s)
	rrect(ci, pad, Color("fffdf5"), 3 * s, Color("c9b98a"), 1)
	ci.draw_rect(Rect2(pad.position, Vector2(pad.size.x, 5 * s)), Color("d9534a"))
	for l in 5:
		var y := pad.position.y + (11 + l * 5.5) * s
		ci.draw_line(Vector2(pad.position.x + 3 * s, y), Vector2(pad.end.x - 3 * s, y), Color(0.6, 0.75, 0.9, 0.7), 1.0)
	# Lo que ya anotó (garabatos que crecen mientras escribe)
	var lines_done := 2 + int(fmod(time * 2.0, 3.0)) if writing else 2
	for l in lines_done:
		var y := pad.position.y + (10 + l * 5.5) * s
		var pts := PackedVector2Array()
		for p in 7:
			pts.append(Vector2(pad.position.x + (4 + p * 3.2) * s, y + sin(p * 2.1 + l) * 1.2 * s))
		ci.draw_polyline(pts, Color("2b3a8a"), 1.2, true)
	# Mano que sostiene la libreta
	ci.draw_circle(Vector2(pad.position.x + 2 * s, pad.end.y - 4 * s), 6 * s, Color("d9a074"))
	# Birome: la punta se mueve sobre la hoja cuando escribe
	var tip := Vector2(pad.position.x + 18 * s, pad.position.y + 20 * s)
	if writing:
		tip += Vector2(sin(time * 22.0) * 7.0, fmod(time * 2.0, 1.0) * 10.0 - 4.0) * s
	var back := tip + Vector2(14, -20) * s
	ci.draw_line(tip, back, Color("2b5ab8"), 3.2 * s)
	ci.draw_line(back, back + Vector2(2, -3) * s, Color("1d1d26"), 3.2 * s)
	ci.draw_circle(tip, 1.2 * s, Color("1d1d26"))
	ci.draw_circle(tip + Vector2(10, -12) * s, 6 * s, Color("d9a074"))


static func _draw_hair(ci: CanvasItem, look: Dictionary, hc: Vector2, s: float, _time: float) -> void:
	var hair: Color = look["hair"]
	var style: int = look["style"]
	var cap_pts := PackedVector2Array()
	for k in 15:
		var a := PI + PI * k / 14.0
		cap_pts.append(hc + Vector2(cos(a), sin(a)) * 32.5 * s)
	for p in [Vector2(28, -6), Vector2(14, -14), Vector2(0, -11), Vector2(-14, -15), Vector2(-28, -6)]:
		cap_pts.append(hc + p * s)
	match style:
		0, 1:
			ci.draw_colored_polygon(cap_pts, hair)
			ci.draw_arc(hc + Vector2(0, -2) * s, 26 * s, PI * 1.18, PI * 1.5, 10, Color(hair.lightened(0.35), 0.55), 3 * s)
		2:
			for k in 9:
				var a := PI + PI * k / 8.0
				ci.draw_circle(hc + Vector2(cos(a), sin(a)) * 30 * s, 12 * s, hair)
			ci.draw_circle(hc + Vector2(0, -30) * s, 16 * s, hair)
			ci.draw_circle(hc + Vector2(-14, -24) * s, 14 * s, hair)
			ci.draw_circle(hc + Vector2(14, -24) * s, 14 * s, hair)
		3:
			ci.draw_circle(hc + Vector2(0, -38) * s, 13 * s, hair)
			ci.draw_colored_polygon(cap_pts, hair)
		4:
			ellipse(ci, hc + Vector2(-27, -2) * s, Vector2(6, 12) * s, hair)
			ellipse(ci, hc + Vector2(27, -2) * s, Vector2(6, 12) * s, hair)
			ellipse(ci, hc + Vector2(-10, -22) * s, Vector2(8, 4) * s, Color(1, 1, 1, 0.35))
		5:
			var cap: Color = look.get("cap", Color("d9534a"))
			var pts := PackedVector2Array()
			for k in 15:
				var a := PI + PI * k / 14.0
				pts.append(hc + Vector2(cos(a), sin(a) * 0.9) * 33 * s + Vector2(0, -4) * s)
			ci.draw_colored_polygon(pts, cap)
			rrect(ci, Rect2(hc + Vector2(-6, -9) * s, Vector2(46, 8) * s), cap.darkened(0.2), 4 * s)
			ci.draw_circle(hc + Vector2(0, -33) * s, 3.5 * s, cap.darkened(0.25))
		6:
			var spikes := PackedVector2Array()
			spikes.append(hc + Vector2(-31, -4) * s)
			for k in 7:
				var x := -27 + k * 9
				spikes.append(hc + Vector2(x, -22 - abs(3 - k) * -2.0 - 12) * s)
				spikes.append(hc + Vector2(x + 4.5, -24) * s)
			spikes.append(hc + Vector2(31, -4) * s)
			spikes.append(hc + Vector2(0, -12) * s)
			ci.draw_colored_polygon(spikes, hair)
		7:
			ci.draw_colored_polygon(cap_pts, hair)
			var hat := Color("fbfbf8")
			rrect(ci, Rect2(hc + Vector2(-27, -36) * s, Vector2(54, 16) * s), hat, 3 * s, Color("d8d8d0"), 1)
			ci.draw_circle(hc + Vector2(-17, -50) * s, 17 * s, hat)
			ci.draw_circle(hc + Vector2(17, -50) * s, 17 * s, hat)
			ci.draw_circle(hc + Vector2(0, -60) * s, 20 * s, hat)
			ci.draw_arc(hc + Vector2(0, -60) * s, 20 * s, PI * 1.1, PI * 1.6, 10, Color("e6e6de"), 2.0 * s)
