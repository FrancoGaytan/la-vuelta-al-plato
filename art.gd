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
	"Tomate": Color("c8341f"), "Blanca": Color("f3ecd8"), "Pomodoro": Color("d23a22"), "Alfredo": Color("f5ecd0"),
	"Salsa verde": Color("6a9a2a"), "Salsa roja": Color("b8281a"), "Guacamole": Color("8ab83a"),
	"Miel de maple": Color("b8661a"),
	"Choco-avellanas": Color("5a3218"), "Caramelo": Color("c8862a"), "Limón y azúcar": Color("f2e48a"), "Bechamel": Color("f6f0dc"),
	"Raita": Color("f2f2e8"), "Chutney de menta": Color("4f9a3a"),
	"Shoyu": Color("8a4a1e"), "Miso": Color("c8964a"), "Tonkotsu": Color("f2ead2"), "Salsa yakisoba": Color("6a3018"), "Teriyaki": Color("7a3a14"),
	"Chocolate": Color("4a2412"), "Café": Color("a0703a"), "Frutilla": Color("f28aa8"),
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
	# Italia
	"Mozzarella": {"color": Color("fbf8ee"), "shape": "blob"},
	"Jamón": {"color": Color("e8a0a0"), "shape": "square"},
	"Aceitunas": {"color": Color("2a2622"), "shape": "olive"},
	"Champiñones": {"color": Color("dcc9a6"), "shape": "mushroom"},
	"Pepperoni": {"color": Color("b8322a"), "shape": "disc"},
	"Parmesano": {"color": Color("f3e4ac"), "shape": "flake"},
	"Cacao": {"color": Color("5a3218"), "shape": "sugar"},
	# México
	"Cebolla y cilantro": {"color": Color("f4f0e8"), "shape": "cube"},
	"Piña": {"color": Color("f6d040"), "shape": "cube"},
	"Jalapeños": {"color": Color("3f8a2a"), "shape": "ring"},
	"Queso fresco": {"color": Color("fbf8ee"), "shape": "dot"},
	"Azúcar y canela": {"color": Color("c8955a"), "shape": "sugar"},
	"Chocolate": {"color": Color("4a2412"), "shape": "drizzle"},
	# EE.UU.
	"Manteca": {"color": Color("f8e48a"), "shape": "square"},
	"Frutillas": {"color": Color("d9283a"), "shape": "disc"},
	"Arándanos": {"color": Color("3a3a8a"), "shape": "olive"},
	"Cereza": {"color": Color("c8102e"), "shape": "disc"},
	# Francia
	"Banana": {"color": Color("f6e08a"), "shape": "disc"},
	"Queso gruyère": {"color": Color("f2d16b"), "shape": "flake"},
	"Ciboulette": {"color": Color("3f8f2f"), "shape": "strip"},
	"Mermelada": {"color": Color("b8102e"), "shape": "dollop"},
	# India
	"Cilantro": {"color": Color("3f8f2f"), "shape": "leaf"},
	"Yogur": {"color": Color("fbfbf4"), "shape": "dollop"},
	"Cebolla morada": {"color": Color("a84a8a"), "shape": "ring"},
	# Japón
	"Salmón": {"color": Color("f28a5a"), "shape": "square"},
	"Palta": {"color": Color("8ab83a"), "shape": "slice"},
	"Pepino": {"color": Color("5a9a3a"), "shape": "slice"},
	"Queso crema": {"color": Color("fbf6ea"), "shape": "dollop"},
	"Kanikama": {"color": Color("e8503a"), "shape": "strip"},
	"Huevo marinado": {"color": Color("ffffff"), "shape": "egg_half"},
	"Cebollita": {"color": Color("6fbf4a"), "shape": "ring"},
	"Nori": {"color": Color("1d2a1e"), "shape": "square"},
	"Chashu": {"color": Color("c8865a"), "shape": "disc"},
	"Sésamo": {"color": Color("f2e6c8"), "shape": "seed"},
	"Jengibre rojo": {"color": Color("e8506a"), "shape": "strip"},
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
	if e.has("fillings"):
		draw_maki(ci, rect, e["fillings"])
		return
	if e.has("spices"):
		draw_masala(ci, rect, e["spices"])
		return
	if e.has("piped"):
		draw_eclair(ci, rect, e["piped"])
		return
	if e.has("layers"):
		draw_burger(ci, rect, e["layers"], true, e.get("patty_t", -1.0), e.get("vtarget", 7.0), e.get("burn", 14.0))
		return
	if e.get("item", "") == "pizza":
		draw_pizza(ci, rect, e.get("pizza", {}), e.get("ta", 0.0), e.get("tb", 0.0), e.get("vtarget", 9.0), e.get("burn", 15.0), e.get("rot", 0.0))
		return
	if e.get("t", -1.0) >= 0.0:
		draw_cooking(ci, e["item"], rect, e["t"], e["vtarget"], e["burn"])
	else:
		draw_food(ci, e["item"], rect, Color.WHITE, e.get("chopped", false))


# =====================================================================
# Primitivas
# =====================================================================

static var _sb_cache := {}


## Rectángulo redondeado. Los estilos se guardan y se reusan (crear uno nuevo en cada dibujo es caro).
static func rrect(ci: CanvasItem, rect: Rect2, color: Color, radius := 8.0, border := Color(0, 0, 0, 0), bw := 0) -> void:
	var key := [color, int(radius), border if bw > 0 else Color(0, 0, 0, 0), bw]
	var sb: StyleBoxFlat = _sb_cache.get(key)
	if sb == null:
		if _sb_cache.size() > 4000:
			_sb_cache.clear()
		sb = StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(int(radius))
		if bw > 0:
			sb.border_color = border
			sb.set_border_width_all(bw)
		sb.anti_aliasing = true
		_sb_cache[key] = sb
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
		"blob":
			return [0.1, 18]
		"olive", "disc", "mushroom":
			return [0.16, 12]
		"slice", "square", "strip":
			return [0.32, 6]
		"egg":
			return [0.9, 1]
		"egg_half":
			return [0.7, 2]
		"dollop":
			return [0.5, 3]
		"drizzle":
			return [0.13, 20]     # gotitas sueltas, no un chorro
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
			_drizzle_drops(ci, center, radius, pts, info["color"], k, idx)
			continue
		for j in pts.size():
			var rng := RandomNumberGenerator.new()
			rng.seed = idx * 1009 + j * 31
			draw_topping_piece(ci, center + pts[j] * radius, k, info["color"], info["shape"], rng)


## Dulce de leche delicado: gotitas brillantes de distinto tamaño y, entre algunas cercanas, un hilito finísimo.
static func _drizzle_drops(ci: CanvasItem, center: Vector2, radius: float, pts: Array, col: Color, k: float, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	for j in pts.size():
		var p: Vector2 = center + pts[j] * radius
		if j > 0:
			var q: Vector2 = center + pts[j - 1] * radius
			if p.distance_to(q) < radius * 0.22 and j % 3 != 0:
				ci.draw_line(q, p, Color(col, 0.45), maxf(0.7, 0.7 * k), true)
	for j in pts.size():
		rng.seed = idx * 977 + j * 53
		var p: Vector2 = center + pts[j] * radius
		var r := rng.randf_range(1.4, 2.6) * k
		ellipse(ci, p + Vector2(0.4, 0.6) * k, Vector2(r * 1.1, r * 0.9), col.darkened(0.25))
		ellipse(ci, p, Vector2(r * 1.05, r * 0.85), col)
		ci.draw_circle(p + Vector2(-r * 0.35, -r * 0.3), r * 0.32, Color(1, 0.93, 0.78, 0.75))


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
		"blob":
			# Mozzarella: manchón blanco irregular (se dora en el horno)
			draw_sauce(ci, p, 8 * k * v, col, rng.randi())
			ci.draw_circle(p + Vector2(-2, -2) * k, 2.5 * k, Color(1, 1, 1, 0.8))
		"olive":
			ci.draw_circle(p, 5 * k * v, col)
			ci.draw_circle(p, 2 * k * v, Color("4a3a2a"))
			ci.draw_circle(p + Vector2(-1.5, -1.5) * k, 1.2 * k, Color(1, 1, 1, 0.5))
		"disc":
			# Pepperoni: rodaja roja con puntitos de grasa
			ci.draw_circle(p, 7 * k * v, col.darkened(0.2))
			ci.draw_circle(p, 6 * k * v, col)
			for s in 4:
				ci.draw_circle(p + Vector2(rng.randf_range(-3.5, 3.5), rng.randf_range(-3.5, 3.5)) * k, 0.9 * k, Color("f2c9b8"))
		"mushroom":
			ci.draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
			ellipse(ci, Vector2(0, -2) * k, Vector2(6, 4) * k * v, col)
			ci.draw_rect(Rect2(Vector2(-1.8, -1) * k, Vector2(3.6, 6) * k * v), col.lightened(0.15))
			ci.draw_arc(Vector2(0, -2) * k, 6 * k * v, PI, TAU, 8, col.darkened(0.3), 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
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
		"Mozzarella":
			ci.draw_circle(c + Vector2(1, 2) * u, 13 * u, Color("c9c1a8"))
			ci.draw_circle(c, 13 * u, Color("fbf8ee"))
			ci.draw_circle(c + Vector2(-4, -4) * u, 4 * u, Color(1, 1, 1, 0.9))
			ci.draw_arc(c, 13 * u, PI * 0.1, PI * 0.9, 10, Color("ddd5bf"), 1.5 * u)
		"Jamón":
			ci.draw_colored_polygon(PackedVector2Array([P.call(-14, -8), P.call(12, -12), P.call(15, 6), P.call(-10, 12)]), Color("e8a0a0"))
			ci.draw_polyline(PackedVector2Array([P.call(-14, -8), P.call(12, -12), P.call(15, 6)]), Color("fbe6e0"), 2.5 * u)
			ci.draw_colored_polygon(PackedVector2Array([P.call(-10, 12), P.call(15, 6), P.call(6, 14)]), Color("c87a7a"))
		"Aceitunas":
			for q in [[-6, 2], [6, -3]]:
				var p: Vector2 = P.call(q[0], q[1])
				ellipse(ci, p, Vector2(8, 6.5) * u, Color("2a2622"))
				ellipse(ci, p, Vector2(3, 2.5) * u, Color("5a4a3a"))
				ci.draw_circle(p + Vector2(-3, -3) * u, 1.5 * u, Color(1, 1, 1, 0.5))
		"Champiñones":
			ellipse(ci, P.call(0, -2), Vector2(14, 9) * u, Color("dcc9a6"))
			ci.draw_arc(P.call(0, -2), 14 * u, PI, TAU, 14, Color("a88a62"), 1.5 * u)
			Art_mush_stem(ci, P.call(0, 4), u)
		"Pepperoni":
			for q in [[-6, -3], [6, 2], [-1, 8]]:
				var p: Vector2 = P.call(q[0], q[1])
				ci.draw_circle(p, 7 * u, Color("8a2018"))
				ci.draw_circle(p, 6 * u, Color("b8322a"))
				for d in [[-2, -2], [2, 1], [-1, 3]]:
					ci.draw_circle(p + Vector2(d[0], d[1]) * u, 0.9 * u, Color("f2c9b8"))
		"Parmesano":
			ci.draw_colored_polygon(PackedVector2Array([P.call(-14, 8), P.call(12, 8), P.call(12, -6), P.call(-14, 2)]), Color("f3e4ac"))
			ci.draw_colored_polygon(PackedVector2Array([P.call(-14, 2), P.call(12, -6), P.call(15, -8), P.call(-11, -1)]), Color("e0c27a"))
			for k in 6:
				ci.draw_circle(P.call(-10 + k * 4, 12 + (k % 2)), 0.9 * u, Color("e8d89a"))
		"Cacao":
			ellipse(ci, P.call(0, 4), Vector2(14, 7) * u, Color("5a3218"))
			ellipse(ci, P.call(0, 1), Vector2(9, 5) * u, Color("6e3e1e"))
			ellipse(ci, P.call(7, -8), Vector2(5, 3) * u, Color("3a1e10"))
			ci.draw_line(P.call(4, -8), P.call(10, -8), Color("6e3e1e"), 1.0)
		"Cebolla y cilantro":
			for k in 5:
				rrect(ci, Rect2(P.call(-12 + k * 5, -2 + (k % 2) * 6), Vector2(5, 5) * u), Color("f6f2ea"), 1.5 * u, Color("d8cfc0"), 1)
			for k in 3:
				_leaf_icon(ci, P.call(-8 + k * 9, -10 + (k % 2) * 3), 7 * u, -0.6 + k * 0.5, Color("3f8f2f"))
		"Piña":
			for k in 4:
				var pc: Vector2 = P.call(-9 + (k % 2) * 12, -6 + (k / 2) * 11)
				rrect(ci, Rect2(pc - Vector2(5, 5) * u, Vector2(10, 9) * u), Color("f6d040"), 2 * u, Color("d8a820"), 1)
				ci.draw_line(pc + Vector2(-3, -2) * u, pc + Vector2(3, 2) * u, Color("e8b82a"), 1.0)
		"Jalapeños":
			for k in 3:
				var jc: Vector2 = P.call(-9 + k * 9, (k % 2) * 6 - 3)
				ci.draw_circle(jc, 6 * u, Color("2f7a22"))
				ci.draw_circle(jc, 4 * u, Color("a8d06a"))
				for d in 3:
					ci.draw_circle(jc + Vector2.from_angle(d * 2.1) * 2 * u, 0.9 * u, Color("f6f0d0"))
		"Queso fresco":
			for k in 4:
				rrect(ci, Rect2(P.call(-12 + (k % 2) * 12, -8 + (k / 2) * 10), Vector2(9, 8) * u), Color("fbf8ee"), 2 * u, Color("e2d8c0"), 1)
		"Azúcar y canela":
			ellipse(ci, P.call(0, 4), Vector2(15, 7) * u, Color("e8d2a8"))
			for k in 14:
				ci.draw_circle(P.call(-11 + (k * 7) % 22, -1 + (k * 3) % 8), 0.9 * u, Color("8a5a2a") if k % 3 == 0 else Color.WHITE)
			rrect(ci, Rect2(P.call(-14, -10), Vector2(22, 4) * u), Color("9a5a2a"), 2 * u)
		"Chocolate":
			rrect(ci, Rect2(P.call(-12, -10), Vector2(24, 18) * u), Color("4a2412"), 2 * u)
			for k in 3:
				ci.draw_line(P.call(-12 + k * 8, -10), P.call(-12 + k * 8, 8), Color("2e1408"), 1.2)
			ci.draw_line(P.call(-12, -1), P.call(12, -1), Color("2e1408"), 1.2)
			ellipse(ci, P.call(-6, -7), Vector2(4, 1.5) * u, Color(1, 1, 1, 0.2))
		"Manteca":
			rrect(ci, Rect2(P.call(-12, -8), Vector2(24, 16) * u), Color("f8e48a"), 3 * u, Color("d8b84a"), 1)
			rrect(ci, Rect2(P.call(-10, -8), Vector2(20, 5) * u), Color("fff2b0"), 2 * u)
		"Frutillas":
			for k in 2:
				var fc: Vector2 = P.call(-7 + k * 14, (k % 2) * 4)
				ci.draw_colored_polygon(PackedVector2Array([fc + Vector2(-8, -6) * u, fc + Vector2(8, -6) * u, fc + Vector2(0, 12) * u]), Color("d9283a"))
				ci.draw_circle(fc + Vector2(0, -6) * u, 8 * u, Color("d9283a"))
				for d in 4:
					ci.draw_circle(fc + Vector2(-4 + (d % 2) * 8, -2 + (d / 2) * 6) * u, 0.9 * u, Color("f6e08a"))
				_leaf_icon(ci, fc + Vector2(0, -13) * u, 6 * u, -1.57, Color("3f8f2f"))
		"Arándanos":
			for k in 5:
				var bc: Vector2 = P.call(-10 + (k % 3) * 10, -4 + (k / 3) * 10)
				ci.draw_circle(bc, 6 * u, Color("3a3a8a"))
				ci.draw_circle(bc + Vector2(-2, -2) * u, 1.6 * u, Color(1, 1, 1, 0.35))
		"Cereza":
			ci.draw_circle(P.call(0, 4), 10 * u, Color("c8102e"))
			ci.draw_circle(P.call(-3, 1), 3 * u, Color(1, 1, 1, 0.35))
			ci.draw_line(P.call(0, -5), P.call(6, -16), Color("3f7a28"), 2.0 * u)
		"Banana":
			for k in 3:
				var bc: Vector2 = P.call(-10 + k * 10, (k % 2) * 6 - 3)
				ci.draw_circle(bc, 7 * u, Color("f2dc8a"))
				ci.draw_circle(bc, 5 * u, Color("fbf0c4"))
				ci.draw_circle(bc, 1.2 * u, Color("8a6a2a"))
		"Queso gruyère":
			var wedge := PackedVector2Array([P.call(-14, 8), P.call(14, 8), P.call(14, -6), P.call(-14, 2)])
			ci.draw_colored_polygon(wedge, Color("f2d16b"))
			for h in [[-6, 4, 2.5], [5, 2, 3.0], [10, -2, 1.8]]:
				ci.draw_circle(P.call(h[0], h[1]), h[2] * u, Color("d9b24a"))
		"Ciboulette":
			for k in 7:
				ci.draw_line(P.call(-12 + k * 4, -10 + (k % 3) * 3), P.call(-10 + k * 4, 10 - (k % 2) * 4), Color("3f8f2f"), 2.2 * u)
		"Mermelada":
			ellipse(ci, P.call(0, 4), Vector2(14, 9) * u, Color("8a0a20"))
			ellipse(ci, P.call(0, 2), Vector2(11, 7) * u, Color("c8102e"))
			ellipse(ci, P.call(-4, 0), Vector2(4, 2) * u, Color(1, 1, 1, 0.35))
		"Cilantro":
			for k in 4:
				_leaf_icon(ci, P.call(-9 + (k % 2) * 12, -6 + (k / 2) * 10), 9 * u, -0.8 + k * 0.6, Color("3f8f2f"))
		"Yogur":
			ellipse(ci, P.call(0, 6), Vector2(14, 6) * u, Color("e8e8dc"))
			ci.draw_circle(P.call(0, 0), 9 * u, Color("fbfbf4"))
			ci.draw_circle(P.call(4, -6), 5 * u, Color("fbfbf4"))
			ci.draw_circle(P.call(-3, -3), 2 * u, Color(1, 1, 1, 0.9))
		"Cebolla morada":
			for k in 3:
				var oc: Vector2 = P.call(-9 + k * 9, (k % 2) * 6 - 3)
				ci.draw_arc(oc, 7 * u, 0, TAU, 16, Color("a84a8a"), 2.5 * u)
				ci.draw_arc(oc, 4 * u, 0, TAU, 12, Color("e8c8e0"), 1.5 * u)
		"Salmón":
			rrect(ci, Rect2(P.call(-14, -8), Vector2(28, 16) * u), Color("f28a5a"), 3 * u)
			for k in 4:
				ci.draw_line(P.call(-10 + k * 7, -8), P.call(-14 + k * 7, 8), Color("fbd2b8"), 1.6 * u)
		"Palta":
			ellipse(ci, P.call(0, 2), Vector2(13, 15) * u, Color("2f4a1a"))
			ellipse(ci, P.call(0, 2), Vector2(11, 13) * u, Color("cfe08a"))
			ci.draw_circle(P.call(0, 5), 5 * u, Color("7a4a24"))
		"Pepino":
			for k in 3:
				var pc2: Vector2 = P.call(-9 + k * 9, (k % 2) * 5 - 2)
				ci.draw_circle(pc2, 7 * u, Color("3f7a28"))
				ci.draw_circle(pc2, 5.5 * u, Color("c8e8a0"))
				ci.draw_circle(pc2, 1.5 * u, Color("8ab86a"))
		"Queso crema":
			rrect(ci, Rect2(P.call(-13, -6), Vector2(26, 14) * u), Color("fbf6ea"), 4 * u, Color("e2d8c0"), 1)
			ellipse(ci, P.call(-4, -3), Vector2(6, 2) * u, Color(1, 1, 1, 0.9))
		"Kanikama":
			for k in 3:
				rrect(ci, Rect2(P.call(-14, -10 + k * 8), Vector2(28, 6) * u), Color("f8f2ea"), 3 * u)
				rrect(ci, Rect2(P.call(-14, -10 + k * 8), Vector2(28, 3) * u), Color("e8503a"), 2 * u)
		"Huevo marinado":
			ellipse(ci, P.call(0, 2), Vector2(13, 11) * u, Color("e8c08a"))
			ci.draw_circle(P.call(0, 2), 6 * u, Color("f2a81d"))
			ci.draw_circle(P.call(-1, 1), 2.5 * u, Color("f6c84a"))
		"Cebollita":
			for k in 5:
				var cc2: Vector2 = P.call(-10 + (k % 3) * 10, -4 + (k / 3) * 9)
				ci.draw_arc(cc2, 4 * u, 0, TAU, 12, Color("6fbf4a"), 2 * u)
		"Nori":
			rrect(ci, Rect2(P.call(-12, -12), Vector2(24, 24) * u), Color("1d2a1e"), 2 * u)
			ci.draw_line(P.call(-8, -8), P.call(6, -8), Color(1, 1, 1, 0.12), 1.5 * u)
		"Chashu":
			ci.draw_circle(P.call(0, 2), 13 * u, Color("8a4a1e"))
			ci.draw_circle(P.call(0, 2), 10 * u, Color("e8a87a"))
			ci.draw_arc(P.call(0, 2), 6 * u, 0, 4.5, 12, Color("fbe0c8"), 2 * u)
		"Sésamo":
			for k in 9:
				ellipse(ci, P.call(-10 + (k % 3) * 10, -8 + (k / 3) * 8), Vector2(2.4, 1.4) * u, Color("f2e6c8") if k % 2 == 0 else Color("3a3a3a"))
		"Jengibre rojo":
			for k in 4:
				ci.draw_line(P.call(-12 + k * 6, -10), P.call(-8 + k * 6, 10), Color("e8506a"), 3 * u)
		_:
			text(ci, c + Vector2(-s, 4), name.left(1), int(s * 0.6), INK, HORIZONTAL_ALIGNMENT_CENTER, s * 2)


static func Art_mush_stem(ci: CanvasItem, p: Vector2, u: float) -> void:
	rrect(ci, Rect2(p + Vector2(-4, -2) * u, Vector2(8, 10) * u), Color("f0e4cc"), 3 * u)


# --- Italia: pizza y masa ---

static func _crust_color(t: float, target: float, burn: float) -> Color:
	if t < 0.0:
		return Color("f1e2bc")       # masa cruda
	if t >= burn:
		return Color("3a2a20")
	if t <= target:
		return Color("f1e2bc").lerp(Color("e3a64a"), t / target)
	return Color("e3a64a").lerp(Color("7a4a1e"), (t - target) / (burn - target))


## Bollo de masa
static func draw_dough(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.4
	ellipse(ci, c + Vector2(2, r * 0.6), Vector2(r * 1.05, r * 0.35), Color(0, 0, 0, 0.18))
	ellipse(ci, c, Vector2(r, r * 0.85), Color("e9d6a8"))
	ellipse(ci, c + Vector2(-r * 0.2, -r * 0.25), Vector2(r * 0.55, r * 0.35), Color("f8ecd0"))
	for k in 6:
		ci.draw_circle(c + Vector2(cos(k * 2.0) * r * 0.6, sin(k * 1.3) * r * 0.5), 1.2, Color(1, 1, 1, 0.8))


## Bolsa de harina de papel, abierta arriba
static func draw_flour_bag(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	var h := minf(rect.size.y * 0.8, rect.size.x)
	var w := h * 0.7
	ellipse(ci, c + Vector2(4, h * 0.46), Vector2(w * 0.6, h * 0.08), Color(0, 0, 0, 0.2))
	var bag := PackedVector2Array([c + Vector2(-w * 0.5, h * 0.45), c + Vector2(-w * 0.46, -h * 0.32), c + Vector2(-w * 0.3, -h * 0.42),
		c + Vector2(w * 0.3, -h * 0.4), c + Vector2(w * 0.46, -h * 0.33), c + Vector2(w * 0.5, h * 0.45)])
	ci.draw_colored_polygon(bag, Color("e8dcc0"))
	ellipse(ci, c + Vector2(0, -h * 0.36), Vector2(w * 0.42, h * 0.08), Color("f8f4ea"))
	rrect(ci, Rect2(c + Vector2(-w * 0.4, -h * 0.05), Vector2(w * 0.8, h * 0.3)), Color("2f6f9f"), 4)
	text(ci, c + Vector2(-w * 0.4, h * 0.15), "FARINA", int(h * 0.11), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w * 0.8)
	ci.draw_line(c + Vector2(-w * 0.3, -h * 0.2), c + Vector2(-w * 0.32, h * 0.4), Color(0, 0, 0, 0.08), 3)
	for k in 5:
		ci.draw_circle(c + Vector2(-w * 0.2 + k * w * 0.1, -h * 0.4 - (k % 2) * 4), 2.0, Color(1, 1, 1, 0.8))


## Huevos en un cuenco
static func draw_eggs(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center() + Vector2(0, 8)
	var r := minf(rect.size.x * 0.4, rect.size.y * 0.5)
	for k in 3:
		var p := c + Vector2((k - 1) * r * 0.5, -r * 0.35 - (k % 2) * r * 0.12)
		ellipse(ci, p, Vector2(r * 0.28, r * 0.36), Color("f3e4cc"))
		ellipse(ci, p + Vector2(-r * 0.08, -r * 0.12), Vector2(r * 0.08, r * 0.12), Color(1, 1, 1, 0.5))
	var bowl := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		bowl.append(c + Vector2(cos(a) * r, sin(a) * r * 0.6 - r * 0.1))
	ci.draw_colored_polygon(bowl, Color("6f9fc4"))
	ellipse(ci, c + Vector2(0, -r * 0.1), Vector2(r, r * 0.16), Color("4f7fa4"))
	ellipse(ci, c + Vector2(-r * 0.5, r * 0.15), Vector2(r * 0.15, r * 0.08), Color(1, 1, 1, 0.25))


## Nido de fettuccine fresco (crudo)
static func draw_pasta_nest(ci: CanvasItem, c: Vector2, r: float, seed := 0) -> void:
	ellipse(ci, c + Vector2(3, r * 0.5), Vector2(r * 1.0, r * 0.3), Color(0, 0, 0, 0.18))
	ellipse(ci, c, Vector2(r, r * 0.72), Color("e2c06a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 40 + seed
	for k in 9:
		var rr := r * rng.randf_range(0.35, 0.95)
		var a0 := rng.randf() * TAU
		var pts := PackedVector2Array()
		for i in 12:
			var a := a0 + i * 0.32
			pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 0.7))
		ci.draw_polyline(pts, Color("f6dc8e") if k % 2 == 0 else Color("e9c872"), r * 0.13, true)
	ellipse(ci, c + Vector2(-r * 0.3, -r * 0.3), Vector2(r * 0.25, r * 0.1), Color(1, 1, 1, 0.25))
	for k in 6:
		ci.draw_circle(c + Vector2(rng.randf_range(-r, r) * 0.7, rng.randf_range(-r, r) * 0.5), 1.4, Color(1, 1, 1, 0.8))


## Cuenco con bolitas de masa de maíz
static func draw_masa_bowl(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center() + Vector2(0, 10)
	var r := minf(rect.size.x * 0.42, rect.size.y * 0.5)
	for k in 5:
		var p := c + Vector2((k - 2) * r * 0.32, -r * 0.3 - (k % 2) * r * 0.16)
		ellipse(ci, p, Vector2(r * 0.22, r * 0.18), Color("e2d29c"))
		ellipse(ci, p + Vector2(-r * 0.06, -r * 0.06), Vector2(r * 0.09, r * 0.06), Color(1, 1, 1, 0.35))
	var bowl := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		bowl.append(c + Vector2(cos(a) * r, sin(a) * r * 0.6 - r * 0.1))
	ci.draw_colored_polygon(bowl, Color("c0602a"))
	ellipse(ci, c + Vector2(0, -r * 0.1), Vector2(r, r * 0.16), Color("9a4a1e"))
	for k in 3:
		ci.draw_arc(c + Vector2(0, r * 0.05), r * (0.55 + k * 0.12), 0.3, PI - 0.3, 12, Color("f2d27a"), 2.0)


## Pizza vista desde arriba. pz = {stretch, sauce, sprinkles}. ta/tb = cocción de cada mitad (-1 = cruda).
## La mitad "a" (izquierda) es la que mira al fuego. rot = cuánto se giró (para dibujar los ingredientes).
static func draw_pizza(ci: CanvasItem, rect: Rect2, pz: Dictionary, ta := -1.0, tb := -1.0, target := 9.0, burn := 15.0, rot := 0.0) -> void:
	var c := rect.get_center()
	var stretch: float = pz.get("stretch", 1.0)
	var r := minf(rect.size.x, rect.size.y) * 0.48 * (0.45 + 0.55 * stretch)
	ci.draw_circle(c + Vector2(2, 4), r, Color(0, 0, 0, 0.22))
	if stretch < 1.0 and ta < 0.0:
		# Todavía es un bollo que se va estirando
		ellipse(ci, c, Vector2(r, r * (0.95 - 0.05 * stretch)), Color("ead7aa"))
		ellipse(ci, c + Vector2(-r * 0.2, -r * 0.25), Vector2(r * 0.5, r * 0.3), Color(1, 1, 1, 0.25))
		return
	# Cada mitad se dora según su cocción
	for half in 2:
		var tt := ta if half == 0 else tb
		var col := _crust_color(tt, target, burn)
		var pts := PackedVector2Array([c])
		for k in 25:
			var a := PI * 0.5 + PI * k / 24.0 + (PI if half == 1 else 0.0)
			pts.append(c + Vector2.from_angle(a) * r)
		ci.draw_colored_polygon(pts, col)
	ci.draw_circle(c, r * 0.84, _crust_color(minf(ta, tb), target, burn).lerp(Color("f6e7c4"), 0.4))
	var sauce: String = pz.get("sauce", "")
	if sauce != "":
		var sc: Color = SAUCE_COLORS.get(sauce, Color.WHITE)
		ci.draw_circle(c, r * 0.8, sc.darkened(0.08))
		ci.draw_circle(c, r * 0.76, sc)
	# Ingredientes (giran con la pizza)
	var sp: Dictionary = pz.get("sprinkles", {})
	if not sp.is_empty():
		# Se giran los puntos (no el lienzo: cada pieza usa su propia transformación)
		var turned := {}
		for name in sp:
			var pts := []
			for q in sp[name]["pts"]:
				pts.append((q as Vector2).rotated(rot))
			turned[name] = {"amount": sp[name]["amount"], "pts": pts}
		draw_sprinkles(ci, c, r * 0.72, turned)
	# Manchitas tostadas en el borde y gratinado cuando se cocina
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for half in 2:
		var tt := ta if half == 0 else tb
		if tt <= target * 0.6:
			continue
		var amount := clampf((tt - target * 0.6) / (target * 0.6), 0.0, 1.0)
		for k in int(14 * amount):
			var a := PI * 0.5 + rng.randf() * PI + (PI if half == 1 else 0.0)
			ci.draw_circle(c + Vector2.from_angle(a) * r * rng.randf_range(0.86, 0.97), rng.randf_range(1.5, 3.2), Color(0.25, 0.14, 0.06, 0.55))
		if "Mozzarella" in sp:
			for k in int(10 * amount):
				var a := PI * 0.5 + rng.randf() * PI + (PI if half == 1 else 0.0)
				ci.draw_circle(c + Vector2.from_angle(a) * r * rng.randf_range(0.1, 0.7), rng.randf_range(1.5, 3.5), Color(0.85, 0.55, 0.2, 0.45))
	ci.draw_arc(c, r, 0, TAU, 40, Color(0.5, 0.3, 0.1, 0.4), 1.5)


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
static func draw_logo(ci: CanvasItem, c: Vector2, s: float, time: float, steam := true) -> void:
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
	# Vapor que sale del plato (el ícono va sin vapor: sobre fondo transparente se ve gris)
	for k in (3 if steam else 0):
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


# =====================================================================
# Lavado: utensilios, pileta, esponja y escurridor
# =====================================================================

## Un utensilio. dirt (0-1) = cuánta mugre tiene; foam (0-1) = espuma; shine = recién lavado.
static func draw_tool(ci: CanvasItem, rect: Rect2, kind: String, dirt := 0.0, foam := 0.0, shine := false, seed := 1) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y)
	match kind:
		"plato":
			draw_tex(ci, tex("kitchen/plate"), rect)
		"olla":
			draw_tex(ci, tex("kitchen/pot"), rect)
		"tabla":
			draw_tex(ci, tex("kitchen/board"), rect.grow(-s * 0.05))
		"espatula":
			ci.draw_set_transform(c, -0.6, Vector2.ONE)
			rrect(ci, Rect2(Vector2(-s * 0.06, s * 0.02), Vector2(s * 0.12, s * 0.45)), Color("5a3a22"), 4)
			rrect(ci, Rect2(Vector2(-s * 0.18, -s * 0.42), Vector2(s * 0.36, s * 0.42)), Color("c5ccd2"), 5, Color("8d98a3"), 2)
			for k in 3:
				ci.draw_line(Vector2(-s * 0.1 + k * s * 0.1, -s * 0.36), Vector2(-s * 0.1 + k * s * 0.1, -s * 0.06), Color("8d98a3"), 2)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"canasto":
			var b := Rect2(c - Vector2(s * 0.36, s * 0.28), Vector2(s * 0.72, s * 0.56))
			for k in 7:
				ci.draw_line(Vector2(b.position.x + k * b.size.x / 6.0, b.position.y), Vector2(b.position.x + k * b.size.x / 6.0, b.end.y), Color("6b737b"), 1.5)
			for k in 6:
				ci.draw_line(Vector2(b.position.x, b.position.y + k * b.size.y / 5.0), Vector2(b.end.x, b.position.y + k * b.size.y / 5.0), Color("6b737b"), 1.5)
			ci.draw_rect(b, Color("4a5056"), false, 3)
			ci.draw_line(Vector2(b.end.x, c.y), Vector2(rect.end.x, c.y - s * 0.1), Color("2b2d31"), 5)
		"bandeja":
			rrect(ci, Rect2(c - Vector2(s * 0.42, s * 0.28), Vector2(s * 0.84, s * 0.56)), Color("8d98a3"), 5, Color("6b737b"), 2)
			rrect(ci, Rect2(c - Vector2(s * 0.36, s * 0.22), Vector2(s * 0.72, s * 0.44)), Color("aab3ba"), 4)
		"pala":
			ci.draw_set_transform(c, -0.7, Vector2.ONE)
			rrect(ci, Rect2(Vector2(-s * 0.05, 0), Vector2(s * 0.1, s * 0.48)), Color("8a5a34"), 3)
			ci.draw_circle(Vector2(0, -s * 0.18), s * 0.28, Color("d9a86a"))
			ci.draw_arc(Vector2(0, -s * 0.18), s * 0.28, 0, TAU, 24, Color("a87a44"), 2)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Mugre: manchas de grasa y restos de comida
	if dirt > 0.02:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed * 17 + kind.hash()
		for k in int(14 * dirt) + 2:
			var p := c + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.25, 0.25)) * s
			var col: Color = [Color(0.45, 0.28, 0.12), Color(0.7, 0.25, 0.12), Color(0.55, 0.45, 0.2)][k % 3]
			ellipse(ci, p, Vector2(rng.randf_range(3, 9), rng.randf_range(2, 6)) * s / 80.0, Color(col, 0.55 * dirt + 0.15))
	if foam > 0.02:
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = seed
		for k in int(26 * foam):
			var p := c + Vector2(rng2.randf_range(-0.34, 0.34), rng2.randf_range(-0.28, 0.28)) * s
			ci.draw_circle(p, rng2.randf_range(3, 7) * s / 90.0, Color(1, 1, 1, 0.85))
			ci.draw_arc(p, rng2.randf_range(3, 7) * s / 90.0, 0, TAU, 10, Color(0.75, 0.85, 0.95, 0.8), 1.0)
	if shine:
		var t := Time.get_ticks_msec() / 1000.0
		for k in 3:
			var p := c + Vector2.from_angle(k * 2.1 + t) * s * 0.25
			var r := s * 0.05 * (0.6 + 0.4 * sin(t * 4.0 + k))
			ci.draw_line(p - Vector2(r, 0), p + Vector2(r, 0), Color(1, 1, 1, 0.9), 2)
			ci.draw_line(p - Vector2(0, r), p + Vector2(0, r), Color(1, 1, 1, 0.9), 2)


## Esponja. soap (0-1) = cuánto detergente tiene (se ve la espuma encima); squash = aplastada al frotar.
static func draw_sponge(ci: CanvasItem, rect: Rect2, tilt := 0.0, soap := 0.0, squash := 0.0) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y * 2.2)
	ci.draw_set_transform(c, tilt, Vector2(1.0 + squash * 0.08, 1.0 - squash * 0.18))
	rrect(ci, Rect2(Vector2(-s * 0.36, -s * 0.18), Vector2(s * 0.72, s * 0.24)), Color("f2d24a"), 6, Color("c9a81e"), 2)
	rrect(ci, Rect2(Vector2(-s * 0.36, s * 0.04), Vector2(s * 0.72, s * 0.14)), Color("3f9a48"), 4)
	for k in 6:
		ci.draw_circle(Vector2(-s * 0.26 + k * s * 0.1, -s * 0.06 + (k % 2) * 4), 2, Color("d9b632"))
	if soap > 0.02:
		for k in int(3 + soap * 7):
			var p := Vector2(-s * 0.3 + fmod(k * 0.37, 1.0) * s * 0.6, -s * 0.2 - fmod(k * 0.53, 1.0) * s * 0.08)
			var r := s * (0.03 + 0.03 * fmod(k * 0.71, 1.0))
			ci.draw_circle(p, r, Color(1, 1, 1, 0.9))
			ci.draw_arc(p, r, 0, TAU, 10, Color(0.7, 0.82, 0.95, 0.8), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Botella de detergente (verde, con tapita)
static func draw_detergent(ci: CanvasItem, rect: Rect2, level := 1.0) -> void:
	var c := rect.get_center()
	var h := rect.size.y * 0.86
	var w := minf(rect.size.x * 0.5, h * 0.42)
	var body := Rect2(c.x - w / 2.0, c.y - h * 0.32, w, h * 0.78)
	ellipse(ci, Vector2(c.x + 3, body.end.y + 2), Vector2(w * 0.6, 5), Color(0, 0, 0, 0.2))
	rrect(ci, body, Color("3fae5a"), 10, Color("2a7d3e"), 2)
	# Líquido que se ve a través del plástico
	var lv := Rect2(body.position.x + 4, body.end.y - 4 - (body.size.y - 8) * level, body.size.x - 8, (body.size.y - 8) * level)
	rrect(ci, lv, Color(0.55, 0.9, 0.45, 0.5), 7)
	rrect(ci, Rect2(body.position.x + 6, body.position.y + h * 0.18, body.size.x - 12, h * 0.22), Color("f6f1e0"), 4)
	text(ci, Vector2(body.position.x, body.position.y + h * 0.33), "LIMÓN", int(maxf(8.0, w * 0.2)), Color("2a7d3e"), HORIZONTAL_ALIGNMENT_CENTER, body.size.x)
	rrect(ci, Rect2(c.x - w * 0.22, body.position.y - h * 0.1, w * 0.44, h * 0.11), Color("2a7d3e"), 3)
	rrect(ci, Rect2(c.x - w * 0.09, body.position.y - h * 0.2, w * 0.18, h * 0.11), Color("e8e2d0"), 2)
	ci.draw_line(Vector2(body.position.x + 6, body.position.y + 8), Vector2(body.position.x + 6, body.end.y - 10), Color(1, 1, 1, 0.35), 3)


## Genera manchas de mugre sobre un utensilio. Cada una: o (centro en unidades de s), r, hp (1 = sucia), col, sub.
static func make_dirt(kind: String, rng: RandomNumberGenerator) -> Array:
	var out := []
	var n := rng.randi_range(6, 9)
	for k in n:
		var o := Vector2.ZERO
		match kind:
			"espatula":
				o = Vector2(rng.randf_range(-0.13, 0.13), rng.randf_range(-0.36, -0.08)).rotated(-0.6)
			"pala":
				o = (Vector2(0, -0.18) + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.2).rotated(-0.7)
			"tabla":
				o = Vector2(rng.randf_range(-0.34, 0.34), rng.randf_range(-0.2, 0.2))
			"bandeja":
				o = Vector2(rng.randf_range(-0.32, 0.32), rng.randf_range(-0.18, 0.18))
			"canasto":
				o = Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.22, 0.22))
			_:
				o = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.3
		var cols := [Color(0.45, 0.28, 0.12), Color(0.72, 0.26, 0.12), Color(0.6, 0.5, 0.2), Color(0.35, 0.25, 0.15)]
		var sub := []
		for j in 3:
			sub.append([Vector2.from_angle(rng.randf() * TAU) * rng.randf() * 0.6, rng.randf_range(0.5, 1.0), rng.randf() * PI])
		out.append({"o": o, "r": rng.randf_range(0.06, 0.1), "hp": 1.0, "col": cols[rng.randi() % cols.size()], "sub": sub})
	return out


## Dibuja las manchas: a medida que se friegan se achican y se aclaran.
static func draw_dirt_spots(ci: CanvasItem, rect: Rect2, spots: Array) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y)
	for sp in spots:
		var hp: float = sp["hp"]
		if hp <= 0.0:
			continue
		var center: Vector2 = c + sp["o"] * s
		var r: float = sp["r"] * s * (0.45 + 0.55 * hp)
		var col: Color = sp["col"]
		# Aureola de grasa
		ellipse(ci, center, Vector2(r * 1.5, r * 1.15), Color(0.8, 0.65, 0.3, 0.12 * hp))
		for sb in sp["sub"]:
			var p: Vector2 = center + sb[0] * r
			ci.draw_set_transform(p, sb[2], Vector2.ONE)
			ellipse(ci, Vector2.ZERO, Vector2(r * sb[1], r * sb[1] * 0.62), Color(col, 0.25 + 0.6 * hp))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if hp > 0.5:
			ci.draw_circle(center + Vector2(-r * 0.3, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.25))


## Burbujas de detergente. Cada una: o (unidades de s), r (px), life (0-1).
static func draw_bubbles(ci: CanvasItem, rect: Rect2, bubbles: Array) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y)
	for b in bubbles:
		var p: Vector2 = c + b["o"] * s
		var a := clampf(b["life"] * 2.0, 0.0, 1.0)
		var r: float = b["r"] * (0.6 + 0.4 * a)
		ci.draw_circle(p, r, Color(1, 1, 1, 0.75 * a))
		ci.draw_arc(p, r, 0, TAU, 12, Color(0.66, 0.8, 0.95, 0.9 * a), 1.0)
		ci.draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, a))


## Pila de platos limpios con el número (en rojo cuando quedan pocos)
static func draw_plate_stack(ci: CanvasItem, rect: Rect2, n: int) -> void:
	var cx := rect.get_center().x
	var base := rect.end.y - 30
	ellipse(ci, Vector2(cx + 3, base + 6), Vector2(rect.size.x * 0.44, 7), Color(0, 0, 0, 0.18))
	for k in mini(n, 8):
		var y := base - k * 6.0
		ellipse(ci, Vector2(cx, y + 2), Vector2(rect.size.x * 0.42, 8), Color("b9c0c5"))
		ellipse(ci, Vector2(cx, y), Vector2(rect.size.x * 0.42, 8), Color("f7f7f4"))
		ellipse(ci, Vector2(cx, y), Vector2(rect.size.x * 0.26, 4.5), Color("e6e8e6"))
	if n == 0:
		ci.draw_arc(Vector2(cx, base - 4), 14, 0, TAU, 20, Color("c0281a"), 3)
		ci.draw_line(Vector2(cx - 10, base + 6), Vector2(cx + 10, base - 14), Color("c0281a"), 3)
	var col := Color("c0281a") if n <= 2 else Color("3b2a1e")
	text(ci, Vector2(rect.position.x - 20, rect.end.y - 4), "Platos limpios: %d" % n, 13, col, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 40, 4, Color(1, 1, 1, 0.85))


## Plato parado de canto en el escurridor
static func draw_plate_edge(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	ellipse(ci, c, Vector2(rect.size.x * 0.16, rect.size.y * 0.48), Color("d9dde0"))
	ellipse(ci, c + Vector2(rect.size.x * 0.03, 0), Vector2(rect.size.x * 0.1, rect.size.y * 0.4), Color("f7f7f4"))
	ci.draw_line(c + Vector2(-rect.size.x * 0.05, -rect.size.y * 0.3), c + Vector2(-rect.size.x * 0.05, rect.size.y * 0.1), Color(1, 1, 1, 0.9), 2)


## Pileta con grifo. water = si sale agua.
## Dónde cae el chorro del grifo (x en coordenadas de rect) y desde qué altura sale.
static func sink_stream(rect: Rect2) -> Vector2:
	var basin_y := rect.position.y + rect.size.y * 0.25
	return Vector2(rect.get_center().x + 52, basin_y + 6 - rect.size.y * 0.2 + 22)


## Pileta de acero con grifo monocomando.
## flow (0-1) = cuánta agua sale; pool (0-1) = agua acumulada en el fondo; soapy = el agua tiene espuma.
## hit_y = a qué altura choca el chorro (algo apoyado en la pileta); -1 = el fondo.
static func draw_sink(ci: CanvasItem, rect: Rect2, flow: float, time: float, pool := 0.0, soapy := false) -> void:
	var basin := Rect2(rect.position + Vector2(0, rect.size.y * 0.25), Vector2(rect.size.x, rect.size.y * 0.75))
	rrect(ci, Rect2(basin.position + Vector2(4, 8), basin.size), Color(0, 0, 0, 0.3), 18)
	rrect(ci, basin, Color("c5ccd2"), 18, Color("8d98a3"), 4)
	rrect(ci, basin.grow(-16), Color("8d98a3"), 14)
	var inner := basin.grow(-22)
	grad_rect(ci, inner, Color("aab3ba"), Color("7d8790"))
	# Acero cepillado: vetas finas y un reflejo
	for k in 18:
		var y := inner.position.y + 6 + k * (inner.size.y - 12) / 17.0
		ci.draw_line(Vector2(inner.position.x + 8, y), Vector2(inner.end.x - 8, y), Color(1, 1, 1, 0.04), 1)
	ci.draw_line(inner.position + Vector2(14, 10), Vector2(inner.position.x + 14, inner.end.y - 12), Color(1, 1, 1, 0.18), 4)
	var drain := basin.get_center() + Vector2(0, basin.size.y * 0.28)
	ci.draw_circle(drain, 11, Color("5b6168"))
	ci.draw_circle(drain, 8, Color("2b2d31"))
	for k in 4:
		ci.draw_line(drain + Vector2.from_angle(k * PI / 4) * 7, drain - Vector2.from_angle(k * PI / 4) * 7, Color("7d8790"), 1.5)
	# Agua acumulada en el fondo (se va por la rejilla cuando se cierra el grifo)
	if pool > 0.01:
		var h := inner.size.y * 0.42 * pool
		var wr := Rect2(inner.position.x, inner.end.y - h, inner.size.x, h)
		rrect(ci, wr, Color(0.62, 0.78, 0.9, 0.35), 10)
		var surf := PackedVector2Array()
		for k in 25:
			var x := wr.position.x + 6 + k * (wr.size.x - 12) / 24.0
			surf.append(Vector2(x, wr.position.y + sin(time * 3.0 + k * 0.7) * 1.5))
		ci.draw_polyline(surf, Color(1, 1, 1, 0.45), 2.0, true)
		if soapy:
			for k in 16:
				var x := wr.position.x + 14 + fmod(k * 0.618, 1.0) * (wr.size.x - 28)
				ci.draw_circle(Vector2(x, wr.position.y + sin(time * 2.0 + k) * 1.5), 3 + (k % 3) * 2, Color(1, 1, 1, 0.7))
	# Grifo cuello de cisne
	var base := Vector2(rect.get_center().x, basin.position.y + 6)
	rrect(ci, Rect2(base + Vector2(-18, -10), Vector2(36, 16)), Color("aab3ba"), 6, Color("7d8790"), 2)
	ci.draw_line(base + Vector2(0, -6), base + Vector2(0, -rect.size.y * 0.2), Color("c5ccd2"), 12)
	ci.draw_arc(base + Vector2(26, -rect.size.y * 0.2), 26, PI, PI * 2.0, 16, Color("c5ccd2"), 12)
	ci.draw_line(base + Vector2(52, -rect.size.y * 0.2), base + Vector2(52, -rect.size.y * 0.2 + 18), Color("c5ccd2"), 12)
	ci.draw_arc(base + Vector2(26, -rect.size.y * 0.2), 26, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.6), 3)
	ci.draw_line(base + Vector2(-3, -10), base + Vector2(-3, -rect.size.y * 0.2 + 4), Color(1, 1, 1, 0.5), 2)
	# Monocomando: palanca que se levanta para abrir
	var piv := base + Vector2(-40, -14)
	rrect(ci, Rect2(piv + Vector2(-13, -2), Vector2(26, 16)), Color("aab3ba"), 5, Color("7d8790"), 2)
	ci.draw_circle(piv, 9, Color("c5ccd2"))
	var ang := lerpf(-0.15, -1.05, flow)
	var tip := piv + Vector2.from_angle(PI + ang) * 30
	ci.draw_line(piv, tip, Color("8d98a3"), 9)
	ci.draw_line(piv, tip, Color("dfe4e8"), 5)
	ci.draw_circle(tip, 5, Color("dfe4e8"))
	ci.draw_circle(piv + Vector2(-7, 9), 2.5, Color("c8463c"))
	ci.draw_circle(piv + Vector2(7, 9), 2.5, Color("3a7fd0"))


## Escurridor de platos (alambre)
static func draw_rack(ci: CanvasItem, rect: Rect2) -> void:
	rrect(ci, Rect2(rect.position + Vector2(3, 6), rect.size), Color(0, 0, 0, 0.2), 10)
	rrect(ci, Rect2(rect.position + Vector2(0, rect.size.y - 18), Vector2(rect.size.x, 18)), Color("9aa3ab"), 6)
	for k in 9:
		var x := rect.position.x + 10 + k * (rect.size.x - 20) / 8.0
		ci.draw_line(Vector2(x, rect.position.y + 20), Vector2(x, rect.end.y - 14), Color("8d98a3"), 3)
	ci.draw_line(Vector2(rect.position.x + 6, rect.position.y + 20), Vector2(rect.end.x - 6, rect.position.y + 20), Color("8d98a3"), 3)


# =====================================================================
# Salón italiano (Trattoria del Forno)
# =====================================================================

static func draw_dining_italia(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array) -> void:
	var o := rect.position
	# Pared de estuco ocre con manchas, vigas de madera y zócalo de terracota
	grad_rect(ci, rect, Color("eabf86"), Color("d69e62"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for k in 40:
		ellipse(ci, o + Vector2(rng.randf() * rect.size.x, rng.randf() * 220), Vector2(rng.randf_range(20, 60), rng.randf_range(10, 30)),
			Color(1, 1, 1, 0.05) if k % 2 == 0 else Color(0.5, 0.25, 0.1, 0.05))
	ci.draw_rect(Rect2(o, Vector2(rect.size.x, 14)), Color("5a3a22"))
	for x in range(40, int(rect.size.x), 220):
		ci.draw_rect(Rect2(o + Vector2(x, 0), Vector2(26, 22)), Color("4a2e1a"))
	tiles(ci, Rect2(o.x, o.y + 225, rect.size.x, rect.size.y - 225), Vector2(46, 46), Color("c0643a"), Color("8a3e22"), false)
	ci.draw_rect(Rect2(o.x, o.y + 220, rect.size.x, 8), Color("7a4a24"))
	# Puerta de madera con remaches y cartel APERTO
	var d := Rect2(o.x + 30, o.y + 40, 150, 290)
	var arch := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		arch.append(Vector2(d.get_center().x, d.position.y + 60) + Vector2(cos(a) * 75, sin(a) * 50))
	arch.append(Vector2(d.end.x, d.end.y))
	arch.append(Vector2(d.position.x, d.end.y))
	ci.draw_colored_polygon(arch, Color("6e4527"))
	for k in 5:
		ci.draw_line(Vector2(d.position.x + 10 + k * 32, d.position.y + 20), Vector2(d.position.x + 10 + k * 32, d.end.y), Color("5a3a22"), 2)
	for k in 4:
		for j in 3:
			ci.draw_circle(Vector2(d.position.x + 28 + j * 48, d.position.y + 90 + k * 52), 3, Color("3a3a3a"))
	ci.draw_circle(d.position + Vector2(128, 170), 6, Color("e3c26a"))
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("2f6f4f"), 6, Color("e8e0c8"), 2)
	text(ci, d.position + Vector2(28, 85), "APERTO", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, 94)
	# Ventana en arco con persianas verdes y Roma al atardecer
	var w := Rect2(o.x + 330, o.y + 50, 420, 160)
	var wpts := PackedVector2Array()
	for k in 21:
		var a := PI + PI * k / 20.0
		wpts.append(Vector2(w.get_center().x, w.position.y + 60) + Vector2(cos(a) * w.size.x / 2.0, sin(a) * 60))
	wpts.append(w.end)
	wpts.append(Vector2(w.position.x, w.end.y))
	for side in [-1, 1]:
		var sx: float = w.position.x - 70 if side < 0 else w.end.x + 6
		ci.draw_rect(Rect2(sx, w.position.y - 20, 64, w.size.y + 20), Color("3f7a4a"))
		for k in 9:
			ci.draw_line(Vector2(sx + 4, w.position.y - 14 + k * 18), Vector2(sx + 60, w.position.y - 14 + k * 18), Color("2f5a38"), 3)
	var big := PackedVector2Array()
	for p in wpts:
		big.append(w.get_center() + (p - w.get_center()) * 1.06)
	ci.draw_colored_polygon(big, Color("6e4527"))
	ci.draw_colored_polygon(wpts, Color("f6b26b"))
	ci.draw_circle(w.position + Vector2(300, 70), 26, Color(1, 0.92, 0.6, 0.9))
	# Silueta de Roma: Coliseo, cúpula y cipreses
	var ground := w.end.y
	ci.draw_colored_polygon(PackedVector2Array([Vector2(w.position.x + 230, w.position.y + 74), Vector2(w.position.x + 300, w.position.y + 90),
		Vector2(w.position.x + 370, w.position.y + 74), Vector2(w.position.x + 370, ground), Vector2(w.position.x + 230, ground)]), Color("e09a5a"))
	ci.draw_circle(Vector2(w.position.x + 300, w.position.y + 78), 30, Color("e09a5a"))
	var col_x := w.position.x + 40
	ci.draw_rect(Rect2(col_x, w.position.y + 90, 170, ground - w.position.y - 90), Color("d08848"))
	for row in 3:
		for k in 8:
			var ax := col_x + 8 + k * 20.0
			var ay := w.position.y + 100 + row * 22.0
			ci.draw_rect(Rect2(ax, ay + 6, 12, 14), Color("8a4a24"))
			ci.draw_circle(Vector2(ax + 6, ay + 6), 6, Color("8a4a24"))
	for cx in [w.position.x + 222, w.position.x + 390, w.position.x + 405]:
		ellipse(ci, Vector2(cx, ground - 34), Vector2(8, 34), Color("3f5a2a"))
	ci.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("6e4527"), 6)
	# Estante con botellas de vino (con canasto de paja)
	var sh := Rect2(o.x + 790, o.y + 150, 80, 8)
	ci.draw_rect(sh, Color("5a3a22"))
	for k in 3:
		var bx := sh.position.x + 14 + k * 26
		ellipse(ci, Vector2(bx, sh.position.y - 12), Vector2(11, 13), Color("d9b36a"))
		for j in 4:
			ci.draw_line(Vector2(bx - 10, sh.position.y - 18 + j * 4), Vector2(bx + 10, sh.position.y - 18 + j * 4), Color("b08a42"), 1)
		ci.draw_rect(Rect2(bx - 3, sh.position.y - 44, 6, 22), Color("3a5a2a"))
		ci.draw_rect(Rect2(bx - 3, sh.position.y - 48, 6, 5), Color("8a2018"))
	# Ristras de ajo y ají colgando
	for x in [205.0, 1245.0]:
		ci.draw_line(o + Vector2(x, 14), o + Vector2(x, 120), Color("8a6a3a"), 2)
		for k in 6:
			var p := o + Vector2(x + (6 if k % 2 == 0 else -6), 30 + k * 16)
			if x < 600:
				ci.draw_circle(p, 8, Color("f6efe0"))
				ci.draw_line(p + Vector2(0, -8), p + Vector2(0, -12), Color("d9cdb4"), 2)
			else:
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -6), p + Vector2(4, -6), p + Vector2(0, 12)]), Color("c8281e"))
				ci.draw_line(p + Vector2(0, -6), p + Vector2(0, -10), Color("3f7a28"), 2)
	# Banderines de Italia entre las lámparas
	for k in 30:
		var x := o.x + 230 + k * 34.0
		if x > rect.end.x - 30:
			break
		var y := o.y + 22 + sin(k * 0.6) * 4
		var colf: Color = [Color("009246"), Color("ffffff"), Color("ce2b37")][k % 3]
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 26, y), Vector2(x + 13, y + 22)]), colf)
	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 30, 300, 188)
	ci.draw_rect(b.grow(9), Color("5a3a22"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "MENÚ DEL GIORNO", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	for i in menu.size():
		text(ci, b.position + Vector2(18, 62 + i * 24), "• " + str(menu[i]), 16, Color("e9f0dc"), HORIZONTAL_ALIGNMENT_LEFT, 270)
	for x in [260, 640, 1220]:
		lamp(ci, o.x + x, o.y + 14, 4, time)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(840, 14), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(450, 14), time)


## Frente del mostrador italiano: azulejos de mayólica
static func draw_counter_italia(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	var front := Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18)
	ci.draw_rect(front, Color("e9e2d0"))
	var size := 52.0
	for row in int(front.size.y / size) + 1:
		for col in int(front.size.x / size) + 1:
			var p := front.position + Vector2(col * size, row * size)
			var tr := Rect2(p + Vector2(2, 2), Vector2(size - 4, size - 4)).intersection(front)
			if tr.size.x <= 0 or tr.size.y <= 0:
				continue
			ci.draw_rect(tr, Color("f7f2e4"))
			var c := p + Vector2(size, size) / 2.0
			if front.has_point(c):
				ci.draw_circle(c, 14, Color("2f5f9f"))
				ci.draw_circle(c, 9, Color("f7f2e4"))
				ci.draw_circle(c, 4, Color("e3a53a"))
				for k in 4:
					var a := PI / 4.0 + k * PI / 2.0
					ci.draw_circle(c + Vector2.from_angle(a) * 20, 4, Color("2f5f9f"))
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("7a4a24"), Color("5a3a22"))
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.25))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


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


## Sello de la guía gastronómica: dorado con las estrellas ganadas (gris si no hay ninguna)
static func draw_guide_seal(ci: CanvasItem, c: Vector2, r: float, n: int, time := 0.0) -> void:
	var gold := Color("e0b44a") if n > 0 else Color("b9b2a6")
	var dark := gold.darkened(0.35)
	# Cintas que cuelgan
	for side in [-1, 1]:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 0.25, 0.5) * r, c + Vector2(side * 0.75, 1.45) * r,
			c + Vector2(side * 0.5, 1.3) * r, c + Vector2(side * 0.35, 1.5) * r, c + Vector2(side * 0.05, 0.6) * r]),
			Color("c0392b") if n > 0 else Color("8a8a8a"))
	# Borde dentado
	var pts := PackedVector2Array()
	for k in 48:
		var a := TAU * k / 48.0 + time * 0.2
		pts.append(c + Vector2.from_angle(a) * r * (1.0 if k % 2 == 0 else 0.9))
	ci.draw_colored_polygon(pts, gold)
	ci.draw_circle(c, r * 0.78, dark)
	ci.draw_circle(c, r * 0.72, gold.lightened(0.15))
	text(ci, c + Vector2(-r, -r * 0.18), "GUÍA", int(r * 0.34), dark, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
	var sr := r * 0.17
	for k in 3:
		star(ci, c + Vector2((k - 1) * sr * 2.3, r * 0.28), sr, k < n)
	# Brillo que pasa
	if n > 0:
		var g := fmod(time * 0.6, 3.0)
		if g < 1.0:
			ci.draw_line(c + Vector2(-0.8 + g * 1.6, -0.7) * r, c + Vector2(-1.1 + g * 1.6, 0.7) * r, Color(1, 1, 1, 0.35), r * 0.12)


## Lata o botella de bebida
static func draw_drink(ci: CanvasItem, rect: Rect2, name: String, drinks: Dictionary) -> void:
	var d: Dictionary = drinks.get(name, {"color": Color.WHITE, "label": Color.GRAY, "kind": "lata"})
	var c := rect.get_center()
	var h := rect.size.y * 0.94
	var w := minf(rect.size.x * 0.55, h * 0.48)
	if d["kind"] == "vino":
		draw_wine_glass(ci, Rect2(c.x - h * 0.3, c.y - h / 2.0, h * 0.6, h), 1.0, 0.0)
		return
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


# =====================================================================
# Vino: copa de cristal y botella
# =====================================================================

const WINE := Color("6e0f22")
const WINE_IDEAL_U := 0.36      # la parte más ancha de la copa (0 = borde, 1 = fondo del cáliz)
const WINE_RIM_FILL := 1.55     # con este nivel llega al borde y se derrama

## Contorno de una elipse (o un tramo, de a0 a a1)
static func ellipse_arc(ci: CanvasItem, c: Vector2, radii: Vector2, a0: float, a1: float, color: Color, width := 1.0) -> void:
	var pts := PackedVector2Array()
	for k in 33:
		var a := lerpf(a0, a1, k / 32.0)
		pts.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_polyline(pts, color, width, true)


## Medio ancho del cáliz (tulipa) a la altura u (0 = borde, 1 = fondo), en fracción del ancho máximo
static func glass_halfw(u: float) -> float:
	if u <= WINE_IDEAL_U:
		return 0.84 + 0.16 * u / WINE_IDEAL_U          # se cierra un poco hacia el borde
	var v := (u - WINE_IDEAL_U) / (1.0 - WINE_IDEAL_U)
	return sqrt(maxf(0.0, 1.0 - v * v)) * 0.98 + 0.02


## Nivel de vino (fill: 1 = hasta la parte más ancha) -> altura u de la superficie
static func wine_surface_u(fill: float) -> float:
	return clampf(1.0 - fill * (1.0 - WINE_IDEAL_U), 0.0, 1.0)


## Copa de vino de cristal. fill = nivel (1 = lo justo); slosh = cuánto se mueve la superficie;
## spill = vino derramado en el mostrador (0-1); pour_x = si cae un chorro, dónde pega (x en coords de ci; NAN = no)
static func draw_wine_glass(ci: CanvasItem, rect: Rect2, fill: float, time: float, slosh := 0.0, spill := 0.0) -> void:
	var cx := rect.get_center().x
	var top := rect.position.y + rect.size.y * 0.04
	var bowl_h := rect.size.y * 0.5
	var bot := top + bowl_h
	var W := rect.size.x * 0.4
	var foot_y := rect.end.y - rect.size.y * 0.05
	# Sombra y mancha de vino derramado
	ellipse(ci, Vector2(cx + 4, foot_y + 3), Vector2(W * 0.95, 6), Color(0, 0, 0, 0.18))
	if spill > 0.0:
		ellipse(ci, Vector2(cx + W * 0.3, foot_y + 2), Vector2(W * (0.6 + spill * 0.9), 4 + spill * 4), Color(WINE, 0.75))
		ellipse(ci, Vector2(cx + W * 0.1, foot_y + 1), Vector2(W * 0.5 * spill, 2 + spill * 2), Color(1, 0.6, 0.65, 0.25))
	# Pie y tallo
	ellipse(ci, Vector2(cx, foot_y), Vector2(W * 0.82, 7), Color(0.85, 0.92, 0.96, 0.55))
	ellipse_arc(ci, Vector2(cx, foot_y), Vector2(W * 0.82, 7), PI * 0.05, PI * 0.95, Color(1, 1, 1, 0.7), 1.5)
	ci.draw_rect(Rect2(cx - 2.5, bot, 5, foot_y - bot - 3), Color(0.86, 0.93, 0.97, 0.6))
	ci.draw_line(Vector2(cx - 1, bot + 4), Vector2(cx - 1, foot_y - 6), Color(1, 1, 1, 0.8), 1.2)
	ellipse(ci, Vector2(cx, bot + 2), Vector2(6, 4), Color(0.86, 0.93, 0.97, 0.7))
	# Contorno del cáliz
	var n := 24
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for k in n + 1:
		var u := float(k) / n
		var y := top + u * bowl_h
		left.append(Vector2(cx - W * glass_halfw(u), y))
		right.append(Vector2(cx + W * glass_halfw(u), y))
	var outline := PackedVector2Array(left)
	for k in range(n, -1, -1):
		outline.append(right[k])
	ci.draw_colored_polygon(outline, Color(0.8, 0.9, 0.97, 0.14))
	# El vino: desde la superficie hasta el fondo, con la superficie que se mueve
	var su := wine_surface_u(fill)
	if fill > 0.02:
		var wob := sin(time * 9.0) * slosh * 0.05
		var liq := PackedVector2Array()
		var steps := 16
		for k in steps + 1:
			var u := lerpf(su, 1.0, float(k) / steps)
			liq.append(Vector2(cx - maxf(0.0, W * glass_halfw(u) - 1.5), top + u * bowl_h))
		for k in range(steps, -1, -1):
			var u := lerpf(su, 1.0, float(k) / steps)
			liq.append(Vector2(cx + maxf(0.0, W * glass_halfw(u) - 1.5) + 0.01 * k, top + u * bowl_h))
		# la superficie inclinada por el bamboleo
		var sy := top + su * bowl_h
		var hw := W * glass_halfw(su) - 1.5
		liq[0] = Vector2(liq[0].x, sy - wob * hw)
		liq[liq.size() - 1] = Vector2(liq[liq.size() - 1].x, sy + wob * hw)
		ci.draw_colored_polygon(liq, WINE)
		# Más oscuro en el centro y abajo, más claro en el borde (como el vino de verdad)
		var core := PackedVector2Array()
		for p in liq:
			core.append(Vector2(cx + (p.x - cx) * 0.6, p.y + (bot - p.y) * 0.12))
		ci.draw_colored_polygon(core, Color(0.25, 0.0, 0.05, 0.45))
		# Superficie: elipse con el brillo y el borde "ribete" más claro
		var surf_c := Vector2(cx, sy)
		ci.draw_set_transform(surf_c, wob * 0.6, Vector2.ONE)
		ellipse(ci, Vector2.ZERO, Vector2(hw, maxf(2.0, hw * 0.16)), Color("8c1a30"))
		ellipse_arc(ci, Vector2.ZERO, Vector2(hw, maxf(2.0, hw * 0.16)), 0, TAU, Color(0.75, 0.2, 0.3, 0.8), 1.2)
		ellipse(ci, Vector2(-hw * 0.3, -hw * 0.03), Vector2(hw * 0.35, maxf(1.0, hw * 0.05)), Color(1, 0.8, 0.85, 0.35))
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		# "Lágrimas" del vino en el vidrio por encima del nivel
		if fill > 0.3:
			for k in 3:
				var lx := cx - W * 0.5 + k * W * 0.45
				var ly := sy - 6 - k * 3
				ci.draw_line(Vector2(lx, ly - 8), Vector2(lx, ly), Color(WINE, 0.25), 1.5)
	# Brillo del cristal y borde
	var shine := PackedVector2Array()
	for k in range(2, n - 6):
		var u := float(k) / n
		shine.append(Vector2(cx - W * glass_halfw(u) * 0.78, top + u * bowl_h))
	ci.draw_polyline(shine, Color(1, 1, 1, 0.55), 3.0, true)
	ci.draw_polyline(left, Color(0.85, 0.92, 0.97, 0.85), 1.6, true)
	ci.draw_polyline(right, Color(0.7, 0.8, 0.88, 0.85), 1.6, true)
	ellipse(ci, Vector2(cx, top), Vector2(W * glass_halfw(0.0), 3.5), Color(0.9, 0.96, 1.0, 0.35))
	ellipse_arc(ci, Vector2(cx, top), Vector2(W * glass_halfw(0.0), 3.5), 0, TAU, Color(1, 1, 1, 0.8), 1.2)


## Botella de vino tinto. mouth = dónde está el pico; angle = 0 parada, más negativo = más volcada
## (gira alrededor del pico, el cuerpo queda arriba a la derecha al servir).
static func draw_wine_bottle(ci: CanvasItem, mouth: Vector2, s: float, angle: float) -> void:
	ci.draw_set_transform(mouth, angle, Vector2.ONE)
	var glass := Color("1f3a24")
	var len := 150.0 * s
	var bw := 19.0 * s
	# Cápsula (papel de la boca), cuello, hombros y cuerpo, hacia +y
	rrect(ci, Rect2(Vector2(-6.5, 0) * s, Vector2(13, 26) * s), Color("7a1426"), 2 * s)
	ci.draw_line(Vector2(-6.5, 22) * s, Vector2(6.5, 22) * s, Color("c9a54a"), 1.5 * s)
	rrect(ci, Rect2(Vector2(-6, 26) * s, Vector2(12, 26) * s), glass, 2 * s)
	var sh := PackedVector2Array([Vector2(-6, 50) * s, Vector2(6, 50) * s, Vector2(bw, 78 * s), Vector2(-bw, 78 * s)])
	ci.draw_colored_polygon(sh, glass)
	rrect(ci, Rect2(Vector2(-bw, 74 * s), Vector2(bw * 2, len - 74 * s)), glass, 6 * s)
	# Etiqueta
	rrect(ci, Rect2(Vector2(-bw + 2 * s, 92 * s), Vector2(bw * 2 - 4 * s, 38 * s)), Color("efe4c8"), 2 * s)
	ci.draw_rect(Rect2(Vector2(-bw + 2 * s, 96 * s), Vector2(bw * 2 - 4 * s, 3 * s)), Color("7a1426"))
	ci.draw_set_transform(mouth + Vector2(0, 112 * s).rotated(angle), angle, Vector2.ONE)
	text(ci, Vector2(-bw, 4 * s), "MALBEC", int(9 * s), Color("4a1018"), HORIZONTAL_ALIGNMENT_CENTER, bw * 2)
	ci.draw_set_transform(mouth, angle, Vector2.ONE)
	ellipse(ci, Vector2(0, 124 * s), Vector2(5 * s, 4 * s), Color("c9a54a"))
	# Brillos del vidrio
	ci.draw_line(Vector2(-bw * 0.6, 80 * s), Vector2(-bw * 0.6, len - 8 * s), Color(1, 1, 1, 0.28), 3 * s)
	ci.draw_line(Vector2(-3, 28) * s, Vector2(-3, 48) * s, Color(1, 1, 1, 0.3), 1.5 * s)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


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
static func draw_day_intro(ci: CanvasItem, rect: Rect2, p: float, title: String, subtitle: String, time: float, theme := "argentina") -> void:
	draw_dining(ci, rect, [], time, [], theme)
	draw_counter(ci, rect, rect.size.y - 250, theme)
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
static func draw_dining(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array = [], theme := "argentina") -> void:
	_draw_dining_base(ci, rect, menu, time, decor, theme)
	draw_salon_decor(ci, rect, decor, time)


static func _draw_dining_base(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array = [], theme := "argentina") -> void:
	if theme == "italia":
		draw_dining_italia(ci, rect, menu, time, decor)
		return
	if theme == "mexico":
		draw_dining_mexico(ci, rect, menu, time, decor)
		return
	if theme == "eeuu":
		draw_dining_eeuu(ci, rect, menu, time, decor)
		return
	if theme == "francia":
		draw_dining_francia(ci, rect, menu, time, decor)
		return
	if theme == "india":
		draw_dining_india(ci, rect, menu, time, decor)
		return
	if theme == "japon":
		draw_dining_japon(ci, rect, menu, time, decor)
		return
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
static func draw_counter(ci: CanvasItem, rect: Rect2, top: float, theme := "argentina") -> void:
	if theme == "italia":
		draw_counter_italia(ci, rect, top)
		return
	if theme == "mexico":
		draw_counter_mexico(ci, rect, top)
		return
	if theme == "eeuu":
		draw_counter_eeuu(ci, rect, top)
		return
	if theme == "francia":
		draw_counter_francia(ci, rect, top)
		return
	if theme == "india":
		draw_counter_india(ci, rect, top)
		return
	if theme == "japon":
		draw_counter_japon(ci, rect, top)
		return
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


## El crítico de la guía, de incógnito: sombrero, anteojos oscuros y una libreta donde anota todo
static func critic_look(rng: RandomNumberGenerator) -> Dictionary:
	return {"skin": SKINS[rng.randi() % SKINS.size()], "hair": HAIRS[rng.randi() % 3], "style": 0,
		"shirt": Color("6b5644"), "cap": Color("3b3430"), "hat": "fedora", "acc": 5, "w": 1.0,
		"seed": rng.randi() % 1000, "notepad": true, "writing": true, "critic": true}


## Dibuja un personaje (torso y cabeza). `pos` es el punto de abajo al centro.
## mood: 0 contento, 1 normal, 2 molesto, 3 enojado.
static func draw_character(ci: CanvasItem, look: Dictionary, pos: Vector2, s: float, mood: int, time: float,
		head_only := false, bob := 0.0) -> void:
	var sd: int = look.get("seed", 0)
	var breathe := sin(time * 2.2 + sd) * 1.2
	var w: float = look.get("w", 1.0)
	var fem: bool = look.get("fem", false)
	if fem:
		w *= 0.93       # hombros un poco más finos
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
		if style == 7 or look.get("jacket", false):
			# Chaqueta de cocinero cruzada, con dos filas de botones y pañuelo al cuello
			var btn: Color = shirt.darkened(0.25) if shirt.v > 0.6 else shirt.lightened(0.35)
			for k in 3:
				for side in [-1, 1]:
					ci.draw_circle(Vector2(pos.x + side * 12 * s, top + (24 + k * 18) * s), 3 * s, btn)
			var scarf = look.get("scarf", Color("d9534a"))
			if scarf != null:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 14 * s, top), Vector2(pos.x + 14 * s, top),
					Vector2(pos.x, top + 12 * s)]), scarf)
		else:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 11 * s, top), Vector2(pos.x + 11 * s, top),
				Vector2(pos.x, top + 16 * s)]), skin.darkened(0.08))
		ci.draw_rect(Rect2(hc.x - 9 * s, hc.y + 20 * s, 18 * s, top - hc.y - 18 * s), skin.darkened(0.12))
		ellipse(ci, hc + Vector2(0, 28) * s, Vector2(13, 5) * s, Color(skin.darkened(0.35), 0.6))   # sombra del mentón
		if look.get("apron", false):
			# Delantal con tiras al cuello y bolsillo
			var ap: Color = look.get("apron_color", Color("f4efe2"))
			rrect(ci, Rect2(pos.x - 26 * s, top + 22 * s, 52 * s, pos.y - top), ap, 8 * s)
			ci.draw_line(Vector2(pos.x - 20 * s, top + 24 * s), Vector2(pos.x - 8 * s, top + 2 * s), ap, 3 * s)
			ci.draw_line(Vector2(pos.x + 20 * s, top + 24 * s), Vector2(pos.x + 8 * s, top + 2 * s), ap, 3 * s)
			rrect(ci, Rect2(pos.x - 12 * s, top + 52 * s, 24 * s, 14 * s), ap.darkened(0.1), 3 * s)
			if not look.get("jacket", false):
				rrect(ci, Rect2(pos.x + 14 * s, top + 8 * s, 18 * s, 7 * s), Color("d9a520"), 2 * s)   # identificación
		if look.get("notepad", false):
			_draw_notepad(ci, pos, top, s, time, look.get("writing", false))

	# Pelo largo (atrás de la cabeza)
	if style == 1:
		rrect(ci, Rect2(hc.x - 35 * s, hc.y - 20 * s, 70 * s, 66 * s), hair, 28 * s)
	elif style == 8:
		# Melena: hasta el mentón, recta
		rrect(ci, Rect2(hc.x - 36 * s, hc.y - 22 * s, 72 * s, 50 * s), hair, 20 * s)
	elif style == 9:
		# Cola de caballo que asoma por atrás, hacia un costado
		var tail := PackedVector2Array([hc + Vector2(20, -24) * s, hc + Vector2(46, -16) * s, hc + Vector2(52, 14) * s,
			hc + Vector2(44, 40) * s, hc + Vector2(36, 18) * s, hc + Vector2(30, -6) * s])
		ci.draw_colored_polygon(tail, hair)
		ci.draw_line(hc + Vector2(42, -8) * s, hc + Vector2(46, 26) * s, Color(hair.lightened(0.3), 0.5), 2 * s)

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
	# Pestañas (perfil femenino)
	if fem and not blink:
		for side in [-1, 1]:
			var e: Vector2 = hc + Vector2(side * 11, 0) * s
			ci.draw_line(e + Vector2(side * 3, -3) * s, e + Vector2(side * 7, -6) * s, INK, 1.6 * s)
			ci.draw_line(e + Vector2(side * 1, -4) * s, e + Vector2(side * 3, -8) * s, INK, 1.4 * s)
	var lip: Color = Color("c2455a") if fem else INK
	var mouth := hc + Vector2(0, 16) * s
	match mood:
		0:
			ci.draw_arc(mouth + Vector2(0, -4) * s, 9 * s, 0.15 * PI, 0.85 * PI, 14, lip, (3.2 if fem else 2.6) * s)
			ci.draw_circle(hc + Vector2(-19, 10) * s, 5 * s, Color(1, 0.45, 0.45, 0.35))
			ci.draw_circle(hc + Vector2(19, 10) * s, 5 * s, Color(1, 0.45, 0.45, 0.35))
		1:
			ci.draw_line(mouth + Vector2(-7, 0) * s, mouth + Vector2(7, 0) * s, lip, (3.2 if fem else 2.6) * s)
		_:
			ci.draw_arc(mouth + Vector2(0, 8) * s, 9 * s, 1.15 * PI, 1.85 * PI, 14, lip, (3.2 if fem else 2.6) * s)

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
		5:
			# Anteojos oscuros
			for side in [-1, 1]:
				rrect(ci, Rect2(hc + Vector2(side * 11 - 9, -6) * s, Vector2(18, 12) * s), Color("16181c"), 4 * s)
				ci.draw_line(hc + Vector2(side * 11 - 5, -3) * s, hc + Vector2(side * 11 - 1, -3) * s, Color(1, 1, 1, 0.35), 1.5 * s)
			ci.draw_line(hc + Vector2(-2, -2) * s, hc + Vector2(2, -2) * s, Color("16181c"), 2.5 * s)

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
		8:
			# Melena con flequillo recto
			ci.draw_colored_polygon(cap_pts, hair)
			rrect(ci, Rect2(hc + Vector2(-27, -24) * s, Vector2(54, 15) * s), hair, 6 * s)
			ci.draw_arc(hc + Vector2(0, -2) * s, 26 * s, PI * 1.18, PI * 1.5, 10, Color(hair.lightened(0.35), 0.5), 3 * s)
		9:
			# Cola de caballo: pelo tirante y una gomita
			ci.draw_colored_polygon(cap_pts, hair)
			ci.draw_circle(hc + Vector2(32, -18) * s, 5 * s, Color("d9534a"))
			ci.draw_arc(hc + Vector2(0, -2) * s, 26 * s, PI * 1.2, PI * 1.45, 10, Color(hair.lightened(0.35), 0.5), 3 * s)
		10:
			# Trenza que cae sobre el hombro
			ci.draw_colored_polygon(cap_pts, hair)
			for k in 6:
				var p: Vector2 = hc + Vector2(27 + k * 1.5 + (2 if k % 2 == 0 else -2), 14 + k * 11) * s
				ellipse(ci, p, Vector2(7.5 - k * 0.5, 6.5) * s, hair)
				ci.draw_line(p + Vector2(-5, -3) * s, p + Vector2(4, 3) * s, hair.darkened(0.25), 1.3 * s)
			ci.draw_circle(hc + Vector2(36, 80) * s, 3.5 * s, Color("d9534a"))
		7:
			ci.draw_colored_polygon(cap_pts, hair)
			var hat := Color("fbfbf8")
			rrect(ci, Rect2(hc + Vector2(-27, -36) * s, Vector2(54, 16) * s), hat, 3 * s, Color("d8d8d0"), 1)
			ci.draw_circle(hc + Vector2(-17, -50) * s, 17 * s, hat)
			ci.draw_circle(hc + Vector2(17, -50) * s, 17 * s, hat)
			ci.draw_circle(hc + Vector2(0, -60) * s, 20 * s, hat)
			ci.draw_arc(hc + Vector2(0, -60) * s, 20 * s, PI * 1.1, PI * 1.6, 10, Color("e6e6de"), 2.0 * s)
	_draw_headwear(ci, look, hc, s)


## Gorro del cocinero del jugador (va encima del peinado): de chef, pañuelo atado o gorra
static func _draw_headwear(ci: CanvasItem, look: Dictionary, hc: Vector2, s: float) -> void:
	var col: Color = look.get("cap", Color.WHITE)
	match String(look.get("hat", "")):
		"toque":
			var hat := Color("fbfbf8")
			rrect(ci, Rect2(hc + Vector2(-28, -38) * s, Vector2(56, 17) * s), hat, 3 * s, Color("d8d8d0"), 1)
			for k in 4:
				ci.draw_line(hc + Vector2(-20 + k * 13, -37) * s, hc + Vector2(-20 + k * 13, -23) * s, Color("e6e6de"), 1.5 * s)
			ci.draw_circle(hc + Vector2(-18, -52) * s, 17 * s, hat)
			ci.draw_circle(hc + Vector2(18, -52) * s, 17 * s, hat)
			ci.draw_circle(hc + Vector2(0, -62) * s, 21 * s, hat)
			ci.draw_arc(hc + Vector2(0, -62) * s, 21 * s, PI * 1.1, PI * 1.6, 10, Color("e6e6de"), 2.0 * s)
			ellipse(ci, hc + Vector2(8, -50) * s, Vector2(12, 7) * s, Color(0, 0, 0, 0.04))
		"bandana":
			# Pañuelo atado: cubre la parte de arriba de la cabeza, con el nudo y las puntas al costado
			var pts := PackedVector2Array()
			for k in 15:
				var a := PI + PI * k / 14.0
				pts.append(hc + Vector2(cos(a) * 33.5, sin(a) * 31.0 - 3.0) * s)
			pts.append(hc + Vector2(30, -8) * s)
			pts.append(hc + Vector2(-30, -8) * s)
			ci.draw_colored_polygon(pts, col)
			rrect(ci, Rect2(hc + Vector2(-33, -13) * s, Vector2(66, 7) * s), col.darkened(0.15), 3 * s)
			for d in [Vector2(-14, -22), Vector2(0, -27), Vector2(14, -22), Vector2(-6, -16), Vector2(8, -16)]:
				ci.draw_circle(hc + d * s, 2.2 * s, Color(1, 1, 1, 0.55))
			ci.draw_circle(hc + Vector2(33, -8) * s, 5 * s, col.darkened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(34, -8) * s, hc + Vector2(48, 2) * s, hc + Vector2(40, 8) * s]), col.darkened(0.1))
			ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(34, -6) * s, hc + Vector2(44, 12) * s, hc + Vector2(35, 13) * s]), col)
		"gorra":
			var pts := PackedVector2Array()
			for k in 15:
				var a := PI + PI * k / 14.0
				pts.append(hc + Vector2(cos(a), sin(a) * 0.9) * 33 * s + Vector2(0, -4) * s)
			ci.draw_colored_polygon(pts, col)
			rrect(ci, Rect2(hc + Vector2(-6, -9) * s, Vector2(46, 8) * s), col.darkened(0.2), 4 * s)
			ci.draw_circle(hc + Vector2(0, -33) * s, 3.5 * s, col.darkened(0.25))
			ellipse(ci, hc + Vector2(-8, -24) * s, Vector2(10, 4) * s, Color(1, 1, 1, 0.2))
		"fedora":
			# Sombrero de ala corta con cinta
			ellipse(ci, hc + Vector2(0, -22) * s, Vector2(44, 9) * s, col.darkened(0.15))
			var crown := PackedVector2Array([hc + Vector2(-27, -22) * s, hc + Vector2(-23, -52) * s, hc + Vector2(-8, -57) * s,
				hc + Vector2(0, -51) * s, hc + Vector2(8, -57) * s, hc + Vector2(23, -52) * s, hc + Vector2(27, -22) * s])
			ci.draw_colored_polygon(crown, col)
			ci.draw_rect(Rect2(hc + Vector2(-27, -32) * s, Vector2(54, 8) * s), Color("1d1a18"))
			ellipse(ci, hc + Vector2(-12, -44) * s, Vector2(6, 9) * s, Color(1, 1, 1, 0.1))


## Salón de La Comalera (México): adobe rosado, talavera, papel picado y la ciudad por la ventana
static func draw_dining_mexico(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array) -> void:
	var o := rect.position
	grad_rect(ci, rect, Color("f08a9c"), Color("dd6a82"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	for k in 40:
		ellipse(ci, o + Vector2(rng.randf() * rect.size.x, rng.randf() * 220), Vector2(rng.randf_range(20, 60), rng.randf_range(10, 30)),
			Color(1, 1, 1, 0.05) if k % 2 == 0 else Color(0.5, 0.1, 0.2, 0.05))
	# Zócalo de talavera: azulejos blancos con flores azules y amarillas
	var z := Rect2(o.x, o.y + 228, rect.size.x, rect.size.y - 228)
	ci.draw_rect(z, Color("f6f1e4"))
	var ts := 44.0
	for row in int(z.size.y / ts) + 1:
		for col in int(z.size.x / ts) + 1:
			var c := z.position + Vector2(col * ts + ts / 2.0, row * ts + ts / 2.0)
			if not z.has_point(c):
				continue
			ci.draw_rect(Rect2(c - Vector2(ts, ts) / 2.0, Vector2(ts, ts)), Color("2f5f9f"), false, 1.0)
			for k in 4:
				ci.draw_circle(c + Vector2.from_angle(k * PI / 2.0) * 9.0, 6.0, Color("2f5f9f"))
			ci.draw_circle(c, 6.0, Color("f0b429"))
			ci.draw_circle(c, 2.5, Color("d0461e"))
	ci.draw_rect(Rect2(o.x, o.y + 222, rect.size.x, 8), Color("2f5f9f"))
	# Puerta de madera en arco con el cartel ABIERTO
	var d := Rect2(o.x + 30, o.y + 40, 150, 290)
	var arch := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		arch.append(Vector2(d.get_center().x, d.position.y + 60) + Vector2(cos(a) * 75, sin(a) * 50))
	arch.append(Vector2(d.end.x, d.end.y))
	arch.append(Vector2(d.position.x, d.end.y))
	ci.draw_colored_polygon(arch, Color("2f8a7a"))
	for k in 5:
		ci.draw_line(Vector2(d.position.x + 10 + k * 32, d.position.y + 20), Vector2(d.position.x + 10 + k * 32, d.end.y), Color("246e62"), 2)
	ci.draw_circle(d.position + Vector2(128, 170), 6, Color("e3c26a"))
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("c0392b"), 6, Color("f6e7c8"), 2)
	text(ci, d.position + Vector2(28, 85), "ABIERTO", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, 94)
	# Ventana con marco de cantera: cielo, volcanes y el Ángel de la Independencia
	var w := Rect2(o.x + 300, o.y + 52, 440, 160)
	ci.draw_rect(w.grow(12), Color("e8d2a8"))
	ci.draw_rect(w.grow(4), Color("b8956a"))
	grad_rect(ci, w, Color("7ec8f0"), Color("cfeaf6"))
	ci.draw_circle(w.position + Vector2(370, 40), 22, Color(1, 0.95, 0.7, 0.9))
	ci.draw_colored_polygon(PackedVector2Array([w.position + Vector2(10, w.size.y), w.position + Vector2(110, 70), w.position + Vector2(130, 74),
		w.position + Vector2(150, 68), w.position + Vector2(260, w.size.y)]), Color("8a9ab0"))
	ci.draw_colored_polygon(PackedVector2Array([w.position + Vector2(108, 72), w.position + Vector2(130, 74), w.position + Vector2(152, 70),
		w.position + Vector2(140, 86), w.position + Vector2(120, 88)]), Color.WHITE)
	ci.draw_colored_polygon(PackedVector2Array([w.position + Vector2(180, w.size.y), w.position + Vector2(280, 90), w.position + Vector2(380, w.size.y)]), Color("9aa8bc"))
	for k in 6:
		var bx := w.position.x + 20 + k * 72
		var bh := 40.0 + (k * 37) % 50
		ci.draw_rect(Rect2(bx, w.end.y - bh, 50, bh), Color("e9c99a") if k % 2 == 0 else Color("d9a87a"))
		for j in int(bh / 14):
			ci.draw_rect(Rect2(bx + 8, w.end.y - bh + 6 + j * 14, 8, 6), Color(1, 1, 1, 0.5))
			ci.draw_rect(Rect2(bx + 30, w.end.y - bh + 6 + j * 14, 8, 6), Color(1, 1, 1, 0.5))
	var ax := w.position.x + 220
	ci.draw_rect(Rect2(ax - 6, w.position.y + 46, 12, w.size.y - 46), Color("e8dcc0"))
	ci.draw_rect(Rect2(ax - 14, w.end.y - 18, 28, 18), Color("d8c8a8"))
	ci.draw_circle(Vector2(ax, w.position.y + 38), 7, Color("e0b030"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(ax - 18, w.position.y + 32), Vector2(ax, w.position.y + 40), Vector2(ax + 18, w.position.y + 32),
		Vector2(ax, w.position.y + 46)]), Color("e0b030"))
	ci.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("b8956a"), 5)
	# Sombrero colgado y maceta con cactus
	var hc := o + Vector2(790, 110)
	ci.draw_line(hc + Vector2(0, -60), hc + Vector2(0, -24), Color("6b4a2a"), 3)
	ellipse(ci, hc, Vector2(58, 16), Color("d8a84a"))
	ellipse(ci, hc + Vector2(0, -16), Vector2(24, 22), Color("e4b85a"))
	ci.draw_arc(hc + Vector2(0, -2), 50, 0.2, PI - 0.2, 20, Color("c0392b"), 4)
	rrect(ci, Rect2(hc + Vector2(-24, -10), Vector2(48, 6)), Color("2f8a4a"), 3)
	var pot := o + Vector2(800, 222)
	ci.draw_colored_polygon(PackedVector2Array([pot + Vector2(-26, -40), pot + Vector2(26, -40), pot + Vector2(20, 0), pot + Vector2(-20, 0)]), Color("c0602a"))
	ci.draw_rect(Rect2(pot + Vector2(-28, -46), Vector2(56, 8)), Color("a84e22"))
	rrect(ci, Rect2(pot + Vector2(-10, -110), Vector2(20, 66)), Color("3f8a3a"), 10)
	rrect(ci, Rect2(pot + Vector2(-30, -90), Vector2(14, 34)), Color("3f8a3a"), 7)
	rrect(ci, Rect2(pot + Vector2(-30, -62), Vector2(24, 10)), Color("3f8a3a"), 5)
	rrect(ci, Rect2(pot + Vector2(16, -100), Vector2(14, 30)), Color("3f8a3a"), 7)
	rrect(ci, Rect2(pot + Vector2(8, -76), Vector2(22, 10)), Color("3f8a3a"), 5)
	ci.draw_circle(pot + Vector2(0, -112), 6, Color("f06292"))
	# Papel picado de colores
	for k in 40:
		var x := o.x + 200 + k * 30.0
		if x > rect.end.x - 20:
			break
		var y := o.y + 16 + sin(k * 0.5) * 3
		var colp: Color = [Color("e91e63"), Color("ff9800"), Color("2196f3"), Color("4caf50"), Color("9c27b0"), Color("ffeb3b")][k % 6]
		var flag := Rect2(x, y, 26, 30)
		ci.draw_rect(flag, colp)
		ci.draw_circle(flag.get_center() + Vector2(0, -2), 5, Color(colp.lightened(0.5), 0.8))
		ci.draw_rect(Rect2(flag.position + Vector2(4, 22), Vector2(4, 4)), Color(colp.lightened(0.5), 0.8))
		ci.draw_rect(Rect2(flag.position + Vector2(18, 22), Vector2(4, 4)), Color(colp.lightened(0.5), 0.8))
		for zz in 4:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + zz * 6.5, y + 30), Vector2(x + zz * 6.5 + 6.5, y + 30), Vector2(x + zz * 6.5 + 3.25, y + 35)]), colp)
	ci.draw_line(Vector2(o.x + 200, o.y + 16), Vector2(rect.end.x, o.y + 16), Color(1, 1, 1, 0.6), 1.5)
	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 52, 300, 166)
	ci.draw_rect(b.grow(9), Color("6e4527"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "MENÚ DEL DÍA", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	for i in menu.size():
		text(ci, b.position + Vector2(18, 62 + i * 24), "• " + str(menu[i]), 16, Color("e9f0dc"), HORIZONTAL_ALIGNMENT_LEFT, 270)
	for x in [260, 640, 1220]:
		lamp(ci, o.x + x, o.y + 14, 4, time)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(850, 14), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(450, 14), time)


## Frente del mostrador mexicano: madera pintada con franjas de colores
static func draw_counter_mexico(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	var front := Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18)
	ci.draw_rect(front, Color("2f8a7a"))
	var cols := [Color("e91e63"), Color("ff9800"), Color("ffeb3b"), Color("4caf50"), Color("2196f3")]
	for k in 5:
		ci.draw_rect(Rect2(front.position.x, front.position.y + 22 + k * 9, front.size.x, 6), cols[k])
	for x in range(0, int(front.size.x), 160):
		var c := Vector2(front.position.x + x + 80, front.position.y + 120)
		if c.y < front.end.y - 10:
			for k in 6:
				ci.draw_circle(c + Vector2.from_angle(k * TAU / 6.0) * 16, 9, Color("f0b429"))
			ci.draw_circle(c, 10, Color("d0461e"))
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("8a5a2b"), Color("6e4527"))
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.25))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


# --- Hamburguesa por capas (EE.UU.) ---

## Alto relativo de cada capa (respecto del ancho del pan)
static func burger_layer_h(name: String) -> float:
	match name:
		"PanAbajo": return 0.17
		"PanArriba": return 0.32
		"Carne": return 0.16
		"Cheddar": return 0.05
		"Lechuga": return 0.08
		"Tomate": return 0.07
		"Cebolla": return 0.05
		"Panceta": return 0.06
		"Pepinos": return 0.05
		"Ketchup", "Mostaza": return 0.035
	return 0.05


## Dibuja una capa apoyada en y (borde de abajo), centrada en cx, de ancho w. Devuelve cuánto ocupa.
static func draw_burger_layer(ci: CanvasItem, cx: float, y: float, w: float, name: String, patty_col := Color("6a3218")) -> float:
	var h := burger_layer_h(name) * w
	var x0 := cx - w / 2.0
	match name:
		"PanAbajo":
			rrect(ci, Rect2(x0 + w * 0.03, y - h, w * 0.94, h), Color("d9944a"), h * 0.45)
			ci.draw_rect(Rect2(x0 + w * 0.04, y - h, w * 0.92, h * 0.3), Color("f2d6a4"))
		"PanArriba":
			var pts := PackedVector2Array()
			for k in 21:
				var a := PI + PI * k / 20.0
				pts.append(Vector2(cx + cos(a) * w * 0.5, y + sin(a) * h))
			ci.draw_colored_polygon(pts, Color("e8a556"))
			ci.draw_arc(Vector2(cx, y), w * 0.42, PI * 1.15, PI * 1.45, 10, Color(1, 1, 1, 0.25), w * 0.03)
			for k in 7:
				var sp := Vector2(cx + (k - 3) * w * 0.11, y - h * (0.45 + 0.3 * absf(sin(k * 1.7))))
				ellipse(ci, sp, Vector2(w * 0.022, w * 0.012), Color("fbf0d4"))
		"Carne":
			rrect(ci, Rect2(x0, y - h, w, h), patty_col, h * 0.45)
			for k in 6:
				ci.draw_circle(Vector2(x0 + w * (0.1 + k * 0.16), y - h * 0.5), w * 0.02, patty_col.darkened(0.3))
			ci.draw_line(Vector2(x0 + w * 0.08, y - h * 0.8), Vector2(x0 + w * 0.92, y - h * 0.8), Color(1, 1, 1, 0.12), w * 0.02)
		"Cheddar":
			var pts := PackedVector2Array([Vector2(x0 - w * 0.02, y - h), Vector2(x0 + w * 1.02, y - h), Vector2(x0 + w * 0.98, y),
				Vector2(x0 + w * 0.82, y + h * 1.2), Vector2(x0 + w * 0.7, y), Vector2(x0 + w * 0.3, y), Vector2(x0 + w * 0.18, y + h * 1.4), Vector2(x0 + w * 0.06, y)])
			ci.draw_colored_polygon(pts, Color("f2b31d"))
		"Lechuga":
			var pts := PackedVector2Array()
			for k in 17:
				pts.append(Vector2(x0 - w * 0.04 + w * 1.08 * k / 16.0, y - h * (0.5 + 0.5 * absf(sin(k * 1.3)))))
			pts.append(Vector2(x0 + w * 1.04, y))
			pts.append(Vector2(x0 - w * 0.04, y))
			ci.draw_colored_polygon(pts, Color("5fae3a"))
			ci.draw_line(Vector2(x0, y - h * 0.4), Vector2(x0 + w, y - h * 0.4), Color("8fd06a"), w * 0.01)
		"Tomate":
			for k in 3:
				rrect(ci, Rect2(x0 + w * (0.02 + k * 0.33), y - h, w * 0.31, h), Color("d9372a"), h * 0.4)
				ci.draw_circle(Vector2(x0 + w * (0.17 + k * 0.33), y - h * 0.5), h * 0.25, Color("f08a6a"))
		"Cebolla":
			for k in 4:
				ellipse(ci, Vector2(x0 + w * (0.14 + k * 0.24), y - h * 0.5), Vector2(w * 0.11, h * 0.5), Color("e8dcf0"))
				ellipse(ci, Vector2(x0 + w * (0.14 + k * 0.24), y - h * 0.5), Vector2(w * 0.07, h * 0.28), Color("b88ac8"))
		"Panceta":
			for k in 2:
				var pts := PackedVector2Array()
				for j in 11:
					pts.append(Vector2(x0 + w * (0.02 + k * 0.5) + w * 0.46 * j / 10.0, y - h + sin(j * 1.2) * h * 0.3))
				ci.draw_polyline(pts, Color("a8423a"), h * 0.8)
				ci.draw_polyline(pts, Color("e8a090"), h * 0.25)
		"Pepinos":
			for k in 4:
				ellipse(ci, Vector2(x0 + w * (0.14 + k * 0.24), y - h * 0.5), Vector2(w * 0.1, h * 0.5), Color("5a8a2a"))
				ellipse(ci, Vector2(x0 + w * (0.14 + k * 0.24), y - h * 0.5), Vector2(w * 0.07, h * 0.3), Color("b6d27a"))
		"Ketchup", "Mostaza":
			var col := Color("c4161c") if name == "Ketchup" else Color("e8b923")
			var pts := PackedVector2Array()
			for k in 25:
				pts.append(Vector2(x0 + w * 0.08 + w * 0.84 * k / 24.0, y - h * 0.5 + sin(k * 1.4) * h * 0.4))
			ci.draw_polyline(pts, col, h * 0.9, true)
	return h


## La hamburguesa vista de costado: pan de abajo, las capas en orden y (si está cerrada) el pan de arriba
static func draw_burger(ci: CanvasItem, rect: Rect2, layers: Array, closed := true, patty_t := -1.0, target := 7.0, burn := 14.0, on_bottom := false) -> void:
	var total := burger_layer_h("PanAbajo") + (burger_layer_h("PanArriba") if closed else 0.0)
	for l in layers:
		total += burger_layer_h(l)
	var w := minf(rect.size.x * 0.9, rect.size.y * 0.9 / maxf(total, 0.6))
	var cx := rect.get_center().x
	var y := rect.get_center().y + total * w / 2.0
	if on_bottom:
		y = rect.end.y
	ellipse(ci, Vector2(cx, y + w * 0.02), Vector2(w * 0.52, w * 0.06), Color(0, 0, 0, 0.2))
	var patty_col := Color("6a3218")
	if patty_t >= 0.0:
		patty_col = Color("a8533a").lerp(Color("5a2a14"), clampf(patty_t / target, 0.0, 1.0))
		if patty_t > target:
			patty_col = patty_col.lerp(Color("2a1810"), clampf((patty_t - target) / (burn - target), 0.0, 1.0))
	y -= draw_burger_layer(ci, cx, y, w, "PanAbajo")
	for l in layers:
		y -= draw_burger_layer(ci, cx, y, w, l, patty_col)
	if closed:
		draw_burger_layer(ci, cx, y, w, "PanArriba")


## Ícono de un ingrediente para apilar (los cajones del Armado)
static func draw_layer_bin(ci: CanvasItem, rect: Rect2, name: String) -> void:
	rrect(ci, rect.grow(-3), Color("e9eef1"), 8, Color("aab3ba"), 2)
	var w := rect.size.x * 0.7
	var h := burger_layer_h(name) * w
	draw_burger_layer(ci, rect.get_center().x, rect.get_center().y + h / 2.0 - 6, w, name)


## Salón del Big Apple Diner (EE.UU.): pared turquesa, damero blanco y negro, cromo, neón y Nueva York por la ventana
static func draw_dining_eeuu(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array) -> void:
	var o := rect.position
	grad_rect(ci, rect, Color("8fd3c8"), Color("6fbfb2"))
	# Damero abajo y moldura de cromo
	var z := Rect2(o.x, o.y + 232, rect.size.x, rect.size.y - 232)
	var ts := 40.0
	for row in int(z.size.y / ts) + 1:
		for col in int(z.size.x / ts) + 1:
			var r := Rect2(z.position + Vector2(col * ts, row * ts), Vector2(ts, ts)).intersection(z)
			if r.size.x > 0 and r.size.y > 0:
				ci.draw_rect(r, Color("1d1d1f") if (row + col) % 2 == 0 else Color("f6f4ee"))
	grad_rect(ci, Rect2(o.x, o.y + 222, rect.size.x, 12), Color("f2f4f6"), Color("9aa3ab"))
	ci.draw_rect(Rect2(o.x, o.y + 226, rect.size.x, 2), Color(1, 1, 1, 0.8))
	# Puerta de vidrio con marco de cromo y el cartel OPEN
	var d := Rect2(o.x + 30, o.y + 40, 150, 290)
	rrect(ci, d, Color("c8ccd0"), 6, Color("8a9298"), 4)
	ci.draw_rect(d.grow(-14), Color(0.75, 0.9, 0.95, 0.75))
	ci.draw_line(d.position + Vector2(30, 40), d.position + Vector2(60, 10), Color(1, 1, 1, 0.6), 3)
	rrect(ci, Rect2(d.position + Vector2(120, 150), Vector2(10, 60)), Color("8a9298"), 4)
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("c0281a"), 6, Color("f6e7c8"), 2)
	text(ci, d.position + Vector2(28, 85), "OPEN", 16, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 94)
	# Ventana con Nueva York: rascacielos, el Empire State y un taxi
	var w := Rect2(o.x + 300, o.y + 60, 440, 150)
	rrect(ci, w.grow(10), Color("dfe3e6"), 10, Color("9aa3ab"), 3)
	grad_rect(ci, w, Color("f6b26b"), Color("fbe3b8"))
	for k in 11:
		var bx := w.position.x + k * 42.0
		var bh := 50.0 + (k * 53) % 70
		ci.draw_rect(Rect2(bx, w.end.y - bh, 36, bh), Color("6b5a7a") if k % 2 == 0 else Color("5a4a6a"))
		for j in int(bh / 14):
			for q in 3:
				if (j + q + k) % 3 != 0:
					ci.draw_rect(Rect2(bx + 5 + q * 10, w.end.y - bh + 6 + j * 14, 5, 6), Color(1, 0.9, 0.55, 0.8))
	var ex := w.position.x + 230
	ci.draw_rect(Rect2(ex - 20, w.position.y + 60, 40, w.size.y - 60), Color("4a3a5a"))
	ci.draw_rect(Rect2(ex - 12, w.position.y + 34, 24, 28), Color("4a3a5a"))
	ci.draw_rect(Rect2(ex - 6, w.position.y + 16, 12, 20), Color("4a3a5a"))
	ci.draw_line(Vector2(ex, w.position.y + 16), Vector2(ex, w.position.y), Color("4a3a5a"), 3)
	rrect(ci, Rect2(w.position.x + 60, w.end.y - 18, 46, 16), Color("f2c418"), 4)
	ci.draw_circle(Vector2(w.position.x + 70, w.end.y - 2), 4, Color("1d1d1f"))
	ci.draw_circle(Vector2(w.position.x + 96, w.end.y - 2), 4, Color("1d1d1f"))
	ci.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("dfe3e6"), 5)
	# Cartel de neón DINER que titila
	var glow := 0.75 + 0.25 * sin(time * 3.0) * (1.0 if fmod(time, 7.0) > 0.25 else 0.0)
	var nr := Rect2(o.x + 760, o.y + 40, 104, 46)
	rrect(ci, nr.grow(6), Color(1, 0.2, 0.4, 0.15 * glow), 14)
	rrect(ci, nr, Color("2a2a2e"), 8, Color(1, 0.3, 0.5, glow), 3)
	text(ci, nr.position + Vector2(0, 33), "DINER", 24, Color(1, 0.55, 0.7, glow), HORIZONTAL_ALIGNMENT_CENTER, nr.size.x)
	# Rocola
	var jb := Rect2(o.x + 770, o.y + 110, 84, 120)
	var arch := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		arch.append(Vector2(jb.get_center().x, jb.position.y + 40) + Vector2(cos(a) * 42, sin(a) * 40))
	arch.append(jb.end)
	arch.append(Vector2(jb.position.x, jb.end.y))
	ci.draw_colored_polygon(arch, Color("c0392b"))
	rrect(ci, Rect2(jb.position + Vector2(12, 34), Vector2(60, 36)), Color(1, 0.85, 0.4, 0.6 + 0.3 * sin(time * 4.0)), 6)
	for k in 4:
		ci.draw_line(jb.position + Vector2(18 + k * 16, 80), jb.position + Vector2(18 + k * 16, 112), Color("f2c418"), 3)
	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 52, 300, 166)
	ci.draw_rect(b.grow(9), Color("c8ccd0"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "TODAY'S MENU", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	for i in menu.size():
		text(ci, b.position + Vector2(18, 62 + i * 24), "• " + str(menu[i]), 16, Color("e9f0dc"), HORIZONTAL_ALIGNMENT_LEFT, 270)
	for x in [260, 640, 1220]:
		lamp(ci, o.x + x, o.y + 14, 4, time)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(240, 14), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(450, 14), time)


## Frente del mostrador del diner: cromo acanalado y franja roja
static func draw_counter_eeuu(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	var front := Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18)
	grad_rect(ci, front, Color("e6eaed"), Color("aab3ba"))
	for x in range(0, int(front.size.x), 14):
		ci.draw_line(Vector2(front.position.x + x, front.position.y), Vector2(front.position.x + x, front.end.y), Color(1, 1, 1, 0.35), 2)
		ci.draw_line(Vector2(front.position.x + x + 6, front.position.y), Vector2(front.position.x + x + 6, front.end.y), Color(0, 0, 0, 0.08), 2)
	ci.draw_rect(Rect2(front.position.x, front.position.y + 30, front.size.x, 18), Color("c0281a"))
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("e8463c"), Color("b02a20"))
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.3))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


# --- Francia ---

## Bowl con masa de crêpes y el cucharón adentro
static func draw_batter_bowl(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center() + Vector2(0, 12)
	var r := minf(rect.size.x * 0.42, rect.size.y * 0.5)
	ellipse(ci, c + Vector2(4, r * 0.5), Vector2(r * 1.05, r * 0.25), Color(0, 0, 0, 0.18))
	var bowl := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		bowl.append(c + Vector2(cos(a) * r, sin(a) * r * 0.65 - r * 0.1))
	ci.draw_colored_polygon(bowl, Color("f2f0ea"))
	ellipse(ci, c + Vector2(0, -r * 0.1), Vector2(r, r * 0.22), Color("d8d4c8"))
	ellipse(ci, c + Vector2(0, -r * 0.08), Vector2(r * 0.9, r * 0.17), Color("f4e4bc"))
	ci.draw_line(c + Vector2(r * 0.1, -r * 0.1), c + Vector2(r * 0.8, -r * 1.1), Color("8a9298"), r * 0.1)
	ellipse(ci, c + Vector2(r * 0.05, -r * 0.08), Vector2(r * 0.25, r * 0.08), Color("8a9298"))


## Manga pastelera llena del glaseado de ese color
static func draw_piping_bag(ci: CanvasItem, rect: Rect2, col: Color) -> void:
	var c := rect.get_center() + Vector2(0, -6)
	var h := minf(rect.size.y * 0.75, rect.size.x)
	var bag := PackedVector2Array([c + Vector2(-h * 0.04, h * 0.42), c + Vector2(h * 0.04, h * 0.42), c + Vector2(h * 0.3, -h * 0.34), c + Vector2(-h * 0.3, -h * 0.34)])
	ci.draw_colored_polygon(bag, Color(0.95, 0.95, 0.97, 0.95))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.04, h * 0.3), c + Vector2(h * 0.04, h * 0.3), c + Vector2(h * 0.2, -h * 0.2), c + Vector2(-h * 0.2, -h * 0.2)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, h * 0.5), c + Vector2(-h * 0.05, h * 0.4), c + Vector2(h * 0.05, h * 0.4)]), Color("9aa3ab"))
	rrect(ci, Rect2(c + Vector2(-h * 0.32, -h * 0.4), Vector2(h * 0.64, h * 0.08)), Color("d8d2c4"), 3)


## Éclair visto de arriba con el glaseado en zigzag del sabor
static func draw_eclair(ci: CanvasItem, rect: Rect2, flavor: String) -> void:
	var cols := {"Chocolate": Color("4a2412"), "Café": Color("a0703a"), "Frutilla": Color("f28aa8")}
	var col: Color = cols.get(flavor, Color("4a2412"))
	var c := rect.get_center()
	var w := rect.size.x * 0.9
	var h := w * 0.3
	rrect(ci, Rect2(c.x - w / 2.0 + 3, c.y - h / 2.0 + 5, w, h), Color(0, 0, 0, 0.18), h * 0.5)
	rrect(ci, Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h), Color("d9944a"), h * 0.5, Color("a8661e"), 2)
	var pts := PackedVector2Array()
	for k in 15:
		var u := k / 14.0
		pts.append(Vector2(c.x - w * 0.4 + u * w * 0.8, c.y + sin(u * PI * 7.0) * h * 0.22))
	ci.draw_polyline(pts, col.darkened(0.2), h * 0.3, true)
	ci.draw_polyline(pts, col, h * 0.22, true)
	ci.draw_polyline(pts, Color(col.lightened(0.45), 0.5), h * 0.05, true)


## Salón de Le Petit Crêpier (Francia): boiserie verde y crema, toldo a rayas, espejos y París con la torre
static func draw_dining_francia(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array) -> void:
	var o := rect.position
	grad_rect(ci, rect, Color("f4ead2"), Color("e8dab8"))
	# Boiserie: paneles con molduras
	for x in range(0, int(rect.size.x), 160):
		rrect(ci, Rect2(o.x + x + 14, o.y + 30, 132, 170), Color(0, 0, 0, 0), 4, Color(0.6, 0.5, 0.3, 0.25), 2)
	var z := Rect2(o.x, o.y + 228, rect.size.x, rect.size.y - 228)
	ci.draw_rect(z, Color("2f5a46"))
	for x in range(0, int(rect.size.x), 120):
		rrect(ci, Rect2(o.x + x + 12, z.position.y + 14, 96, z.size.y - 28), Color(0, 0, 0, 0), 4, Color(1, 1, 1, 0.18), 2)
	grad_rect(ci, Rect2(o.x, o.y + 220, rect.size.x, 10), Color("d9b45a"), Color("a8862a"))
	# Puerta verde con vidrio y el cartel OUVERT
	var d := Rect2(o.x + 30, o.y + 40, 150, 290)
	rrect(ci, d, Color("2f5a46"), 6, Color("1f3e30"), 3)
	ci.draw_rect(Rect2(d.position + Vector2(16, 16), Vector2(118, 130)), Color(0.75, 0.88, 0.9, 0.8))
	ci.draw_line(d.position + Vector2(75, 16), d.position + Vector2(75, 146), Color("2f5a46"), 4)
	ci.draw_circle(d.position + Vector2(130, 170), 6, Color("e3c26a"))
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("1f3e30"), 6, Color("e3c26a"), 2)
	text(ci, d.position + Vector2(28, 85), "OUVERT", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, 94)
	# Ventana con toldo a rayas y París con la torre
	var w := Rect2(o.x + 300, o.y + 66, 440, 146)
	rrect(ci, w.grow(10), Color("f6f0e0"), 4, Color("b8a070"), 3)
	grad_rect(ci, w, Color("a8c8e8"), Color("e8d8f0"))
	for k in 9:
		var bx := w.position.x + k * 50.0
		var bh := 40.0 + (k * 29) % 30
		ci.draw_rect(Rect2(bx, w.end.y - bh, 46, bh), Color("e8dcc8"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 2, w.end.y - bh), Vector2(bx + 48, w.end.y - bh), Vector2(bx + 40, w.end.y - bh - 12), Vector2(bx + 6, w.end.y - bh - 12)]), Color("7a8a9a"))
		for j in 2:
			ci.draw_rect(Rect2(bx + 8 + j * 18, w.end.y - bh + 10, 8, 12), Color("8aa0b8"))
	var ex := w.position.x + 300
	var base := w.end.y
	ci.draw_colored_polygon(PackedVector2Array([Vector2(ex - 36, base), Vector2(ex - 6, base - 100), Vector2(ex + 6, base - 100), Vector2(ex + 36, base),
		Vector2(ex + 20, base), Vector2(ex, base - 30), Vector2(ex - 20, base)]), Color("5a4a3a"))
	ci.draw_rect(Rect2(ex - 22, base - 52, 44, 5), Color("5a4a3a"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(ex - 6, base - 100), Vector2(ex, base - 128), Vector2(ex + 6, base - 100)]), Color("5a4a3a"))
	ci.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("f6f0e0"), 5)
	# Toldo
	for k in 12:
		var ax := w.position.x - 20 + k * 40.0
		ci.draw_rect(Rect2(ax, w.position.y - 40, 40, 30), Color("c0392b") if k % 2 == 0 else Color("f6f0e0"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ax, w.position.y - 10), Vector2(ax + 40, w.position.y - 10), Vector2(ax + 20, w.position.y + 4)]),
			Color("c0392b") if k % 2 == 0 else Color("f6f0e0"))
	# Espejo redondo con marco dorado y canasto de baguettes
	var m := o + Vector2(810, 110)
	ci.draw_circle(m, 46, Color("c9a24a"))
	ci.draw_circle(m, 38, Color("dfe8ec"))
	ci.draw_line(m + Vector2(-20, -10), m + Vector2(-4, -26), Color(1, 1, 1, 0.6), 4)
	var bk := o + Vector2(810, 214)
	for k in 4:
		ci.draw_line(bk + Vector2(-20 + k * 12, 0), bk + Vector2(-30 + k * 16, -58 - k * 4), Color("d9944a"), 10)
		for j in 3:
			ci.draw_line(bk + Vector2(-23 + k * 12 - j * 3, -14 - j * 14), bk + Vector2(-17 + k * 12 - j * 3, -18 - j * 14), Color("f6c784"), 2)
	rrect(ci, Rect2(bk + Vector2(-36, -16), Vector2(72, 20)), Color("b88a4a"), 6)
	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 52, 300, 166)
	ci.draw_rect(b.grow(9), Color("c9a24a"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "MENU DU JOUR", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	for i in menu.size():
		text(ci, b.position + Vector2(18, 62 + i * 24), "• " + str(menu[i]), 16, Color("e9f0dc"), HORIZONTAL_ALIGNMENT_LEFT, 270)
	for x in [260, 640, 1220]:
		lamp(ci, o.x + x, o.y + 14, 4, time)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(240, 14), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(450, 14), time)


## Frente del mostrador del bistró: zinc arriba y madera verde con paneles
static func draw_counter_francia(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	var front := Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18)
	ci.draw_rect(front, Color("2f5a46"))
	for x in range(0, int(front.size.x), 160):
		rrect(ci, Rect2(front.position.x + x + 14, front.position.y + 16, 132, front.size.y - 30), Color(0, 0, 0, 0.12), 6, Color("d9b45a"), 2)
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("c8ccd0"), Color("8a9298"))
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.4))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


# --- India ---

## Latita de la masala dabba vista de arriba, llena de la especia
static func draw_spice_tin(ci: CanvasItem, rect: Rect2, col: Color) -> void:
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.42
	ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.25))
	ci.draw_circle(c, r, Color("b8bcc0"))
	ci.draw_circle(c, r * 0.86, col.darkened(0.1))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(col.r * 1000)
	for k in 14:
		ci.draw_circle(c + Vector2.from_angle(rng.randf() * TAU) * r * 0.75 * sqrt(rng.randf()), r * 0.06, col.lightened(0.2))
	ci.draw_arc(c, r * 0.93, PI * 1.1, PI * 1.6, 10, Color(1, 1, 1, 0.5), r * 0.08)


## Karahi (sartén honda) con aceite y las especias que se van agregando, cada una con su color
static func draw_karahi(ci: CanvasItem, c: Vector2, r: float, spices: Array, time: float) -> void:
	var cols := {"Comino": Color("8a6a3a"), "Cúrcuma": Color("f2b01d"), "Jengibre": Color("e8c88a"),
		"Garam masala": Color("7a3a1e"), "Chile": Color("c8281a"), "Cardamomo": Color("6a8a3a")}
	for side in [-1, 1]:
		rrect(ci, Rect2(c + Vector2(side * (r + 10) - 16, -10), Vector2(32, 20)), Color("2a2a2a"), 8)
	ci.draw_circle(c + Vector2(4, 8), r, Color(0, 0, 0, 0.3))
	ci.draw_circle(c, r, Color("3a3634"))
	ci.draw_circle(c, r * 0.9, Color("4a4542"))
	var base := Color("d8a43a")
	for s in spices:
		base = base.lerp(cols.get(s, base), 0.45)
	ci.draw_circle(c, r * 0.72, base.darkened(0.1))
	# Cada especia deja su remolino
	for k in spices.size():
		var col: Color = cols.get(spices[k], Color.WHITE)
		var a0 := time * 0.6 + k * 1.3
		ci.draw_arc(c, r * (0.2 + k * 0.1), a0, a0 + 2.4, 18, col, r * 0.06)
	# Burbujas del aceite caliente
	for k in 7:
		var ph := fmod(time * 1.5 + k * 0.37, 1.0)
		ci.draw_circle(c + Vector2.from_angle(k * 2.3) * r * 0.5, r * 0.03 * (1.0 - ph) + 1, Color(1, 1, 1, 0.4 * (1.0 - ph)))
	steam(ci, c + Vector2(0, -r * 0.4), time, 0.8, 4)


## Masala servido en su cuenquito de bronce
static func draw_masala(ci: CanvasItem, rect: Rect2, spices: Array) -> void:
	var cols := {"Comino": Color("8a6a3a"), "Cúrcuma": Color("f2b01d"), "Jengibre": Color("e8c88a"),
		"Garam masala": Color("7a3a1e"), "Chile": Color("c8281a"), "Cardamomo": Color("6a8a3a")}
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.42
	var base := Color("d0661e")
	for s in spices:
		base = base.lerp(cols.get(s, base), 0.3)
	ci.draw_circle(c + Vector2(2, 4), r, Color(0, 0, 0, 0.2))
	ci.draw_circle(c, r, Color("c9a24a"))
	ci.draw_circle(c, r * 0.84, base.darkened(0.12))
	ci.draw_circle(c, r * 0.74, base)
	ci.draw_arc(c, r * 0.45, 0.4, 2.6, 14, base.lightened(0.3), r * 0.08)
	ci.draw_arc(c, r * 0.95, PI * 1.1, PI * 1.6, 10, Color(1, 1, 1, 0.4), r * 0.06)


## Salón de Masala Express (India): azafrán, arcos, guirnaldas de caléndulas y la Puerta de la India
static func draw_dining_india(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array) -> void:
	var o := rect.position
	grad_rect(ci, rect, Color("f6b04a"), Color("e8902a"))
	# Arcos decorativos en la pared
	for x in range(220, int(rect.size.x) - 100, 180):
		var ac := Vector2(o.x + x + 70, o.y + 80)
		var arch := PackedVector2Array()
		for k in 17:
			var a := PI + PI * k / 16.0
			arch.append(ac + Vector2(cos(a) * 56, sin(a) * 50))
		arch.append(ac + Vector2(56, 130))
		arch.append(ac + Vector2(-56, 130))
		ci.draw_colored_polygon(arch, Color(1, 1, 1, 0.12))
	# Zócalo turquesa con flores
	var z := Rect2(o.x, o.y + 228, rect.size.x, rect.size.y - 228)
	ci.draw_rect(z, Color("1f8a8a"))
	for x in range(30, int(rect.size.x), 80):
		var fc := Vector2(o.x + x, z.position.y + 40)
		for k in 8:
			ci.draw_circle(fc + Vector2.from_angle(k * TAU / 8.0) * 12, 6, Color("f6d040"))
		ci.draw_circle(fc, 7, Color("d0461e"))
	grad_rect(ci, Rect2(o.x, o.y + 220, rect.size.x, 10), Color("e3c26a"), Color("a8862a"))
	# Puerta tallada con el cartel KHULA (abierto)
	var d := Rect2(o.x + 30, o.y + 40, 150, 290)
	var darch := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		darch.append(Vector2(d.get_center().x, d.position.y + 60) + Vector2(cos(a) * 75, sin(a) * 60))
	darch.append(d.end)
	darch.append(Vector2(d.position.x, d.end.y))
	ci.draw_colored_polygon(darch, Color("7a3a1e"))
	for k in 4:
		for j in 2:
			rrect(ci, Rect2(d.position + Vector2(20 + j * 62, 110 + k * 44), Vector2(48, 34)), Color(0, 0, 0, 0), 4, Color("c9a24a"), 2)
	ci.draw_circle(d.position + Vector2(128, 170), 6, Color("e3c26a"))
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("1f8a8a"), 6, Color("f6e7c8"), 2)
	text(ci, d.position + Vector2(28, 85), "ABIERTO", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, 94)
	# Ventana con la Puerta de la India y el mar
	var w := Rect2(o.x + 300, o.y + 60, 440, 150)
	rrect(ci, w.grow(10), Color("c9a24a"), 8, Color("8a6a1e"), 3)
	grad_rect(ci, w, Color("f6c88a"), Color("fbe6c4"))
	ci.draw_rect(Rect2(w.position.x, w.end.y - 30, w.size.x, 30), Color("4a9ab8"))
	for k in 6:
		ci.draw_line(Vector2(w.position.x + 20 + k * 70, w.end.y - 18), Vector2(w.position.x + 50 + k * 70, w.end.y - 18), Color(1, 1, 1, 0.5), 2)
	var gx := w.position.x + 220
	var gy := w.end.y - 30
	ci.draw_rect(Rect2(gx - 70, gy - 80, 140, 80), Color("e8c89a"))
	var garch := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		garch.append(Vector2(gx, gy - 40) + Vector2(cos(a) * 24, sin(a) * 26))
	garch.append(Vector2(gx + 24, gy))
	garch.append(Vector2(gx - 24, gy))
	ci.draw_colored_polygon(garch, Color("c89a6a"))
	for side in [-1, 1]:
		ci.draw_rect(Rect2(gx + side * 62 - 8, gy - 100, 16, 22), Color("e8c89a"))
		ci.draw_circle(Vector2(gx + side * 62, gy - 102), 9, Color("e8c89a"))
	ci.draw_rect(Rect2(gx - 70, gy - 86, 140, 8), Color("d8b88a"))
	for k in 3:
		var px := w.position.x + 40 + k * 40.0
		ci.draw_line(Vector2(px, gy), Vector2(px + 6, gy - 60), Color("6a4a2a"), 4)
		for j in 5:
			ci.draw_line(Vector2(px + 6, gy - 60), Vector2(px + 6, gy - 60) + Vector2.from_angle(PI + j * 0.6 - 0.3) * 24, Color("3f8a3a"), 4)
	ci.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("c9a24a"), 5)
	# Lámpara de bronce colgante y guirnaldas de caléndulas
	var lp := o + Vector2(810, 60)
	ci.draw_line(lp + Vector2(0, -46), lp, Color("8a6a1e"), 2)
	ci.draw_colored_polygon(PackedVector2Array([lp + Vector2(-24, 0), lp + Vector2(24, 0), lp + Vector2(14, 34), lp + Vector2(-14, 34)]), Color("c9a24a"))
	ci.draw_circle(lp + Vector2(0, 40), 8, Color(1, 0.8, 0.3, 0.7 + 0.2 * sin(time * 5.0)))
	for k in 40:
		var x := o.x + 200 + k * 26.0
		if x > rect.end.x - 20:
			break
		var y := o.y + 18 + sin(k * 0.45) * 8.0 + 8.0
		ci.draw_circle(Vector2(x, y), 9, Color("f29a1d") if k % 2 == 0 else Color("f6d040"))
		ci.draw_circle(Vector2(x, y), 3, Color("d0461e"))
	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 52, 300, 166)
	ci.draw_rect(b.grow(9), Color("7a3a1e"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "MENÚ DEL DÍA", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	for i in menu.size():
		text(ci, b.position + Vector2(18, 62 + i * 24), "• " + str(menu[i]), 16, Color("e9f0dc"), HORIZONTAL_ALIGNMENT_LEFT, 270)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(240, 14), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(450, 14), time)


## Frente del mostrador indio: madera tallada con un rangoli de colores
static func draw_counter_india(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	var front := Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18)
	ci.draw_rect(front, Color("7a3a1e"))
	for x in range(0, int(front.size.x), 200):
		var c := Vector2(front.position.x + x + 100, front.position.y + minf(80.0, front.size.y / 2.0))
		var cols := [Color("d0461e"), Color("f6d040"), Color("1f8a8a"), Color("e8507a")]
		for ring in 4:
			for k in 8:
				var a := k * TAU / 8.0 + ring * 0.2
				ci.draw_circle(c + Vector2.from_angle(a) * (44 - ring * 11), 9 - ring * 1.5, cols[ring])
		ci.draw_circle(c, 7, Color.WHITE)
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("c9a24a"), Color("8a6a1e"))
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.3))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


# --- Japón ---

## Pila de hojas de alga nori
static func draw_nori_stack(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	var w := rect.size.x * 0.7
	var h := rect.size.y * 0.5
	for k in 4:
		var off := Vector2(-k * 3, -k * 4)
		rrect(ci, Rect2(c - Vector2(w, h) / 2.0 + off + Vector2(4, 6), Vector2(w, h)), Color(0, 0, 0, 0.12), 3)
		rrect(ci, Rect2(c - Vector2(w, h) / 2.0 + off, Vector2(w, h)), Color("1d2a1e") if k % 2 == 0 else Color("24331f"), 3)
	ci.draw_line(c + Vector2(-w * 0.4, -h * 0.3 - 12), c + Vector2(w * 0.2, -h * 0.3 - 12), Color(1, 1, 1, 0.12), 2)


## Piezas de maki con su relleno
static func draw_maki(ci: CanvasItem, rect: Rect2, fillings: Array) -> void:
	var cols := {"Salmón": Color("f28a5a"), "Palta": Color("8ab83a"), "Pepino": Color("5a9a3a"), "Queso crema": Color("fbf6ea"), "Kanikama": Color("e8503a")}
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.17
	for k in 6:
		var p := c + Vector2.from_angle(k * TAU / 6.0) * r * 1.9
		ci.draw_circle(p + Vector2(1, 3), r, Color(0, 0, 0, 0.2))
		ci.draw_circle(p, r, Color("1d2a1e"))
		ci.draw_circle(p, r * 0.82, Color("fbfbf4"))
		for f in fillings.size():
			ci.draw_circle(p + Vector2.from_angle(f * TAU / maxf(fillings.size(), 1)) * r * 0.25 * float(fillings.size() > 1), r * 0.28, cols.get(fillings[f], Color.WHITE))
	# Jengibre y wasabi al costado
	ellipse(ci, c + Vector2(0, 0), Vector2(r * 0.5, r * 0.4), Color("8ab83a"))


## Salón de Sakura Ramen (Japón): madera clara, faroles de papel, noren en la puerta y el Fuji con cerezos
static func draw_dining_japon(ci: CanvasItem, rect: Rect2, menu: Array, time: float, decor: Array) -> void:
	var o := rect.position
	grad_rect(ci, rect, Color("f2e6cc"), Color("e2d2ae"))
	# Vigas y paneles de papel (shoji)
	for x in range(0, int(rect.size.x), 120):
		ci.draw_rect(Rect2(o.x + x, o.y, 8, 228), Color("8a6a42"))
	ci.draw_rect(Rect2(o.x, o.y + 12, rect.size.x, 8), Color("6b4a2a"))
	var z := Rect2(o.x, o.y + 228, rect.size.x, rect.size.y - 228)
	ci.draw_rect(z, Color("c8a46a"))
	for x in range(0, int(rect.size.x), 18):
		ci.draw_line(Vector2(o.x + x, z.position.y), Vector2(o.x + x, z.end.y), Color(0, 0, 0, 0.1), 2)
	ci.draw_rect(Rect2(o.x, o.y + 222, rect.size.x, 8), Color("6b4a2a"))
	# Puerta corrediza con la cortina noren y el cartel ABIERTO
	var d := Rect2(o.x + 30, o.y + 40, 150, 290)
	ci.draw_rect(d, Color("8a6a42"))
	ci.draw_rect(d.grow(-10), Color("f6f0e0"))
	for k in 4:
		ci.draw_line(Vector2(d.position.x + 10, d.position.y + 40 + k * 60), Vector2(d.end.x - 10, d.position.y + 40 + k * 60), Color("8a6a42"), 3)
	ci.draw_line(Vector2(d.get_center().x, d.position.y + 10), Vector2(d.get_center().x, d.end.y - 10), Color("8a6a42"), 3)
	for k in 3:
		var nr := Rect2(d.position.x + 6 + k * 46, d.position.y + 4, 44, 52)
		ci.draw_rect(nr, Color("1f3a6a"))
		ci.draw_circle(nr.position + Vector2(22, 30), 9, Color("f6f0e0"))
	rrect(ci, Rect2(d.position + Vector2(28, 64), Vector2(94, 30)), Color("c0281a"), 6, Color("f6e7c8"), 2)
	text(ci, d.position + Vector2(28, 85), "ABIERTO", 15, Color("f4efe0"), HORIZONTAL_ALIGNMENT_CENTER, 94)
	# Ventana redonda con el monte Fuji y un cerezo
	var wc := o + Vector2(520, 130)
	ci.draw_circle(wc, 96, Color("6b4a2a"))
	ci.draw_circle(wc, 88, Color("cfe6f6"))
	ci.draw_circle(wc + Vector2(36, -40), 14, Color("f28a5a"))
	ci.draw_colored_polygon(PackedVector2Array([wc + Vector2(-80, 50), wc + Vector2(-8, -36), wc + Vector2(8, -36), wc + Vector2(80, 50)]), Color("6a7a9a"))
	ci.draw_colored_polygon(PackedVector2Array([wc + Vector2(-20, -22), wc + Vector2(-8, -36), wc + Vector2(8, -36), wc + Vector2(20, -22), wc + Vector2(8, -18), wc + Vector2(0, -24), wc + Vector2(-8, -18)]), Color.WHITE)
	ci.draw_rect(Rect2(wc + Vector2(-88, 46), Vector2(176, 44)), Color("7aa85a"))
	ci.draw_arc(wc, 90, 0, TAU, 48, Color("6b4a2a"), 6)
	# Rama de cerezo que cruza
	var br := o + Vector2(620, 40)
	ci.draw_polyline(PackedVector2Array([br, br + Vector2(-60, 40), br + Vector2(-120, 50), br + Vector2(-170, 90)]), Color("5a3a2a"), 5)
	for k in 16:
		var p := br + Vector2(-k * 11, 6 + k * 4.5) + Vector2(sin(k * 2.1) * 10, cos(k * 1.7) * 8)
		for j in 5:
			ci.draw_circle(p + Vector2.from_angle(j * TAU / 5.0) * 4, 3.5, Color("f8c8d8"))
		ci.draw_circle(p, 2, Color("e8608a"))
	# Pétalos que caen
	for k in 6:
		var fy := fmod(time * 18.0 + k * 50.0, 200.0)
		ci.draw_circle(o + Vector2(470 + k * 30 + sin(time + k) * 12, 40 + fy), 2.5, Color(0.97, 0.78, 0.85, 1.0 - fy / 200.0))
	# Faroles de papel rojos
	for x in [700.0, 760.0, 820.0]:
		var lp := o + Vector2(x, 30)
		ci.draw_line(lp + Vector2(0, -20), lp, Color("3a2a1a"), 2)
		ellipse(ci, lp + Vector2(0, 24), Vector2(20, 26), Color("d0281a"))
		for k in 4:
			ci.draw_arc(lp + Vector2(0, 24), 20 - k * 0.5, PI * 0.15, PI * 0.85, 10, Color(0, 0, 0, 0.15), 1.5)
		rrect(ci, Rect2(lp + Vector2(-10, -2), Vector2(20, 5)), Color("2a1a10"), 2)
		rrect(ci, Rect2(lp + Vector2(-10, 48), Vector2(20, 5)), Color("2a1a10"), 2)
		ellipse(ci, lp + Vector2(0, 24), Vector2(10, 14), Color(1, 0.85, 0.4, 0.25 + 0.1 * sin(time * 3.0 + x)))
	# Pizarra con el menú
	var b := Rect2(o.x + 880, o.y + 52, 300, 166)
	ci.draw_rect(b.grow(9), Color("6b4a2a"))
	ci.draw_rect(b, Color("2c3a33"))
	text(ci, b.position + Vector2(0, 30), "MENÚ DEL DÍA", 20, Color("f4f1e6"), HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	for i in menu.size():
		text(ci, b.position + Vector2(18, 62 + i * 24), "• " + str(menu[i]), 16, Color("e9f0dc"), HORIZONTAL_ALIGNMENT_LEFT, 270)
	if "plantas" in decor:
		hanging_plant(ci, o + Vector2(240, 14), 0.8)
	if "ventilador" in decor:
		ceiling_fan(ci, o + Vector2(380, 14), time)


## Frente del mostrador japonés: listones de madera clara y una franja índigo
static func draw_counter_japon(ci: CanvasItem, rect: Rect2, top: float) -> void:
	var y := rect.position.y + top
	var front := Rect2(rect.position.x, y + 18, rect.size.x, rect.end.y - y - 18)
	ci.draw_rect(front, Color("d8b880"))
	for x in range(0, int(front.size.x), 24):
		ci.draw_line(Vector2(front.position.x + x, front.position.y), Vector2(front.position.x + x, front.end.y), Color("b8955a"), 3)
	ci.draw_rect(Rect2(front.position.x, front.position.y + 26, front.size.x, 22), Color("1f3a6a"))
	for x in range(30, int(front.size.x), 90):
		ci.draw_arc(Vector2(front.position.x + x, front.position.y + 37), 8, PI, TAU, 10, Color("f6f0e0"), 2)
	grad_rect(ci, Rect2(rect.position.x, y, rect.size.x, 20), Color("8a6a42"), Color("5a3a22"))
	ci.draw_rect(Rect2(rect.position.x, y + 3, rect.size.x, 2), Color(1, 1, 1, 0.25))
	ci.draw_rect(Rect2(rect.position.x, y + 20, rect.size.x, 6), Color(0, 0, 0, 0.3))


## Pegatina de papel con un nombre (en potes y botellas): la letra se achica si el nombre es largo
static func draw_sticker(ci: CanvasItem, rect: Rect2, s: String) -> void:
	rrect(ci, Rect2(rect.position + Vector2(1, 2), rect.size), Color(0, 0, 0, 0.18), 6)
	rrect(ci, rect, Color("fffdf6"), 6, Color("c9a86a"), 1)
	var font := ThemeDB.fallback_font
	var fs := 13
	while fs > 8 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect.size.x - 6:
		fs -= 1
	text(ci, Vector2(rect.position.x, rect.get_center().y + fs * 0.36), s, fs, INK, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


## Botella de salsa tipo pomo: grande, con pico, tapa y una gota del color de la salsa en la etiqueta
static func draw_sauce_bottle(ci: CanvasItem, rect: Rect2, col: Color) -> void:
	var c := rect.get_center()
	var h := rect.size.y * 0.92
	var w := minf(rect.size.x * 0.62, h * 0.5)
	var body := Rect2(c.x - w / 2.0, rect.end.y - h * 0.78, w, h * 0.78)
	ellipse(ci, Vector2(c.x + 2, rect.end.y), Vector2(w * 0.6, 4), Color(0, 0, 0, 0.2))
	# Pico y tapa
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 3, rect.end.y - h), Vector2(c.x + 3, rect.end.y - h),
		Vector2(c.x + w * 0.18, body.position.y - h * 0.06), Vector2(c.x - w * 0.18, body.position.y - h * 0.06)]), col.darkened(0.25))
	rrect(ci, Rect2(c.x - w * 0.32, body.position.y - h * 0.08, w * 0.64, h * 0.1), col.darkened(0.35), 3)
	# Cuerpo con brillo
	rrect(ci, body, col, w * 0.28, col.darkened(0.35), 2)
	rrect(ci, Rect2(body.position + Vector2(w * 0.12, h * 0.05), Vector2(w * 0.14, body.size.y * 0.75)), Color(1, 1, 1, 0.3), 4)
	# Etiqueta blanca con una gota de la salsa
	var lab := Rect2(body.position.x + w * 0.1, body.position.y + body.size.y * 0.38, w * 0.8, body.size.y * 0.36)
	rrect(ci, lab, Color("fffdf6"), 4)
	var d := lab.get_center() + Vector2(0, lab.size.y * 0.08)
	var dr := lab.size.y * 0.3
	ci.draw_circle(d, dr, col if col.v < 0.93 else col.darkened(0.15))
	ci.draw_colored_polygon(PackedVector2Array([d + Vector2(-dr * 0.85, -dr * 0.45), d + Vector2(0, -dr * 2.0), d + Vector2(dr * 0.85, -dr * 0.45)]),
		col if col.v < 0.93 else col.darkened(0.15))


## Mejoras caras del salón que se ven en todos los locales: lámparas de diseño y el pianista (notas que flotan)
static func draw_salon_decor(ci: CanvasItem, rect: Rect2, decor: Array, time: float) -> void:
	var o := rect.position
	if "lamparas" in decor:
		for x in [560.0, 760.0]:
			var top := o + Vector2(x, 14)
			ci.draw_line(top, top + Vector2(0, 40), Color("8a6a1e"), 2)
			var c := top + Vector2(0, 52)
			ci.draw_circle(c, 32, Color(1, 0.85, 0.45, 0.12 + 0.03 * sin(time * 2.0 + x)))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 4), c + Vector2(22, 4), c + Vector2(12, -12), c + Vector2(-12, -12)]), Color("c9a24a"))
			for k in 3:
				var b := c + Vector2((k - 1) * 14, 10)
				ci.draw_circle(b, 5, Color(1, 0.92, 0.6))
	if "pianista" in decor:
		# Notas musicales que suben despacio
		for k in 4:
			var ph := fmod(time * 0.25 + k * 0.25, 1.0)
			var p := o + Vector2(880 + k * 70 + sin(time + k) * 10, 210 - ph * 160)
			var col := Color(0.25, 0.15, 0.08, 0.7 * (1.0 - ph))
			ellipse(ci, p, Vector2(6, 4.5), col)
			ci.draw_line(p + Vector2(5, 0), p + Vector2(5, -18), col, 2)
			if k % 2 == 0:
				ci.draw_line(p + Vector2(5, -18), p + Vector2(13, -13), col, 2)
