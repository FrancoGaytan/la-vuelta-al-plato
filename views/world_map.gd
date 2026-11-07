extends Control
## Mapamundi del modo historia: se arrastra para moverse, se hace zoom y un avioncito viaja entre los locales.
## Avisa con city_selected(id) cuando el avión llega a una ciudad (o se toca la ciudad donde ya está).

signal city_selected(id: String)

const Art = preload("res://art.gd")
const Data = preload("res://data.gd")

const MW := 2600.0          # tamaño del mapa (coordenadas del mundo)
const MH := 1300.0
const LAT_TOP := 80.0
const LAT_BOTTOM := -60.0

# Contornos simplificados de los continentes [longitud, latitud]
const LANDS := {
	"sudamerica": [[-80, 10], [-75, 11], [-62, 10.5], [-52, 4], [-50, 0], [-44, -2], [-35, -7], [-39, -15], [-41, -22],
		[-48, -28], [-53, -34], [-57.5, -38], [-62, -39], [-65, -45], [-68, -51], [-70, -54], [-74, -51], [-74, -43],
		[-72, -31], [-71, -18], [-76, -12], [-81, -5], [-80, 0], [-78, 2], [-77, 7]],
	"norteamerica": [[-168, 66], [-162, 70], [-140, 70], [-120, 72], [-95, 72], [-80, 68], [-62, 60], [-56, 52],
		[-66, 45], [-70, 42], [-76, 36], [-81, 30], [-80, 25], [-83, 29], [-90, 30], [-97, 26], [-97, 20], [-91, 18.5],
		[-87, 21], [-88, 16], [-83.5, 15], [-83.5, 11], [-79, 9.3], [-77.5, 8.2], [-80, 7.4], [-85, 9.8], [-87.5, 13],
		[-92, 15], [-105, 20], [-110, 24], [-115, 30],
		[-118, 34], [-123, 38], [-124, 46], [-130, 54], [-140, 60], [-152, 58], [-165, 60]],
	"groenlandia": [[-55, 60], [-42, 60], [-20, 70], [-20, 80], [-40, 83], [-60, 80], [-70, 77], [-55, 70]],
	"europa": [[-9, 37], [-9, 43], [-2, 43.5], [-4.5, 48], [-1, 49.5], [2, 51], [5, 53], [8, 54], [9, 55], [10, 54],
		[14, 54], [20, 55], [22, 58], [28, 60], [30, 62], [40, 66], [44, 68], [55, 69], [60, 68], [60, 46], [50, 46],
		[40, 46], [37, 47], [30, 46], [29, 42], [26, 40], [23, 40], [24, 37], [22, 37], [20, 40], [19, 42], [16, 44],
		[13.7, 45.6], [12.3, 45.4], [14, 42], [16, 41.5], [18.5, 40], [16, 38], [15.6, 40], [12, 41.8], [10, 43.5],
		[8.5, 44.4], [6, 43], [3, 43], [3, 42], [0, 39], [-2, 37], [-6, 36]],
	"escandinavia": [[5, 58], [8, 58], [11, 59], [12, 56], [14, 56], [16, 57], [18, 60], [20, 63], [24, 66], [28, 70],
		[22, 71], [15, 69], [12, 66], [8, 63], [5, 61]],
	"britania": [[-5, 50], [1, 51], [2, 53], [-1, 55], [-3, 58], [-6, 58], [-5, 54], [-3, 52]],
	"africa": [[-17, 21], [-16, 13], [-12, 7], [-4, 5], [8, 4], [10, 0], [12, -6], [13, -12], [12, -18], [15, -27],
		[18, -34], [25, -34], [32, -28], [35, -20], [40, -15], [40, -5], [43, 0], [51, 11], [43, 12], [38, 18], [33, 27],
		[32, 31], [20, 32], [10, 37], [-6, 36], [-10, 30], [-15, 27]],
	"asia": [[60, 68], [70, 72], [80, 73], [95, 76], [110, 76], [130, 72], [150, 71], [170, 69], [180, 66], [178, 62],
		[165, 60], [160, 54], [150, 59], [142, 53], [140, 47], [135, 43], [130, 42], [126, 38], [127, 35], [122, 31],
		[121, 25], [115, 22], [109, 21], [108, 16], [109, 12], [105, 9], [103, 11], [100, 13], [99, 8], [103, 2],
		[101, 3], [98, 8], [98, 15], [94, 17], [92, 21], [89, 22], [86, 20], [80, 15], [80, 10], [77, 8], [73, 16],
		[72, 21], [68, 23], [62, 25], [57, 25], [56, 27], [52, 27], [50, 30], [48, 29], [51, 24], [56, 24], [59, 22],
		[55, 17], [52, 15], [45, 13], [43, 15], [40, 20], [37, 25], [34, 28], [35, 32], [36, 36], [30, 36], [27, 37],
		[26, 40], [30, 41], [38, 41], [42, 42], [48, 43], [48, 47], [52, 47], [55, 45], [60, 46], [60, 52], [57, 57],
		[60, 62]],
	"japon": [[130, 33], [135, 34], [141, 37], [142, 43], [145, 44], [141, 45], [139, 40], [136, 36], [131, 34]],
	"australia": [[114, -22], [122, -17], [130, -12], [137, -12], [142, -11], [145, -15], [150, -22], [153, -28],
		[150, -37], [144, -39], [138, -35], [130, -32], [115, -34], [113, -26]],
	"madagascar": [[44, -16], [50, -15], [50, -20], [47, -25], [44, -22]],
	"indonesia": [[95, 5], [100, 0], [106, -6], [114, -8], [119, -8], [110, -5], [104, -2], [98, 3]],
	"borneo": [[109, 1], [114, 5], [119, 6], [118, 1], [116, -4], [110, -3]],
	"nuevazelanda": [[172, -34], [178, -38], [174, -42], [170, -46], [167, -46], [172, -41]],
	"cuba": [[-85, 22], [-80, 23], [-74, 20], [-78, 20]],
	"islandia": [[-24, 65], [-18, 66.5], [-13, 65], [-18, 63.5]],
}

# Decorados [lon, lat]
const MOUNTAINS := [[-70, -30], [-69, -22], [-72, -40], [-110, 42], [-114, 47], [-106, 38], [10, 46.5], [85, 29],
	[90, 30], [80, 31], [-5, 32], [37, -3], [44, 40], [100, 35]]
const FORESTS := [[-60, -5], [-55, -9], [-66, -2], [-100, 56], [-88, 52], [-115, 58], [100, 62], [120, 60], [80, 60],
	[20, 0], [25, -5], [28, 60], [145, -18]]
const DUNES := [[5, 24], [20, 22], [12, 28], [45, 22], [130, -25]]

var cam := Vector2.ZERO        # esquina de arriba a la izquierda de la vista, en coordenadas del mapa
var zoom := 0.62
var home := "argentina"        # donde está el avión
var owned: Array = ["argentina"]
var info := {}                 # id -> {"rep": %, "stars": n}

var _lands := []               # polígonos ya proyectados (con la costa un poco irregular)
var _drag_from = null
var _dragged := false
var _travel_to := ""
var _travel_t := 0.0
var _plane := Vector2.ZERO
var _plane_angle := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _ready() -> void:
	_build_lands()
	_plane = city_pos(home)
	center_on(_plane, false)


## Longitud/latitud -> coordenadas del mapa
static func project(lon: float, lat: float) -> Vector2:
	return Vector2((lon + 180.0) / 360.0 * MW, (LAT_TOP - lat) / (LAT_TOP - LAT_BOTTOM) * MH)


func city_pos(id: String) -> Vector2:
	var c: Dictionary = Data.COUNTRIES[id]
	return project(c["lon"], c["lat"])


func _build_lands() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for key in LANDS:
		var raw: Array = LANDS[key]
		var pts := PackedVector2Array()
		for k in raw.size():
			var a: Vector2 = project(raw[k][0], raw[k][1])
			var b: Vector2 = project(raw[(k + 1) % raw.size()][0], raw[(k + 1) % raw.size()][1])
			pts.append(a)
			# Subdivide la costa y la hace un poco irregular (más natural)
			var steps := int(a.distance_to(b) / 14.0)
			for s in steps:
				var f := float(s + 1) / (steps + 1)
				var n := Vector2(-(b - a).y, (b - a).x).normalized()
				pts.append(a.lerp(b, f) + n * rng.randf_range(-2.0, 2.0))
		if Geometry2D.triangulate_polygon(pts).is_empty():
			# Si la versión irregular quedó cruzada, se usa la simple
			pts = PackedVector2Array()
			for p in raw:
				pts.append(project(p[0], p[1]))
		_lands.append(pts)


# --- Cámara ---

func center_on(p: Vector2, smooth := true) -> void:
	var target := p - size / zoom / 2.0
	if smooth:
		cam = cam.lerp(target, 0.12)
	else:
		cam = target
	_clamp_cam()


func _clamp_cam() -> void:
	var view := size / zoom
	cam.x = clampf(cam.x, -60.0, maxf(-60.0, MW - view.x + 60.0))
	cam.y = clampf(cam.y, -40.0, maxf(-40.0, MH - view.y + 40.0))


func zoom_at(screen_p: Vector2, factor: float) -> void:
	var world_before := cam + screen_p / zoom
	zoom = clampf(zoom * factor, 0.42, 1.6)
	cam = world_before - screen_p / zoom
	_clamp_cam()


func to_screen(p: Vector2) -> Vector2:
	return (p - cam) * zoom


# --- Viajar ---

func travel_to(id: String) -> void:
	if id == home:
		city_selected.emit(id)
		return
	_travel_to = id
	_travel_t = 0.0


func _travel_point(t: float) -> Vector2:
	var a := city_pos(home)
	var b := city_pos(_travel_to)
	var mid := (a + b) / 2.0 - Vector2(0, a.distance_to(b) * 0.28)
	return a.lerp(mid, t).lerp(mid.lerp(b, t), t)


func _process(delta: float) -> void:
	if _travel_to != "":
		var dist := city_pos(home).distance_to(city_pos(_travel_to))
		_travel_t = minf(_travel_t + delta / clampf(dist / 650.0, 1.0, 2.4), 1.0)
		var p := _travel_point(_travel_t)
		var ahead := _travel_point(minf(_travel_t + 0.02, 1.0))
		if ahead.distance_to(p) > 0.1:
			_plane_angle = (ahead - p).angle()
		_plane = p
		center_on(_plane)
		if _travel_t >= 1.0:
			home = _travel_to
			_travel_to = ""
			city_selected.emit(home)
	# Moverse con el teclado
	var move := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_key_pressed(KEY_A): move.x -= 1
	if Input.is_key_pressed(KEY_D): move.x += 1
	if Input.is_key_pressed(KEY_W): move.y -= 1
	if Input.is_key_pressed(KEY_S): move.y += 1
	if move != Vector2.ZERO and _travel_to == "":
		cam += move.normalized() * 600.0 * delta / zoom
		_clamp_cam()
	queue_redraw()


# --- Mouse / dedo ---

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, 1.12)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, 1.0 / 1.12)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_from = mb.position
				_dragged = false
			else:
				if not _dragged and _travel_to == "":
					var id := _city_at(mb.position)
					if id != "":
						travel_to(id)
				_drag_from = null
		accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		if _drag_from != null and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			if (mm.position - _drag_from).length() > 6.0:
				_dragged = true
			if _dragged and _travel_to == "":
				cam -= mm.relative / zoom
				_clamp_cam()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _city_at(mm.position) != "" else Control.CURSOR_DRAG
	var mg := event as InputEventMagnifyGesture
	if mg != null:
		zoom_at(mg.position, mg.factor)


func _city_at(screen_p: Vector2) -> String:
	for id in Data.COUNTRY_ORDER:
		if to_screen(city_pos(id)).distance_to(screen_p) < 44.0 * maxf(zoom, 0.7):
			return id
	return ""


# =====================================================================
# Dibujo
# =====================================================================

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# Mar con degradé y olitas que se mueven
	Art.grad_rect(self, Rect2(Vector2.ZERO, size), Color("5fb0c9"), Color("2f7f9f"))
	draw_set_transform(-cam * zoom, 0.0, Vector2(zoom, zoom))
	for k in 160:
		var p := Vector2(fmod(k * 397.0, MW), fmod(k * 173.0, MH))
		var drift := Vector2(sin(t * 0.5 + k) * 6.0, 0)
		draw_arc(p + drift, 9, PI * 1.15, PI * 1.85, 6, Color(1, 1, 1, 0.22), 2.0)
		draw_arc(p + drift + Vector2(18, 0), 9, PI * 1.15, PI * 1.85, 6, Color(1, 1, 1, 0.14), 2.0)
	# Paralelos y meridianos punteados
	for lat in [-40, -20, 0, 20, 40, 60]:
		var y := project(0, lat).y
		for x in range(0, int(MW), 28):
			draw_line(Vector2(x, y), Vector2(x + 12, y), Color(1, 1, 1, 0.18 if lat != 0 else 0.35), 2.0)
	for lon in range(-150, 180, 30):
		var x := project(lon, 0).x
		for y in range(0, int(MH), 28):
			draw_line(Vector2(x, y), Vector2(x, y + 12), Color(1, 1, 1, 0.12), 2.0)
	# Continentes: sombra, costa con espuma, tierra y relieve
	for pts in _lands:
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(4, 6))
		draw_colored_polygon(shadow, Color(0.05, 0.2, 0.3, 0.35))
	for pts in _lands:
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(1, 1, 1, 0.45), 9.0, true)
		draw_colored_polygon(pts, Color("e9d9a6"))
		draw_polyline(closed, Color("b89a5e"), 2.5, true)
	for p in DUNES:
		var c := project(p[0], p[1])
		for d in 3:
			draw_arc(c + Vector2(d * 14 - 14, d * 6), 14, PI * 1.1, PI * 1.9, 8, Color("d2b26a"), 2.5)
	for p in FORESTS:
		var c := project(p[0], p[1])
		for d in 5:
			var q := c + Vector2((d % 3) * 13 - 13, (d / 3) * 11 - 5)
			draw_circle(q, 7, Color("5d9a4a"))
			draw_circle(q + Vector2(-2, -2), 3, Color("7fbf62"))
	for p in MOUNTAINS:
		var c := project(p[0], p[1])
		for d in 2:
			var q := c + Vector2(d * 16 - 8, d * 4)
			draw_colored_polygon(PackedVector2Array([q + Vector2(-14, 10), q + Vector2(0, -14), q + Vector2(14, 10)]), Color("a08868"))
			draw_colored_polygon(PackedVector2Array([q + Vector2(-5, -5), q + Vector2(0, -14), q + Vector2(5, -5)]), Color.WHITE)
	# Pirámides en Egipto
	var egypt := project(31, 27)
	for d in 2:
		var q := egypt + Vector2(d * 18, d * 3)
		draw_colored_polygon(PackedVector2Array([q + Vector2(-12, 8), q + Vector2(0, -10), q + Vector2(12, 8)]), Color("d9b66a"))
		draw_line(q + Vector2(0, -10), q + Vector2(12, 8), Color("b08a42"), 2)
	_draw_life(t)
	_draw_routes(t)
	for id in Data.COUNTRY_ORDER:
		_draw_city(id, t)
	_draw_plane(t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_compass(Vector2(70, size.y - 80))


## Barquito, ballena y nubes que le dan vida al mapa
func _draw_life(t: float) -> void:
	# Barco que cruza el Atlántico
	var u := fmod(t * 0.02, 1.0)
	var ship := project(-40 + u * 30, -25 + u * 40)
	var bob := sin(t * 2.0) * 2.0
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-16, bob), ship + Vector2(16, bob), ship + Vector2(11, 8 + bob), ship + Vector2(-11, 8 + bob)]), Color("8a4a24"))
	draw_line(ship + Vector2(0, bob), ship + Vector2(0, -24 + bob), Color("5a3a22"), 2)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(1, -22 + bob), ship + Vector2(15, -4 + bob), ship + Vector2(1, -4 + bob)]), Color("fdf6e3"))
	draw_arc(ship + Vector2(-22, 6), 6, 0, PI, 6, Color(1, 1, 1, 0.5), 1.5)
	# Ballena en el Pacífico que tira agua
	var whale := project(-135, -22)
	Art.ellipse(self, whale, Vector2(26, 10), Color("3a5f7a"))
	draw_colored_polygon(PackedVector2Array([whale + Vector2(22, -2), whale + Vector2(36, -12), whale + Vector2(34, 4)]), Color("3a5f7a"))
	draw_circle(whale + Vector2(-14, -2), 2, Color.WHITE)
	var spout := fmod(t * 0.7, 1.0)
	if spout < 0.5:
		for k in 5:
			var a := -PI / 2.0 + (k - 2) * 0.35
			draw_circle(whale + Vector2(-6, -10) + Vector2.from_angle(a) * spout * 30.0, 3.0 * (1.0 - spout), Color(1, 1, 1, 0.8))
	# Nubes que pasan
	for k in 6:
		var cx := fmod(k * 470.0 + t * (10.0 + k * 2.0), MW + 300.0) - 150.0
		var cy := 120.0 + fmod(k * 263.0, MH - 240.0)
		for b in 4:
			draw_circle(Vector2(cx + b * 22, cy + (b % 2) * -8), 22 - (b % 2) * 4, Color(1, 1, 1, 0.42))


func _draw_routes(t: float) -> void:
	var a := city_pos(home)
	for id in Data.COUNTRY_ORDER:
		if id == home:
			continue
		var b := city_pos(id)
		var mid := (a + b) / 2.0 - Vector2(0, a.distance_to(b) * 0.28)
		var col := Color(1, 1, 1, 0.55) if Data.COUNTRIES[id]["ready"] else Color(0.3, 0.2, 0.15, 0.35)
		var n := 34
		for k in n:
			if (k + int(t * 4.0)) % 2 == 0:
				var f0 := float(k) / n
				var f1 := float(k + 1) / n
				var p0 := a.lerp(mid, f0).lerp(mid.lerp(b, f0), f0)
				var p1 := a.lerp(mid, f1).lerp(mid.lerp(b, f1), f1)
				draw_line(p0, p1, col, 3.0)


func _draw_city(id: String, t: float) -> void:
	var c: Dictionary = Data.COUNTRIES[id]
	var p := city_pos(id)
	var mine: bool = id in owned
	var ready: bool = c["ready"]
	var k := 1.0 / maxf(zoom, 0.6)    # los íconos no se achican tanto al alejarse
	# Pin con sombra y un pequeño rebote en el local actual
	var lift := sin(t * 3.0) * 3.0 if id == home else 0.0
	Art.ellipse(self, p + Vector2(0, 4), Vector2(20, 7) * k, Color(0, 0, 0, 0.3))
	var base := p + Vector2(0, -6 + lift) * k
	# Local: casita con toldo de los colores de la bandera
	var w := 40.0 * k
	var h := 30.0 * k
	var house := Rect2(base.x - w / 2.0, base.y - h, w, h)
	Art.rrect(self, house, Color("fdf6e3") if (mine or ready) else Color("b9b2a3"), 3 * k, Color("6e4527"), 2)
	var cols: Array = c["flag"][1]
	for s in 6:
		var col: Color = cols[s % cols.size()]
		var sx := house.position.x - 3 * k + s * (w + 6 * k) / 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, house.position.y - 2 * k), Vector2(sx + (w + 6 * k) / 6.0, house.position.y - 2 * k),
			Vector2(sx + (w + 6 * k) / 6.0, house.position.y + 7 * k), Vector2(sx, house.position.y + 7 * k)]), col if (mine or ready) else col.darkened(0.4))
	draw_rect(Rect2(base.x - 6 * k, base.y - 14 * k, 12 * k, 14 * k), Color("8a5a34"))
	draw_rect(Rect2(house.position.x + 4 * k, base.y - 22 * k, 8 * k, 7 * k), Color("bfe3f2"))
	draw_rect(Rect2(house.end.x - 12 * k, base.y - 22 * k, 8 * k, 7 * k), Color("bfe3f2"))
	# Banderita en el techo
	var pole := Vector2(house.end.x - 4 * k, house.position.y - 2 * k)
	draw_line(pole, pole + Vector2(0, -22) * k, Color("5a3a22"), 2)
	_draw_flag(Rect2(pole + Vector2(0, -22) * k, Vector2(16, 11) * k), c["flag"], t)
	if not mine and not ready:
		# Candado: todavía no se puede abrir
		var lk := base + Vector2(0, -h * 0.5)
		draw_arc(lk + Vector2(0, -4) * k, 5 * k, PI, TAU, 10, Color("4a4a4a"), 2.5)
		Art.rrect(self, Rect2(lk + Vector2(-7, -4) * k, Vector2(14, 11) * k), Color("e3b84a"), 2 * k)
	# Cartel con el nombre
	var label: String = c["city"]
	var font := ThemeDB.fallback_font
	var fs := int(15 * k)
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16 * k
	var plate := Rect2(p.x - tw / 2.0, p.y + 8 * k, tw, 22 * k)
	if c.get("label_left", false):
		# Ciudades muy cerca de otra (París y Roma): el cartel va al costado
		plate.position = Vector2(p.x - w / 2.0 - tw - 6 * k, p.y - 36 * k)
	Art.rrect(self, plate, Color(0.12, 0.09, 0.07, 0.82), 6 * k)
	Art.text(self, Vector2(plate.position.x, plate.position.y + 16 * k), label, fs, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, tw)
	var st: int = info.get(id, {}).get("stars", 0)
	if mine:
		Art.stars(self, Vector2(p.x, plate.end.y + 10 * k), 6 * k, st)
	elif not ready:
		var r2 := Rect2(p.x - 44 * k, plate.end.y + 3 * k, 88 * k, 16 * k)
		Art.rrect(self, r2, Color("c8463c"), 4 * k)
		Art.text(self, Vector2(r2.position.x, r2.position.y + 12 * k), "PRÓXIMAMENTE", int(10 * k), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)


func _draw_flag(r: Rect2, flag: Array, t: float) -> void:
	Art.draw_flag(self, r, flag, t)


func _draw_plane(t: float) -> void:
	var p := _plane
	var flying := _travel_to != ""
	var alt := sin(_travel_t * PI) * 26.0 if flying else 0.0
	var ang := _plane_angle if flying else -0.3
	var k := 1.0 / maxf(zoom, 0.6)
	if not flying:
		p = city_pos(home) + Vector2(34, -48) * k + Vector2(0, sin(t * 2.0) * 3.0)
	# Sombra en el piso cuando vuela
	if flying:
		Art.ellipse(self, p + Vector2(0, alt * 0.8 + 10), Vector2(16, 5) * k, Color(0, 0, 0, 0.25))
	var c := p - Vector2(0, alt)
	draw_set_transform(-cam * zoom + c * zoom, ang, Vector2(zoom * k, zoom * k))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -3), Vector2(16, -3), Vector2(22, 0), Vector2(16, 3), Vector2(-18, 3)]), Color("fdf6e3"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -3), Vector2(-10, -18), Vector2(-4, -18), Vector2(8, -3)]), Color("d9534a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 3), Vector2(-10, 18), Vector2(-4, 18), Vector2(8, 3)]), Color("d9534a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -3), Vector2(-22, -10), Vector2(-15, -3)]), Color("d9534a"))
	draw_circle(Vector2(14, 0), 1.6, Color("2f6f8f"))
	draw_set_transform(-cam * zoom, 0.0, Vector2(zoom, zoom))


## Rosa de los vientos (fija en la pantalla)
func _draw_compass(c: Vector2) -> void:
	draw_circle(c, 46, Color(0.99, 0.96, 0.89, 0.85))
	draw_arc(c, 46, 0, TAU, 40, Color("8a5a2b"), 3)
	draw_arc(c, 38, 0, TAU, 40, Color("c9a86a"), 1.5)
	for k in 8:
		var a := -PI / 2.0 + k * PI / 4.0
		var length := 36.0 if k % 2 == 0 else 22.0
		var d := Vector2.from_angle(a)
		var n := Vector2(-d.y, d.x) * (6.0 if k % 2 == 0 else 4.0)
		draw_colored_polygon(PackedVector2Array([c + n, c + d * length, c - n]), Color("c8463c") if k == 0 else Color("3b2414"))
	draw_circle(c, 5, Color("e3b84a"))
	Art.text(self, c + Vector2(-8, -50), "N", 16, Color("3b2414"), HORIZONTAL_ALIGNMENT_CENTER, 16)
