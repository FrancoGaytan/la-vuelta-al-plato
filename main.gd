extends Control
## Viandas — juego de cocina por estaciones.
## Flujo: Pedidos -> Cocina (medir tiempos) -> Tabla (cortar) -> Emplatado -> Entrega (puntaje).
## Datos en data.gd · Arte en art.gd y assets/ · Piezas visuales en views/.

const Data = preload("res://data.gd")
const Art = preload("res://art.gd")
const Painter = preload("res://views/painter.gd")
const PropButton = preload("res://views/prop_button.gd")
const CustomerView = preload("res://views/customer_view.gd")
const ApplianceView = preload("res://views/appliance_view.gd")
const BoardView = preload("res://views/board_view.gd")
const PlateView = preload("res://views/plate_view.gd")
const MesaView = preload("res://views/pizza_mesa_view.gd")
const SinkView = preload("res://views/sink_view.gd")
const RackView = preload("res://views/rack_view.gd")
const TrashView = preload("res://views/trash_view.gd")
const WorldMap = preload("res://views/world_map.gd")

const STATIONS := ["Pedidos", "Cocina", "Tabla", "Emplatado", "Entrega", "Bacha"]
const TAB_ICONS := ["kitchen/notepad", "kitchen/pot", "kitchen/board", "kitchen/plate", "kitchen/bell", "kitchen/sponge"]
const NAMES := ["Marta", "Rulo", "Doña Elsa", "Tano", "Vicky", "Pocho", "Lula", "Beto", "Chela", "Nacho",
	"Cachi", "Mirta", "Gonza", "Rocío", "Don Aldo", "Flor"]
const MAX_ACTIVE := 6
const SAVE_PATH := "user://progreso.cfg"
var save_path := SAVE_PATH   # las pruebas automáticas usan otro archivo para no tocar tu progreso
const DOOR_X := 105.0
const WAITER_X := 790.0      # dónde está parada la moza del mostrador
const WALK_SPEED := 240.0
const STATION_SIZE := Vector2(1280, 466)

const COL_BG := Color("2b2420")
const COL_PAPER := Color("fdf6e3")
const COL_SELECTED := Color("ffd166")
const COL_INK := Color("3b2414")

var rng := RandomNumberGenerator.new()

# --- Progreso guardado ---
var unlocked_level := 0
var best_scores := {}
var savings := 0             # ahorros: lo ganado en los días, para gastar en la tienda
var country_progress := {}   # por país: {desbloqueado, mejores, estrellas}
var owned_countries: Array = ["argentina"]
var current_country := "argentina"
var world_map = null
var owned: Array = []        # mejoras compradas

# --- Estado del día ---
var level_idx := 0
var level: Dictionary = {}
var recipes: Array = []      # recetas habilitadas en este día
var playing := false
var elapsed := 0.0
var spawn_timer := 0.0
var spawned := 0
var served := 0
var lost := 0                # clientes que se fueron sin comer
var score_sum := 0.0
var money := 0
var next_id := 1
var queue: Array = []        # clientes en el mostrador: {name, arrived, look, x}
var walkers: Array = []      # clientes que ya pidieron y se van a sentar: {look, x, bubble}
var orders: Array = []       # pedidos tomados (ver _take_order)
var cookers := {}            # aparato -> Array de null o {item, t, target, burn}
var board = null             # tabla: null o {item, cuts, need}
var prepared: Array = []     # bandeja compartida: lo cocinado/cortado sirve para cualquier plato
var music_on := true
var music: AudioStreamPlayer
var music_button: Button
var sfx_on := true
var sfx_button: Button
var cook_players := {}       # "aparato:lugar" -> AudioStreamPlayer (un sonido por cada cosa cocinándose)
var cook_streams := {}

# Sonido de cada aparato: archivo y volumen base (dB) de cada cosa que se cocina
const COOK_SFX := {
	"olla": ["res://assets/sfx/hervor.wav", -17.0],
	"plancha": ["res://assets/sfx/chisporroteo.wav", -16.0],
	"freidora": ["res://assets/sfx/freidora.wav", -16.0],
	"horno": ["res://assets/sfx/horno.wav", -21.0],
}

# Sonidos sueltos: archivo y volumen (dB)
const ONE_SHOTS := {
	"caja": ["res://assets/sfx/caja.wav", -15.0],          # el cliente paga
	"campanita": ["res://assets/sfx/campanita.wav", -13.0], # entra un cliente
	"puerta": ["res://assets/sfx/puerta.wav", -18.0],       # cierra el local
	"enojo": ["res://assets/sfx/enojo.wav", -21.0],        # un cliente se empieza a enojar (sutil)
	"enojo2": ["res://assets/sfx/enojo2.wav", -21.0],
	"timbre": ["res://assets/sfx/timbre.wav", -13.0],     # algo llegó a su punto (mejora)
	"birome": ["res://assets/sfx/birome.wav", -15.0],     # la moza anota el pedido
	"persiana": ["res://assets/sfx/persiana.wav", -17.0], # sube la persiana al abrir el día
	"salero": ["res://assets/sfx/salero.wav", -20.0],     # sacudir el salero
	"corte1": ["res://assets/sfx/corte1.wav", -16.0],     # cuchillo en la tabla (sutil)
	"frotar": ["res://assets/sfx/frotar.wav", -18.0],     # esponja en la bacha
	"detergente": ["res://assets/sfx/detergente.wav", -16.0], # botella de detergente
	"chapoteo": ["res://assets/sfx/chapoteo.wav", -16.0],   # algo cae al agua de la pileta
	"plato": ["res://assets/sfx/plato.wav", -15.0],         # loza que se apoya
	"platos": ["res://assets/sfx/platos.wav", -14.0],       # se apilan los platos sucios (aviso)
	"corte2": ["res://assets/sfx/corte2.wav", -16.0],
	"corte3": ["res://assets/sfx/corte3.wav", -16.0],
}
var one_shot_streams := {}
var hint_label: Label = null
var paused := false
var pause_button: Button
# Desparramar toppings: se mantiene apretado el bowl y se pasa por arriba de la comida
var sprinkle_name := ""
var sprinkle_used := 0.0         # segundos que estuvo desparramando de verdad (sobre la comida)
var sprinkle_timer := 0.0
var sprinkle_cursor: Control = null
var plating_plate = null         # el PlateView del emplatado (para saber dónde está el plato)
var recipe_panel: Control = null
var kitchen_views: Array = []        # aparatos dibujados en la cocina (para saber dónde está el salero)
var salting := false
var salt_cursor: Control = null
var salt_sound_t := 0.0
# Lavado
var clean_stock := {}                # utensilio -> cuántos limpios quedan
var dirty: Array = []                # utensilios sucios (por tipo, uno por elemento)
var sink_item = null                 # lo que está en la pileta {kind, dirt, foam, seed}
var water_on := false
var scrubbing := false
var scrub_cursor: Control = null
var scrub_last := Vector2.ZERO
var scrub_sound_t := 0.0
var sink_view = null
var rack_view = null
var rack_recent: Array = []
var water_player: AudioStreamPlayer = null
var dishwasher_t := 0.0
var water_flow := 0.0                 # el grifo abre de a poco (0-1)
var sink_pool := 0.0                  # agua juntada en el fondo de la pileta
var sponge_soap := 0.0                # detergente en la esponja
var soap_warned := false
var scrub_speed := 0.0
var wash_alert := 0                   # 0 ok, 1 se apilan, 2 urgente
var wash_alert_t := 0.0
var tool_uses_left := {}              # utensilio en uso -> cuántos usos le quedan antes de ir a lavar
var tool_clean_now := {}              # si el que está en uso salió limpio
var tool_last := false
var closing := false                  # ya se atendió a todos: falta lavar y cerrar
var closing_t := 0.0                  # segundos que quedan para lavar antes de que cierre solo
var close_button: Button = null
var mesa_pizza = null                # Italia: la pizza que se está armando en la mesa {stretch, sauce, sprinkles, plate_toppings}
var mesa_view = null
var pending_order: Dictionary = {}   # pedido que la moza está anotando
var pending_timer := 0.0
var waiter_look: Dictionary = {}
var selected_id := -1
var current_station := 0
var last_result := {}

# --- UI ---
var lbl_level: Label
var lbl_customers: Label
var lbl_money: Label
var ticket_rail: HBoxContainer
var station_box: Control
var tab_buttons: Array = []
var ticket_labels := {}
var ticket_heads := {}
var customer_views: Array = []   # {src, v, queued}
var take_button: Control = null
var board_view = null
var board_info: Label = null
var overlay: Control = null


func _ready() -> void:
	rng.randomize()
	theme = _make_theme()
	_load_progress()
	_build_ui()
	_setup_music()
	_show_title()


# =====================================================================
# Música
# =====================================================================

func _setup_music() -> void:
	music = AudioStreamPlayer.new()
	music.volume_db = -11.0
	add_child(music)
	music.stream = _looped("res://assets/music/lounge.wav")
	if music_on and music.stream != null:
		music.play()
	_update_music_button()
	for a in COOK_SFX:
		cook_streams[a] = _looped(COOK_SFX[a][0])
	for s in ONE_SHOTS:
		if ResourceLoader.exists(ONE_SHOTS[s][0]):
			one_shot_streams[s] = load(ONE_SHOTS[s][0])


func _play_sfx(name: String, extra_db := 0.0) -> void:
	if not sfx_on or not one_shot_streams.has(name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = one_shot_streams[name]
	p.volume_db = ONE_SHOTS[name][1] + extra_db
	p.pitch_scale = rng.randf_range(0.96, 1.04)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Cuando un cliente pasa a "molesto" o a "enojado" hace un murmullo de fastidio y suelta un comentario
## (una sola vez por estado). Si espera demasiado, se va.
func _check_moods() -> void:
	for c in queue + orders:
		var wait: float = elapsed - c["arrived"]
		var m := _mood(wait)
		var heard: int = c.get("heard", 1)
		if m >= 2 and heard < m:
			c["heard"] = m
			_play_sfx("enojo" if rng.randf() < 0.5 else "enojo2", 0.0 if m == 2 else 2.0)
			_hint("%s: «%s»" % [c["name"], _wait_line(c, m)])
	var leave_at := _patience() * Data.LEAVE_FACTOR
	for c in queue.duplicate():
		if elapsed - c["arrived"] >= leave_at:
			_customer_leaves(c, false)
	for o in orders.duplicate():
		if elapsed - o["arrived"] >= leave_at:
			_customer_leaves(o, true)


## Frases (cada vez más sarcásticas) de los clientes que esperan
const WAIT_LINES := [
	["¡Hola! ¿Me tomás el pedido?", "Buenas, cuando puedan...", "Qué lindo local, ¿no?"],
	["¿Hoy cocinan o es un museo?", "Tranqui, total no tengo nada que hacer...", "¿Esto es comida rápida o lenta?",
		"Me están creciendo canas acá", "¿El cocinero fue a buscar la vaca?"],
	["Tic, tac... tic, tac.", "Si tardan más, vengo con almohada", "¡Ya me hice amigo de la planta!",
		"Pido el desayuno de mañana también, así ganamos tiempo", "¿Sabían que el pedido era para hoy?",
		"Bravo, récord mundial de espera"],
]


func _wait_line(c: Dictionary, mood: int) -> String:
	var lines: Array = WAIT_LINES[clampi(mood - 1, 0, 2)]
	var sd: int = c.get("look", {}).get("seed", 0)
	return lines[(int(elapsed / 7.0) + sd) % lines.size()]


## Un cliente se cansó de esperar: se va enojado y el pedido se pierde
func _customer_leaves(c: Dictionary, is_order: bool) -> void:
	if is_order:
		for e in c["plate"]:
			if not e["pantry"]:
				prepared.append(e)       # lo que ya estaba en el plato vuelve a la bandeja
		orders.erase(c)
		if selected_id == c["id"]:
			selected_id = orders[0]["id"] if not orders.is_empty() else -1
	else:
		if not pending_order.is_empty() and not queue.is_empty() and queue[0] == c:
			pending_order = {}
		queue.erase(c)
	lost += 1
	walkers.append({"look": c["look"], "x": c.get("x", _queue_x(0)) if not is_order else _queue_x(0),
		"bubble": "¡Me voy! ¡Qué servicio!", "dir": -1, "mood": 3})
	_play_sfx("enojo2", 3.0)
	_play_sfx("campanita", -4.0)
	_hint("%s se cansó de esperar y se fue" % c["name"])
	_refresh_all()


func _looped(path: String) -> AudioStreamWAV:
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStreamWAV = load(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	return stream


## Un sonido por cada cosa que se está cocinando: se suman entre sí.
func _update_cook_audio(delta: float) -> void:
	var muffle := 0.0 if current_station == 1 else -7.0
	for a in cookers:
		for i in cookers[a].size():
			var key := "%s:%d" % [a, i]
			var s = cookers[a][i]
			var p: AudioStreamPlayer = cook_players.get(key)
			if s != null and playing and sfx_on and cook_streams.get(a) != null:
				var target: float = COOK_SFX[a][1] + muffle
				if s["t"] >= s["burn"] - 3.0:
					target += 3.0     # cuando se está por quemar, se escucha más
				if p == null:
					p = AudioStreamPlayer.new()
					p.stream = cook_streams[a]
					p.pitch_scale = rng.randf_range(0.92, 1.08)
					# la plancha y la freidora "chillan" al apoyar la comida; la olla y el horno entran despacio
					p.volume_db = target + 4.0 if a in ["plancha", "freidora"] else -30.0
					add_child(p)
					p.play(rng.randf() * 3.8)
					cook_players[key] = p
				p.volume_db = move_toward(p.volume_db, target, 30.0 * delta)
			elif p != null:
				p.volume_db = move_toward(p.volume_db, -45.0, 70.0 * delta)
				if p.volume_db <= -44.0:
					p.queue_free()
					cook_players.erase(key)


func _stop_cook_audio() -> void:
	for key in cook_players:
		cook_players[key].queue_free()
	cook_players.clear()
	if water_player != null:
		water_player.queue_free()
		water_player = null


# =====================================================================
# Bacha: lavar lo sucio
# =====================================================================


func _update_washing(delta: float) -> void:
	var sv_ok: bool = sink_view != null and is_instance_valid(sink_view)
	# El grifo abre y cierra de a poco
	water_flow = move_toward(water_flow, 1.0 if water_on else 0.0, delta * 3.0)
	if water_flow > 0.0:
		sink_pool = minf(0.55, sink_pool + delta * 0.035 * water_flow)
	else:
		sink_pool = maxf(0.0, sink_pool - delta * 0.1)
	# Fregar: las manchas salen sólo donde pasa la esponja
	var sponge_off = null
	if scrubbing:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not sv_ok:
			_end_scrub()
		else:
			var mp := get_global_mouse_position()
			scrub_cursor.position = mp
			var moved := mp.distance_to(scrub_last)
			scrub_last = mp
			scrub_speed = lerpf(scrub_speed, moved / maxf(delta, 0.001), minf(1.0, delta * 12.0))
			var local: Vector2 = sink_view.get_local_mouse_position()
			if sink_item != null and sink_view.is_over_item(local):
				sponge_off = sink_view.to_item(local)
				if moved > 0.0:
					_soap_item()
					SinkView.scrub(sink_item, sponge_off, moved, 1.0 if sink_item.get("soaped", false) else 0.0, rng)
					if not sink_item.get("soaped", false) and sink_item["dirt"] > 0.0 and not soap_warned:
						soap_warned = true
						_hint("Sin detergente casi no sale la grasa: tocá la botella")
				scrub_sound_t -= delta
				if moved > 2.0 and scrub_sound_t <= 0.0:
					_play_sfx("frotar", -3.0 if water_flow > 0.5 else 0.0)
					scrub_sound_t = 0.26
	# Enjuagar: el chorro se lleva la espuma
	if sink_item != null:
		SinkView.rinse(sink_item, delta, water_flow, sponge_off)
	if sv_ok:
		sink_view.item = sink_item
		sink_view.flow = water_flow
		sink_view.pool = sink_pool
		sink_view.soap = 1.0 if sink_item != null and sink_item.get("soaped", false) else sponge_soap
	# Sonido de la canilla (más fuerte y agudo si el chorro pega sobre algo)
	var want := water_flow > 0.05 and sfx_on
	if want and water_player == null:
		var st := _looped("res://assets/sfx/canilla.wav")
		if st != null:
			water_player = AudioStreamPlayer.new()
			water_player.stream = st
			water_player.volume_db = -30.0
			add_child(water_player)
			water_player.play()
	if water_player != null:
		var target := -45.0
		if want:
			target = (-14.0 if current_station == 5 else -24.0) + (2.0 if sink_item != null else 0.0) + linear_to_db(water_flow)
		water_player.volume_db = move_toward(water_player.volume_db, target, 60.0 * delta)
		water_player.pitch_scale = move_toward(water_player.pitch_scale, 1.12 if sink_item != null else 1.0, delta)
		if not want and water_player.volume_db <= -44.0:
			water_player.queue_free()
			water_player = null
	# Lavavajillas: lava una cosa sucia cada 8 segundos
	if _has("lavavajillas") and not dirty.is_empty():
		dishwasher_t += delta
		if dishwasher_t >= 8.0:
			dishwasher_t = 0.0
			var k: String = dirty.pop_front()
			clean_stock[k] = clean_stock.get(k, 0) + 1
			if current_station == 5:
				_refresh_station()
	else:
		dishwasher_t = 0.0
	_check_wash_alert(delta)


## 0 = todo bien, 1 = se están apilando, 2 = urgente (sin platos limpios o una montaña de sucios)
func _wash_alert_level() -> int:
	var plates: int = clean_stock.get("plato", 0)
	if plates == 0 or dirty.size() >= 10:
		return 2
	if plates <= 2 or dirty.size() >= 6:
		return 1
	return 0


## Avisa cuando se acumula lo sucio: ruido de loza apilándose y un cartel (y recuerda cada tanto si es urgente)
func _check_wash_alert(delta: float) -> void:
	var lvl := _wash_alert_level()
	wash_alert_t -= delta
	var remind: bool = lvl == 2 and wash_alert_t <= 0.0 and current_station != 5
	if lvl > wash_alert or remind:
		wash_alert_t = 30.0
		_play_sfx("platos", 0.0 if lvl == 2 else -3.0)
		var plates: int = clean_stock.get("plato", 0)
		if plates == 0:
			_hint("¡No quedan platos limpios! Los próximos salen en plato sucio: andá a la Bacha (tecla 6)")
		elif lvl == 2:
			_hint("¡Montaña de cosas sucias en la Bacha! Lavá antes de que no quede nada (tecla 6)")
		elif plates <= 2:
			_hint("Quedan %d platos limpios: se están apilando los sucios en la Bacha (tecla 6)" % plates)
		else:
			_hint("Se están apilando las cosas sucias en la Bacha (tecla 6)")
	wash_alert = lvl


func _sink_drop(data: Dictionary) -> void:
	var k: String = data.get("tool", "")
	if not k in dirty:
		return
	if not SinkView.can_stack(sink_item, k):
		if sink_item != null and sink_item["kind"] != k:
			_hint("En la pileta sólo se lavan juntas piezas del mismo tipo")
		else:
			_hint("Ya hay %d en la pileta: no entran más" % SinkView.MAX_STACK)
		return
	dirty.erase(k)
	if sink_item == null:
		sink_item = SinkView.new_item(k, rng.randi() % 100000)
	else:
		SinkView.add_to_stack(sink_item)    # se apila: tarda más en proporción
		if sink_item.get("soaped", false):
			sponge_soap = maxf(0.0, sponge_soap - 1.0 / SinkView.SOAP_ITEMS)
	_play_sfx("chapoteo" if sink_pool > 0.08 else "plato", -6.0)
	_refresh_station()


func _toggle_water() -> void:
	water_on = not water_on
	if current_station == 5:
		_refresh_station()


## La pieza toma su parte de detergente la primera vez que se la friega con la esponja cargada:
## desde ahí le alcanza hasta quedar limpia (nunca se acaba a mitad de una pieza).
func _soap_item() -> void:
	if sink_item == null or sink_item.get("soaped", false) or sponge_soap <= 0.0:
		return
	sink_item["soaped"] = true
	sponge_soap = maxf(0.0, sponge_soap - 1.0 / SinkView.SOAP_ITEMS)
	if sponge_soap <= 0.01:
		sponge_soap = 0.0


func _load_soap() -> void:
	sponge_soap = 1.0
	soap_warned = false
	_play_sfx("detergente")
	_hint("Esponja con detergente: ¡a fregar!")
	if current_station == 5:
		_refresh_station()


func _start_scrub() -> void:
	if paused:
		return
	if sink_item == null:
		_hint("Primero arrastrá algo sucio a la pileta")
		return
	if sink_item["dirt"] <= 0.0 and sink_item["bubbles"].is_empty():
		_hint("Ya está limpio: arrastralo al escurridor")
		return
	scrubbing = true
	scrub_speed = 0.0
	scrub_last = get_global_mouse_position()
	var cursor := Painter.new()
	cursor.animate = true
	cursor.size = Vector2(1, 1)
	cursor.z_index = 100
	cursor.fn = func(ci, time):
		var sq := clampf(scrub_speed / 900.0, 0.0, 1.0)
		Art.draw_sponge(ci, Rect2(-36, -26, 72, 52), sin(time * 14.0) * 0.12 * sq, sponge_soap, sq)
	add_child(cursor)
	scrub_cursor = cursor
	scrub_cursor.position = scrub_last


func _end_scrub() -> void:
	scrubbing = false
	if scrub_cursor != null and is_instance_valid(scrub_cursor):
		scrub_cursor.queue_free()
	scrub_cursor = null
	if current_station == 5:
		_refresh_station()     # para que la esponja muestre cuánto detergente le queda


func _rack_drop(data: Dictionary) -> void:
	if sink_item == null or sink_item["dirt"] > 0.0 or not sink_item["bubbles"].is_empty():
		return
	var k: String = data.get("tool", sink_item["kind"])
	var cnt: int = sink_item.get("count", 1)
	clean_stock[k] = clean_stock.get(k, 0) + cnt
	for j in cnt:
		rack_recent.append({"kind": k, "t": Time.get_ticks_msec() / 1000.0})
	var plates := rack_recent.filter(func(r): return r["kind"] == "plato")
	var others := rack_recent.filter(func(r): return r["kind"] != "plato")
	rack_recent = plates.slice(-6) + others.slice(-3)
	sink_item = null
	_play_sfx("plato", -4.0)
	_refresh_all()


func _dirty_count() -> int:
	return dirty.size() + (sink_item.get("count", 1) if sink_item != null else 0)


func _build_sink_station() -> void:
	var draw_bg := func(ci, _t):
		Art.draw_kitchen_wall(ci, Rect2(0, 0, 1280, 300))
		Art.draw_wood_counter(ci, Rect2(0, 300, 1280, STATION_SIZE.y - 300))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	_tag("Bacha  ·  sucio a la pileta (podés juntar varios iguales) → detergente → frotá → enjuagá → al escurridor", Vector2(12, 4), 15)
	# Izquierda: la pila de sucios, agrupada por tipo (los platos, apilados)
	_tag("Sucio (%d)" % dirty.size(), Vector2(24, 44), 15)
	var counts := {}
	for k in dirty:
		counts[k] = counts.get(k, 0) + 1
	var n := 0
	for k in Data.TOOL_ORDER:
		if not counts.has(k):
			continue
		var kind: String = k
		var cnt: int = counts[kind]
		var b := _prop(Rect2(20 + (n % 2) * 160, 74 + (n / 2) * 128, 150, 120))
		var seed := n * 37 + 5
		b.draw_fn = func(ci, r):
			# Se ve la pila: varias piezas una encima de otra
			for j in mini(cnt, 4):
				var off := Vector2(4.0 * ((j % 2) * 2 - 1) * (1 if j > 0 else 0), -7.0 * j)
				Art.draw_tool(ci, Rect2(r.position + Vector2(10, 14) + off, r.size - Vector2(20, 24)), kind, 1.0, 0.0, false, seed + j)
		b.text = "%s x%d" % [Data.TOOLS[kind]["name"], cnt]
		b.text_size = 14
		b.drag_data = {"kind": "dirty", "tool": kind}
		b.tooltip_text = "Arrastralo a la pileta"
		b.pressed.connect(_sink_drop.bind({"tool": kind}))
		n += 1
	if n == 0:
		_tag("¡Nada sucio!\nTodo en orden.", Vector2(60, 140), 18)
	# Centro: la pileta con su grifo
	sink_view = SinkView.new()
	sink_view.position = Vector2(370, 40)
	sink_view.size = Vector2(440, 380)
	sink_view.item = sink_item
	sink_view.flow = water_flow
	sink_view.pool = sink_pool
	sink_view.soap = 1.0 if sink_item != null and sink_item.get("soaped", false) else sponge_soap
	sink_view.faucet_pressed.connect(_toggle_water)
	sink_view.dropped.connect(_sink_drop)
	station_box.add_child(sink_view)
	# Esponja y detergente
	var soap_now := sponge_soap
	var sponge := _prop(Rect2(830, 56, 130, 100))
	sponge.draw_fn = func(ci, r): Art.draw_sponge(ci, r.grow(-8), 0.0, soap_now)
	sponge.text = "Esponja" if sponge_soap > 0.0 else "Esponja (seca)"
	sponge.text_size = 12
	sponge.mouse_default_cursor_shape = Control.CURSOR_DRAG
	sponge.tooltip_text = "Mantené apretado y frotá sobre las manchas"
	sponge.held.connect(_start_scrub)
	var soap := _prop(Rect2(845, 172, 100, 130))
	soap.draw_fn = func(ci, r): Art.draw_detergent(ci, r.grow(-6), 0.7)
	soap.text = "Detergente"
	soap.text_size = 12
	soap.tooltip_text = "Tocalo para cargar la esponja"
	soap.pressed.connect(_load_soap)
	var faucet := _button("Cerrar grifo" if water_on else "Abrir grifo", _toggle_water, 14)
	faucet.position = Vector2(836, 330)
	station_box.add_child(faucet)
	# Derecha: el escurridor
	rack_view = RackView.new()
	rack_view.position = Vector2(990, 44)
	rack_view.size = Vector2(260, 170)
	rack_view.recent = rack_recent
	rack_view.dropped.connect(_rack_drop)
	station_box.add_child(rack_view)
	# Stock limpio
	var lines := []
	for k in Data.TOOL_ORDER:
		if k == "pala" and current_country != "italia":
			continue
		var c: int = clean_stock.get(k, 0)
		lines.append("%s: %s" % [Data.TOOLS[k]["name"], str(c) if c > 0 else "¡0!"])
	var info := "Limpio:\n"
	for k in lines.size():
		info += lines[k] + ("\n" if k % 2 == 1 or k == lines.size() - 1 else "   ·   ")
	if _has("lavavajillas"):
		info += "Lavavajillas: lava solo\n"
	info += "\nSin limpios se usa algo sucio:\ncomida -20%, plato -25%."
	_card(Rect2(990, 250, 270, 0), info, 13)



# =====================================================================
# Pausa
# =====================================================================

func _toggle_pause() -> void:
	if not playing:
		return
	if paused:
		_resume()
		return
	paused = true
	_end_sprinkle()
	for key in cook_players:
		cook_players[key].stream_paused = true
	var box := _open_overlay()
	box.add_child(_label("Pausa", 44, COL_INK))
	box.add_child(_label("El local está en pausa: la cocina y los clientes esperan.", 17, COL_INK))
	box.add_child(_label("(P o Esc para seguir)", 14, Color(0.4, 0.3, 0.2)))
	var go := _button("Seguir cocinando", _resume, 22)
	go.custom_minimum_size = Vector2(320, 56)
	box.add_child(go)
	box.add_child(_button("Reiniciar el día", _restart_from_pause, 18))
	box.add_child(_button("Salir al menú", _quit_from_pause, 18))
	_update_pause_button()


func _resume() -> void:
	paused = false
	_close_overlay()
	for key in cook_players:
		cook_players[key].stream_paused = false
	_update_pause_button()


func _restart_from_pause() -> void:
	paused = false
	playing = false
	_stop_cook_audio()
	_show_intro(level_idx)
	_update_pause_button()


func _quit_from_pause() -> void:
	paused = false
	_stop_cook_audio()
	_show_menu()
	_update_pause_button()


func _update_pause_button() -> void:
	if pause_button != null:
		pause_button.text = "Seguir" if paused else "Pausa"


func _toggle_sfx() -> void:
	sfx_on = not sfx_on
	if not sfx_on:
		_stop_cook_audio()
	_update_music_button()
	_save_progress()


func _toggle_music() -> void:
	music_on = not music_on
	if music_on and music.stream != null:
		music.play()
	else:
		music.stop()
	_update_music_button()
	_save_progress()


func _update_music_button() -> void:
	if music_button != null:
		music_button.text = "Música: sí" if music_on else "Música: no"
	if sfx_button != null:
		sfx_button.text = "Sonidos: sí" if sfx_on else "Sonidos: no"


func _process(delta: float) -> void:
	if not playing:
		if close_button != null and close_button.visible:
			close_button.visible = false
		if not cook_players.is_empty() or water_player != null:
			_stop_cook_audio()      # también corta la canilla
		return
	if paused:
		return
	if _update_day_intro(delta):
		return
	_update_sprinkle(delta)
	_update_salting(delta)
	_update_washing(delta)
	elapsed += delta

	if spawned < level["customers"]:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and queue.size() + orders.size() < MAX_ACTIVE:
			_spawn_customer()
			var iv: Array = level["interval"]
			spawn_timer = rng.randf_range(iv[0], iv[1])

	for i in queue.size():
		queue[i]["x"] = move_toward(queue[i]["x"], _queue_x(i), WALK_SPEED * delta)
	for wk in walkers:
		wk["x"] += WALK_SPEED * delta * wk.get("dir", 1)
	walkers = walkers.filter(func(wk): return wk["x"] < 1400.0 and wk["x"] > DOOR_X - 10.0)

	var auto_off := []
	for a in cookers:
		for i in cookers[a].size():
			var slot = cookers[a][i]
			if slot == null:
				continue
			var before: float = _doneness_progress(slot)
			slot["t"] += delta / Data.COOK_SLOW     # la cocción avanza más lento que el reloj
			if slot.has("ta"):
				# Pizza en el horno de leña: la mitad que mira al fuego se cocina mucho más rápido
				slot["ta"] += delta / Data.COOK_SLOW * 1.5
				slot["tb"] += delta / Data.COOK_SLOW * 0.5
			if before < slot["target"] and _doneness_progress(slot) >= slot["target"]:
				if _has("timbre"):
					_play_sfx("timbre")
				if _has("ayudante"):
					auto_off.append([a, i])
	for ai in auto_off:
		_hint("El ayudante sacó %s en su punto" % Data.ITEMS[cookers[ai[0]][ai[1]]["item"]]["name"].to_lower())
		_take_off(ai[0], ai[1])
	_update_cook_audio(delta)
	_update_pending_order(delta)
	_check_moods()

	if current_station == 0:
		_update_customer_views()
	_update_tabs()
	_update_hud()
	_update_ticket_texts()

	if spawned >= level["customers"] and queue.is_empty() and orders.is_empty():
		# Ya no queda nadie: hay CLEANUP_TIME segundos para lavar lo que quedó (así conviene lavar
		# mientras se cocina). Cierra solo al terminar de lavar, al acabarse el tiempo o con el botón.
		if _dirty_count() == 0:
			_finish_level()
		elif not closing:
			closing = true
			closing_t = Data.CLEANUP_TIME
			_play_sfx("timbre")
			_hint("¡Atendiste a todos! Tenés %d segundos para lavar lo que quedó: lo sucio al cerrar baja la reputación" % int(Data.CLEANUP_TIME))
		else:
			closing_t -= delta
			if closing_t <= 0.0:
				_hint("¡Se acabó el tiempo! Se cierra el local")
				_finish_level()
		if closing and close_button != null:
			close_button.visible = playing
			close_button.text = "Cerrar ya · %ds · %d sin lavar" % [int(ceil(maxf(closing_t, 0.0))), _dirty_count()]
			close_button.add_theme_color_override("font_color", Color("c0281a") if closing_t <= 10.0 else COL_INK)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_M:
		_toggle_music()
		return
	if not playing:
		return
	if key.keycode == KEY_P or key.keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	if paused:
		return
	if key.keycode == KEY_R and current_station == 1:
		_toggle_recipes()
		return
	if key.keycode >= KEY_1 and key.keycode <= KEY_6:
		_go_to_station(key.keycode - KEY_1)
	elif key.keycode == KEY_SPACE and current_station == 2 and _uses_mesa():
		_mesa_tap()
	elif key.keycode == KEY_SPACE and current_station == 2:
		_chop()


# =====================================================================
# Niveles y progreso
# =====================================================================

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(save_path)
	if err != OK and save_path == SAVE_PATH:
		# El juego antes se llamaba "Viandas": si hay una partida guardada con ese nombre, se trae
		var old := OS.get_data_dir().path_join("Godot/app_userdata/Viandas/progreso.cfg")
		if FileAccess.file_exists(old):
			err = cfg.load(old)
	if err == OK:
		savings = cfg.get_value("progreso", "ahorros", 0)
		owned = cfg.get_value("progreso", "mejoras_compradas", [])
		music_on = cfg.get_value("opciones", "musica", true)
		sfx_on = cfg.get_value("opciones", "sonidos", true)
		country_progress = cfg.get_value("paises", "progreso", {})
		owned_countries = cfg.get_value("paises", "locales", ["argentina"])
		current_country = cfg.get_value("paises", "actual", "argentina")
		if country_progress.is_empty():
			# Partidas viejas (antes del modo historia): lo jugado pasa al local de Buenos Aires
			country_progress["argentina"] = {"desbloqueado": cfg.get_value("progreso", "desbloqueado", 0),
				"mejores": cfg.get_value("progreso", "mejores", {})}
	if not Data.COUNTRIES.has(current_country) or not Data.COUNTRIES[current_country]["ready"]:
		current_country = "argentina"
	_use_country(current_country)


func _save_progress() -> void:
	_store_country()
	var cfg := ConfigFile.new()
	cfg.set_value("progreso", "ahorros", savings)
	cfg.set_value("progreso", "mejoras_compradas", owned)
	cfg.set_value("paises", "progreso", country_progress)
	cfg.set_value("paises", "locales", owned_countries)
	cfg.set_value("paises", "actual", current_country)
	cfg.set_value("opciones", "musica", music_on)
	cfg.set_value("opciones", "sonidos", sfx_on)
	cfg.save(save_path)


func _reset_progress() -> void:
	savings = 0
	owned = []
	country_progress = {}
	owned_countries = ["argentina"]
	current_country = "argentina"
	_use_country(current_country)
	_save_progress()
	_show_title()


## Cambia al local de un país: los días desbloqueados y récords son de cada local
func _use_country(id: String) -> void:
	current_country = id
	var p: Dictionary = country_progress.get(id, {})
	unlocked_level = p.get("desbloqueado", 0)
	best_scores = p.get("mejores", {})


func _store_country() -> void:
	var p: Dictionary = country_progress.get(current_country, {})
	p["desbloqueado"] = unlocked_level
	p["mejores"] = best_scores
	country_progress[current_country] = p


func _levels() -> Array:
	return Data.COUNTRIES[current_country]["levels"]


## Reputación de un local: promedio de los mejores puntajes de sus días
func _reputation(id: String) -> int:
	var best: Dictionary = best_scores if id == current_country else country_progress.get(id, {}).get("mejores", {})
	if best.is_empty():
		return 0
	var sum := 0.0
	for k in best:
		sum += best[k]
	return int(sum / best.size())


func _has(upgrade: String) -> bool:
	return upgrade in owned


func _patience() -> float:
	var p: float = level.get("patience", 60.0)
	if _has("plantas"):
		p *= 1.15
	if _has("ventilador"):
		p *= 1.25
	return p


# =====================================================================
# Tienda: mejoras para el local con los ahorros
# =====================================================================

func _show_shop(next_level := -1) -> void:
	playing = false
	var box := _open_overlay()
	box.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	box.add_child(head)
	head.add_child(_label("Tienda del local", 34, COL_INK))
	var cash := _label("Ahorros: $%d" % savings, 24, Color("2f7a3a"))
	cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cash.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(cash)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for id in Data.UPGRADE_ORDER:
		grid.add_child(_shop_card(id, next_level))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	if next_level >= 0:
		var go := _button("Seguir al día siguiente", _show_intro.bind(next_level), 20)
		row.add_child(go)
	row.add_child(_button("Volver al menú", _show_menu, 18))


func _shop_card(id: String, next_level: int) -> Control:
	var up: Dictionary = Data.UPGRADES[id]
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff9ea") if not _has(id) else Color("e8f4e0")
	sb.border_color = Color("c9a86a") if not _has(id) else Color("7ab36a")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(250, 0)
	var col := HBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var pic := PropButton.new()
	pic.custom_minimum_size = Vector2(64, 64)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.draw_fn = func(ci, r): _draw_upgrade_icon(ci, r, id)
	col.add_child(pic)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(info)
	info.add_child(_label("%s  ·  %s" % [up["name"], up["for"]], 14, COL_INK))
	var d := _label(up["desc"], 12, Color(0.3, 0.24, 0.18))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(160, 0)
	info.add_child(d)
	if _has(id):
		info.add_child(_label("Comprado", 14, Color("2f7a3a")))
	else:
		var b := _button("Comprar $%d" % up["price"], _buy.bind(id, next_level), 14)
		b.disabled = savings < up["price"]
		if b.disabled:
			b.tooltip_text = "Te faltan $%d" % (up["price"] - savings)
		info.add_child(b)
	return card


func _buy(id: String, next_level: int) -> void:
	var price: int = Data.UPGRADES[id]["price"]
	if _has(id) or savings < price:
		return
	savings -= price
	owned.append(id)
	_save_progress()
	_play_sfx("caja", -4.0)
	_show_shop(next_level)


func _draw_upgrade_icon(ci: CanvasItem, r: Rect2, id: String) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y)
	match id:
		"plantas":
			Art.hanging_plant(ci, Vector2(c.x, r.position.y + 2), s / 90.0)
		"ventilador":
			Art.ceiling_fan(ci, Vector2(c.x, r.position.y + 6), Time.get_ticks_msec() / 1000.0, s / 110.0)
		"caramelera":
			Art.candy_jar(ci, Rect2(c - Vector2(s, s) * 0.4, Vector2(s, s) * 0.8))
		"vajilla":
			Art.draw_tex(ci, Art.tex("kitchen/plate"), r)
			ci.draw_arc(c, s * 0.46, 0, TAU, 40, Color("d9a520"), 3)
		"timbre":
			Art.draw_tex(ci, Art.tex("kitchen/bell"), r)
		"reloj":
			ci.draw_circle(c, s * 0.42, Color("2b2d31"))
			ci.draw_circle(c, s * 0.36, Color("fbfbf8"))
			ci.draw_arc(c, s * 0.3, -PI / 2, 0.3, 12, Color("5ee06a"), 5)
			ci.draw_line(c, c + Vector2(0, -s * 0.26), Color("2b2d31"), 2)
			ci.draw_line(c, c + Vector2(s * 0.18, 0), Color("d0281a"), 2)
		"hornalla":
			Art.draw_tex(ci, Art.tex("kitchen/pot"), r)
		"procesadora":
			Art.rrect(ci, Rect2(c + Vector2(-s * 0.25, s * 0.05), Vector2(s * 0.5, s * 0.36)), Color("d9534a"), 6)
			Art.rrect(ci, Rect2(c + Vector2(-s * 0.2, -s * 0.38), Vector2(s * 0.4, s * 0.45)), Color(0.85, 0.92, 0.95, 0.8), 6, Color("9aa3ab"), 2)
			Art.draw_food(ci, "zanahoria", Rect2(c + Vector2(-s * 0.16, -s * 0.32), Vector2(s * 0.32, s * 0.34)), Color.WHITE, true)
		"ayudante":
			Art.draw_character(ci, Art.chef_look(), Vector2(c.x, r.end.y), s / 190.0, 0, Time.get_ticks_msec() / 1000.0)


func _show_menu() -> void:
	playing = false
	paused = false
	_end_sprinkle()
	_end_salting()
	intro_t = -1.0
	if intro_view != null and is_instance_valid(intro_view):
		intro_view.queue_free()
	intro_view = null
	_update_pause_button()
	_close_overlay()
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	overlay = bg
	var menu_names := []
	for lv in _levels():
		for r in lv["new"]:
			if menu_names.size() < 7:
				menu_names.append(Data.RECIPES[r]["name"])
	var draw_bg := func(ci, t):
		Art.draw_dining(ci, Rect2(0, 0, 1280, 720), menu_names, t, owned, current_country)
		Art.draw_counter(ci, Rect2(0, 0, 1280, 720), 470, current_country)
	var p := _painter(Rect2(0, 0, 1280, 720), draw_bg, true, bg)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var light := func(ci, _t): Art.draw_lighting(ci, Rect2(0, 0, 1280, 720))
	_painter(Rect2(0, 0, 1280, 720), light, false, bg)
	var chef := CustomerView.new()
	chef.look = Art.chef_look()
	chef.scale_factor = 2.3
	chef.position = Vector2(60, 40)
	chef.size = Vector2(380, 450)
	chef.bubble = "¡Bienvenido a la cocina!"
	bg.add_child(chef)

	var card := _paper_card(Vector2(560, 0))
	card.position = Vector2(470, 40)
	bg.add_child(card)
	var box: VBoxContainer = card.get_child(0)
	var cdata: Dictionary = Data.COUNTRIES[current_country]
	box.add_child(_label(cdata["restaurant"], 46, COL_INK))
	box.add_child(_label("%s, %s  ·  reputación %d%%" % [cdata["city"], cdata["name"], _reputation(current_country)], 17, COL_INK))
	box.add_child(_spacer(2))
	for i in _levels().size():
		var lv: Dictionary = _levels()[i]
		var txt: String = lv["name"]
		if best_scores.has(i):
			txt += "   ·   %d%%  ·  %d de 3 estrellas" % [int(best_scores[i]), _stars(best_scores[i])]
		elif i > unlocked_level:
			txt += "   (bloqueado)"
		var b := _button(txt, _show_intro.bind(i), 19)
		b.custom_minimum_size = Vector2(520, 46)
		b.disabled = i > unlocked_level
		box.add_child(b)
	box.add_child(_spacer(4))
	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	bottom.add_theme_constant_override("separation", 8)
	var shop := _button("Tienda  ·  ahorros $%d" % savings, _show_shop.bind(-1), 17)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(shop)
	bottom.add_child(_button("Volver al mapa", _show_map, 17))


# =====================================================================
# Pantalla de título y mapamundi
# =====================================================================

func _stop_everything() -> void:
	playing = false
	paused = false
	_end_sprinkle()
	_end_salting()
	intro_t = -1.0
	if intro_view != null and is_instance_valid(intro_view):
		intro_view.queue_free()
	intro_view = null
	_update_pause_button()
	_close_overlay()


func _show_title() -> void:
	_stop_everything()
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	overlay = bg
	# De fondo, el mapamundi moviéndose solo
	var wm := WorldMap.new()
	wm.size = Vector2(1280, 720)
	wm.owned = owned_countries
	wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(wm)
	var drift := func(ci, t):
		wm.cam = Vector2(fmod(t * 25.0, WorldMap.MW - 1280.0 / wm.zoom), 260.0 + sin(t * 0.2) * 80.0)
		ci.draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.07, 0.05, 0.45))
		Art.draw_lighting(ci, Rect2(0, 0, 1280, 720))
	_painter(Rect2(0, 0, 1280, 720), drift, true, bg)
	var logo := func(ci, t): Art.draw_logo(ci, Vector2(640, 300), 1.25 + sin(t * 1.5) * 0.015, t)
	_painter(Rect2(0, 0, 1280, 720), logo, true, bg)
	var sub := _label("Un viaje de cocina por el mundo", 22, Color("fdf6e3"), 5)
	sub.position = Vector2(0, 492)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(sub)
	var play := _button("Jugar", _show_map, 28)
	play.custom_minimum_size = Vector2(260, 64)
	play.position = Vector2(510, 540)
	bg.add_child(play)
	var reset := _button("Borrar progreso", _reset_progress, 13)
	reset.position = Vector2(1130, 676)
	bg.add_child(reset)


func _show_map() -> void:
	_stop_everything()
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	overlay = bg
	var wm := WorldMap.new()
	wm.size = Vector2(1280, 720)
	wm.home = current_country
	wm.owned = owned_countries
	for id in Data.COUNTRY_ORDER:
		wm.info[id] = {"stars": country_progress.get(id, {}).get("estrellas", 0), "rep": _reputation(id)}
	wm.city_selected.connect(_on_city_selected)
	bg.add_child(wm)
	world_map = wm
	# Barra de arriba: logo chico, ahorros, estrellas y volver
	var bar := func(ci, t):
		Art.rrect(ci, Rect2(10, 8, 1260, 58), Color(0.12, 0.09, 0.07, 0.82), 12)
		Art.draw_logo(ci, Vector2(50, 37), 0.2, t)
		Art.text(ci, Vector2(90, 46), "La Vuelta al Plato", 26, Color("fdf6e3"))
		Art.text(ci, Vector2(0, 46), "Ahorros: $%d" % savings, 22, Color("ffe08a"), HORIZONTAL_ALIGNMENT_RIGHT, 1080)
		Art.text(ci, Vector2(380, 46), "Arrastrá el mapa para moverte · tocá una ciudad para viajar", 15, Color(1, 1, 1, 0.75))
	_painter(Rect2(0, 0, 1280, 80), bar, true, bg)
	var back := _button("Título", _show_title, 15)
	back.position = Vector2(1170, 22)
	bg.add_child(back)
	var zin := _button("+", func(): wm.zoom_at(Vector2(640, 380), 1.2), 22)
	zin.position = Vector2(1214, 560)
	zin.custom_minimum_size = Vector2(48, 48)
	bg.add_child(zin)
	var zout := _button("-", func(): wm.zoom_at(Vector2(640, 380), 1.0 / 1.2), 22)
	zout.position = Vector2(1214, 616)
	zout.custom_minimum_size = Vector2(48, 48)
	bg.add_child(zout)
	_show_city_card(current_country)


func _on_city_selected(id: String) -> void:
	if Data.COUNTRIES[id]["ready"] and id in owned_countries:
		_store_country()
		_use_country(id)
		_save_progress()
	_show_city_card(id)


## Ficha de la ciudad elegida en el mapa
func _show_city_card(id: String) -> void:
	if overlay == null:
		return
	var old := overlay.get_node_or_null("Ficha")
	if old != null:
		old.queue_free()
	var c: Dictionary = Data.COUNTRIES[id]
	var card := _paper_card(Vector2(340, 0))
	card.name = "Ficha"
	card.position = Vector2(20, 90)
	overlay.add_child(card)
	var box: VBoxContainer = card.get_child(0)
	box.add_theme_constant_override("separation", 6)
	var flag := Painter.new()
	flag.custom_minimum_size = Vector2(290, 40)
	flag.fn = func(ci, t): Art.draw_flag(ci, Rect2(0, 4, 48, 32), c["flag"], t)
	box.add_child(flag)
	box.add_child(_label(c["restaurant"], 28, COL_INK))
	box.add_child(_label("%s, %s" % [c["city"], c["name"]], 17, Color("2f5d50")))
	var cu := _label("Cocina: " + c["cuisine"], 14, COL_INK)
	cu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cu.custom_minimum_size = Vector2(290, 0)
	box.add_child(cu)
	var co := _label("Cómo se cocina: " + c["cooking"], 14, COL_INK)
	co.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	co.custom_minimum_size = Vector2(290, 0)
	box.add_child(co)
	if id in owned_countries:
		box.add_child(_label("Reputación: %d%%" % _reputation(id), 16, COL_INK))
		var st: int = country_progress.get(id, {}).get("estrellas", 0)
		var sp := Painter.new()
		sp.custom_minimum_size = Vector2(290, 30)
		sp.fn = func(ci, _t):
			Art.stars(ci, Vector2(30, 15), 12, st)
			Art.text(ci, Vector2(70, 21), "Estrellas de la guía", 13, Color(0.35, 0.28, 0.2))
		box.add_child(sp)
		if c["ready"]:
			var go := _button("Entrar al local", _show_menu, 22)
			go.custom_minimum_size = Vector2(290, 54)
			box.add_child(go)
	else:
		var req := _label("Abrir un local: $%d y %d %s" % [c["price"], c["stars_needed"], "estrella" if c["stars_needed"] == 1 else "estrellas"], 15, COL_INK)
		box.add_child(req)
		if not c["ready"]:
			var soon := _label("Próximamente: esta cocina todavía se está construyendo.", 14, Color("c8463c"))
			soon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			soon.custom_minimum_size = Vector2(290, 0)
			box.add_child(soon)
		var buy := _button("Comprar local ($%d)" % c["price"], _buy_country.bind(id), 18)
		buy.disabled = not c["ready"] or savings < c["price"] or _total_stars() < c["stars_needed"]
		box.add_child(buy)


func _total_stars() -> int:
	var n := 0
	for id in country_progress:
		n += country_progress[id].get("estrellas", 0)
	return n


func _buy_country(id: String) -> void:
	var c: Dictionary = Data.COUNTRIES[id]
	if id in owned_countries or not c["ready"] or savings < c["price"] or _total_stars() < c["stars_needed"]:
		return
	savings -= c["price"]
	owned_countries.append(id)
	_play_sfx("caja")
	_on_city_selected(id)


func _show_intro(i: int) -> void:
	var lv: Dictionary = _levels()[i]
	var box := _open_overlay()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_label(lv["name"], 32, COL_INK))
	box.add_child(_label("Clientes del día: %d   ·   Nuevo en el menú:" % lv["customers"], 18, COL_INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	if lv.get("drinks", false):
		# Día con bebidas: se muestran las de la heladera
		for n in Data.DRINKS:
			var dcol := VBoxContainer.new()
			row.add_child(dcol)
			var dpic := PropButton.new()
			dpic.custom_minimum_size = Vector2(70, 76)
			dpic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var dn: String = n
			dpic.draw_fn = func(ci, rr): Art.draw_drink(ci, rr, dn, Data.DRINKS)
			dcol.add_child(dpic)
			var dl := _label(n, 13, COL_INK)
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dcol.add_child(dl)
	for r in lv["new"]:
		var rec: Dictionary = Data.RECIPES[r]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		row.add_child(col)
		var pic := PropButton.new()
		pic.custom_minimum_size = Vector2(130, 76)
		pic.food_id = rec["parts"][0][0]
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(pic)
		var l := _label("%s\n(%s)" % [rec["name"], rec["cat"]], 14, COL_INK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(130, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
	var tip := "La barra de cocción marca en verde el punto ideal: sacá la comida cuando la barra esté adentro."
	if lv.get("drinks", false):
		tip = "Cada pedido viene con bebida: en la Entrega (tecla 5) arrastrala desde la heladera hasta la bandeja antes de servir."
	elif not lv["show_zone"]:
		tip = "Desde hoy la barra NO marca el punto: mirá el reloj, el termómetro de las carnes y el recetario (tecla R)."
	if i == 0:
		tip = "Cómo se juega:\n1. Pedidos: tomá el pedido del cliente del mostrador.\n" + \
			"2. Cocina: arrastrá los ingredientes de la heladera al aparato y sacalos en su punto (click). Las carnes tienen termómetro. Lo de la plancha y la olla se sala con el salero.\n" + \
			"3. Tabla: arrastrá la verdura hasta la tabla y cortala (click en la tabla o barra espaciadora).\n" + \
			"4. Emplatado: arrastrá al plato lo de la bandeja y la salsa. Los toppings se desparraman: mantené el bowl apretado sobre la comida.\n" + \
			"5. Entrega: tocá la campanita para servir.\n" + \
			"6. Bacha: los platos (y, con el uso, ollas, espátulas y tablas) quedan sucios. Detergente a la esponja, frotá las manchas, enjuagá y al escurridor. Cuando se va el último cliente tenés 30 s para lavar lo que quedó (lo sucio al cerrar baja la reputación): conviene lavar mientras se cocina.\n" + \
			"Click en un ticket para elegir con qué pedido trabajás. Teclas 1 a 6: cambiar de estación.\n\n" + tip
	var tl := _label(tip, 14, COL_INK)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(760, 0)
	tl.add_theme_constant_override("line_spacing", -2)
	box.add_child(tl)
	box.add_child(_label("Necesitás un promedio de %d%% para pasar al día siguiente." % int(Data.PASS_SCORE), 14, COL_INK))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var go := _button("¡Abrir el local!", _start_level.bind(i), 22)
	go.custom_minimum_size = Vector2(280, 56)
	buttons.add_child(go)
	var back := _button("Volver", _show_menu, 18)
	back.custom_minimum_size = Vector2(140, 56)
	buttons.add_child(back)


func _start_level(i: int) -> void:
	level_idx = i
	level = _levels()[i]
	recipes = []
	for j in i + 1:
		for r in _levels()[j]["new"]:
			recipes.append(r)
	elapsed = 0.0
	spawn_timer = 1.0
	spawned = 0
	served = 0
	lost = 0
	score_sum = 0.0
	money = 0
	next_id = 1
	queue.clear()
	walkers.clear()
	orders.clear()
	cookers.clear()
	for a in Data.APPLIANCE_ORDER:
		var arr := []
		var n_slots: int = Data.APPLIANCES[a]["slots"] + (1 if a == "olla" and _has("hornalla") else 0)
		for k in n_slots:
			arr.append(null)
		cookers[a] = arr
	board = null
	prepared.clear()
	mesa_pizza = null
	# El día arranca con todo limpio
	clean_stock = {}
	for tk in Data.TOOLS:
		clean_stock[tk] = Data.TOOLS[tk]["stock"]
	dirty = []
	sink_item = null
	water_on = false
	rack_recent = []
	dishwasher_t = 0.0
	water_flow = 0.0
	sink_pool = 0.0
	sponge_soap = 0.0
	soap_warned = false
	wash_alert = 0
	wash_alert_t = 0.0
	tool_uses_left = {}
	tool_clean_now = {}
	closing = false
	if close_button != null:
		close_button.visible = false
	pending_order = {}
	selected_id = -1
	current_station = 0
	last_result = {}
	_close_overlay()
	paused = false
	playing = true
	_update_pause_button()
	_refresh_all()
	_start_day_intro()


# =====================================================================
# Intro del día: sube la persiana, el cartel pasa a ABIERTO y aparece el nombre del día
# =====================================================================

const INTRO_LEN := 3.2
var intro_t := -1.0          # -1 = sin intro
var intro_view: Control = null
var intro_bell := false


func _start_day_intro() -> void:
	intro_t = 0.0
	intro_bell = false
	var title: String = level["name"]
	var sub := "Clientes de hoy: %d  ·  ¡A cocinar!" % level["customers"]
	if level.get("drinks", false):
		sub = "Hoy los pedidos vienen con bebida"
	var p := Painter.new()
	p.position = Vector2.ZERO
	p.size = Vector2(1280, 720)
	p.animate = true
	p.z_index = 50
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.fn = func(ci, time): Art.draw_day_intro(ci, Rect2(0, 0, 1280, 720), intro_t / INTRO_LEN, title, sub, time, current_country)
	p.gui_input.connect(_on_intro_input)
	add_child(p)
	intro_view = p
	_play_sfx("persiana")


func _on_intro_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and intro_t < INTRO_LEN - 0.35:
		intro_t = INTRO_LEN - 0.35      # salta al final y se desvanece


## Avanza la intro. Devuelve true mientras dure (el día no arranca hasta que termina).
func _update_day_intro(delta: float) -> bool:
	if intro_t < 0.0:
		return false
	intro_t += delta
	if not intro_bell and intro_t / INTRO_LEN > 0.6:
		intro_bell = true
		_play_sfx("campanita")
	if intro_view != null and is_instance_valid(intro_view):
		intro_view.modulate.a = clampf((INTRO_LEN - intro_t) / 0.35, 0.0, 1.0)
	if intro_t >= INTRO_LEN:
		intro_t = -1.0
		if intro_view != null and is_instance_valid(intro_view):
			intro_view.queue_free()
		intro_view = null
		return false
	return true


func _finish_level() -> void:
	playing = false
	closing = false
	if close_button != null:
		close_button.visible = false
	_play_sfx("puerta")
	var avg := score_sum / (served + lost) if served + lost > 0 else 0.0   # los que se fueron cuentan como 0
	# Lo que quedó sucio al cerrar baja la reputación del día
	var dirty_left := _dirty_count()
	var dirty_pen := minf(30.0, dirty_left * Data.DIRTY_REPUTATION)
	avg = maxf(0.0, avg - dirty_pen)
	_end_scrub()
	# Al cerrar se cierra la canilla (y deja de sonar)
	water_on = false
	water_flow = 0.0
	if water_player != null:
		water_player.queue_free()
		water_player = null
	var passed := avg >= Data.PASS_SCORE
	var has_next := level_idx + 1 < _levels().size()
	if passed and has_next and level_idx + 1 > unlocked_level:
		unlocked_level = level_idx + 1
	if not best_scores.has(level_idx) or avg > best_scores[level_idx]:
		best_scores[level_idx] = avg
	savings = maxi(savings + money, 0)    # lo recaudado del día va a los ahorros
	_save_progress()

	var box := _open_overlay()
	box.add_child(_label("¡Cerró el local!", 40, COL_INK))
	box.add_child(_label(level["name"], 20, COL_INK))
	var n_stars := _stars(avg)
	var stars_pic := Painter.new()
	stars_pic.custom_minimum_size = Vector2(200, 52)
	stars_pic.fn = func(ci, _t): Art.stars(ci, Vector2(60, 26), 20, n_stars)
	box.add_child(stars_pic)
	box.add_child(_label("Platos servidos: %d" % served + ("   ·   Se fueron sin comer: %d" % lost if lost > 0 else ""), 20, COL_INK))
	box.add_child(_label("Calificación promedio: %d%%" % int(avg), 20, COL_INK))
	if dirty_left > 0:
		box.add_child(_label("Quedaron %d cosas sin lavar: -%d de reputación" % [dirty_left, int(dirty_pen)], 18, Color("a8321e")))
	box.add_child(_label("Recaudado hoy: $%d   ·   Ahorros: $%d" % [money, savings], 20, COL_INK))
	var msg := "¡Aprobado! Se desbloqueó el día siguiente." if passed else "Te faltó para el %d%%. ¡Probá de nuevo!" % int(Data.PASS_SCORE)
	if passed and not has_next:
		msg = "¡Completaste todos los días! Sos el chef del barrio."
	box.add_child(_label(msg, 18, COL_INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var next := level_idx + 1 if passed and has_next else level_idx
	var shop := _button("Ir a la tienda ($%d)" % savings, _show_shop.bind(next), 20)
	shop.tooltip_text = "Comprá mejoras para el local con tus ahorros"
	row.add_child(shop)
	if passed and has_next:
		row.add_child(_button("Día siguiente", _show_intro.bind(level_idx + 1), 20))
	row.add_child(_button("Repetir día", _show_intro.bind(level_idx), 20))
	row.add_child(_button("Menú", _show_menu, 20))


func _stars(score: float) -> int:
	if score >= 90.0:
		return 3
	if score >= 75.0:
		return 2
	if score >= Data.PASS_SCORE:
		return 1
	return 0




# =====================================================================
# Pedidos
# =====================================================================

func _queue_x(i: int) -> float:
	return 600.0 - i * 112.0


func _spawn_customer() -> void:
	spawned += 1
	queue.append({"name": _pick(NAMES), "arrived": elapsed, "look": Art.random_look(rng), "x": DOOR_X})
	_play_sfx("campanita")
	if current_station == 0:
		_refresh_station()


func _mood(wait: float) -> int:
	var p := _patience()
	if wait < p * 0.45:
		return 0
	if wait < p:
		return 1
	if wait < p * 1.5:
		return 2
	return 3


## Click en "Tomar pedido": el cliente dice lo que quiere y la moza lo anota con la birome.
func _begin_take_order() -> void:
	if queue.is_empty() or not pending_order.is_empty():
		return
	pending_order = _make_order(queue[0])
	pending_timer = 1.5
	_play_sfx("birome")
	if current_station == 0:
		_update_customer_views()


func _update_pending_order(delta: float) -> void:
	if pending_order.is_empty():
		return
	pending_timer -= delta
	if pending_timer <= 0.0:
		_commit_order(pending_order)
		pending_order = {}


## Lo que dice el cliente al pedir
func _order_speech(o: Dictionary) -> String:
	var parts := []
	for entry in o["items"]:
		parts.append(_req_text(entry).to_lower())
	var txt: String = ", ".join(PackedStringArray(parts))
	if o["sauce"] != "":
		txt += ", con " + o["sauce"].to_lower()
	if not o["toppings"].is_empty():
		txt += " y " + ", ".join(PackedStringArray(o["toppings"])).to_lower()
	return "Quiero %s" % txt


## Tomar el pedido de una (lo usan las pruebas)
func _take_order() -> void:
	if queue.is_empty():
		return
	_commit_order(_make_order(queue[0]))


func _commit_order(order: Dictionary) -> void:
	if queue.is_empty():
		return
	var c = queue.pop_front()
	next_id = maxi(next_id, order["id"] + 1)
	orders.append(order)
	selected_id = order["id"]
	walkers.append({"look": c["look"], "x": c["x"], "bubble": "¡Gracias!"})
	_refresh_all()


func _make_order(c: Dictionary) -> Dictionary:
	var rkey: String = _pick(recipes)
	var r: Dictionary = Data.RECIPES[rkey]

	var items := []
	for part in r["parts"]:
		var id: String = _pick(part)
		var info: Dictionary = Data.ITEMS[id]
		var dn := ""
		if info.has("doneness"):
			dn = _pick(info["doneness"].keys())
		items.append({"item": id, "doneness": dn})

	var sauce := ""
	var sauces: Array = r["sauces"]
	if not sauces.is_empty():
		sauce = _pick(sauces)
		if sauce == "Sin salsa":
			sauce = ""

	var pool: Array = r["toppings"].duplicate()
	pool.shuffle()
	var max_t: int = mini(level["max_toppings"], pool.size())
	var min_t: int = mini(r.get("min_toppings", 0), max_t)

	var order := {
		"id": next_id,
		"name": c["name"],
		"look": c["look"],
		"arrived": c["arrived"],
		"heard": c.get("heard", 1),
		"recipe": rkey,
		"items": items,
		"sauce": sauce,
		"toppings": pool.slice(0, rng.randi_range(min_t, max_t)),
		"plate": [],          # lo que ya está en el plato (preparaciones sacadas de la bandeja)
		"plate_sauce": "",
		"plate_toppings": [],  # toppings completos (desparramados lo suficiente)
		"sprinkles": {},       # cómo quedaron desparramados: {nombre: {amount, pts}}
		"drink": _pick(Data.DRINKS.keys()) if level.get("drinks", false) else "",
		"plate_drink": "",
	}
	return order


# =====================================================================
# Cocina
# =====================================================================

func _target_for(o, item_id: String) -> float:
	var info: Dictionary = Data.ITEMS[item_id]
	for entry in o["items"]:
		if entry["item"] == item_id and entry["doneness"] != "":
			return info["doneness"][entry["doneness"]]
	return info["target"]


func _cook(item_id: String) -> void:
	var info: Dictionary = Data.ITEMS[item_id]
	var slots: Array = cookers[info["where"]]
	var idx := slots.find(null)
	if idx == -1:
		return
	# El punto que marca la barra sale del ticket elegido (si pide ese ingrediente)
	var o = _get_order(selected_id)
	var target: float = _target_for(o, item_id) if o != null else info["target"]
	slots[idx] = {"item": item_id, "t": 0.0, "target": target, "burn": info["burn"],
		"dirty_tool": not _take_tool(Data.TOOL_FOR.get(info["where"], ""))}
	slots[idx]["tool_last"] = tool_last
	_refresh_all()


## Toma un utensilio. Cada uno aguanta varios usos antes de ir a lavar (el plato, uno solo):
## mientras le queden usos se sigue con el mismo. Si hay que agarrar otro y no quedan limpios,
## se usa uno sucio (devuelve false y avisa). tool_last = true si con este uso ya queda para lavar.
func _take_tool(kind: String) -> bool:
	tool_last = false
	if kind == "":
		return true
	var left: int = tool_uses_left.get(kind, 0)
	if left > 0:
		tool_uses_left[kind] = left - 1
		tool_last = left - 1 == 0
		return tool_clean_now.get(kind, true)
	var uses: int = Data.TOOLS[kind].get("uses", 1)
	tool_uses_left[kind] = uses - 1
	tool_last = uses - 1 == 0
	if clean_stock.get(kind, 0) > 0:
		clean_stock[kind] -= 1
		tool_clean_now[kind] = true
		return true
	dirty.erase(kind)       # se agarra uno de la pila de sucios
	tool_clean_now[kind] = false
	var name: String = Data.TOOLS[kind]["name"].to_lower()
	_hint("No queda %s limpio: se usa uno sucio. Lavá en la Bacha (tecla 6)" % name)
	return false


func _on_slot_clicked(idx: int, appliance: String) -> void:
	_take_off(appliance, idx)


func _take_off(appliance: String, idx: int) -> void:
	var slot = cookers[appliance][idx]
	if slot == null:
		return
	cookers[appliance][idx] = null
	var t: float = slot["t"]
	var tool: String = Data.TOOL_FOR.get(appliance, "")
	if tool != "" and slot.get("tool_last", true):
		dirty.append(tool)        # se gastaron sus usos: va a lavar
	if slot.has("ta"):
		# Pizza: se lleva su armado y la cocción de cada mitad
		var pz: Dictionary = slot["pizza"]
		var burnt: bool = maxf(slot["ta"], slot["tb"]) >= slot["burn"]
		var desc: String = pz.get("sauce", "")
		if desc == "":
			desc = "sin salsa"
		prepared.append({"item": "pizza", "t": t, "ta": slot["ta"], "tb": slot["tb"], "vtarget": slot["target"],
			"burn": slot["burn"], "pizza": pz, "rot": slot.get("rot", 0.0), "pantry": false, "chopped": false,
			"dirty": slot.get("dirty_tool", false),
			"label": "Pizza quemada" if burnt else "Pizza (%s)" % desc.to_lower()})
		_refresh_all()
		return
	var label := "%s %.1fs" % [Data.ITEMS[slot["item"]]["name"], t * Data.COOK_SLOW]
	if t >= slot["burn"]:
		label = "%s quemado" % Data.ITEMS[slot["item"]]["name"]
	prepared.append({"item": slot["item"], "t": t, "vtarget": slot["target"], "burn": slot["burn"],
		"label": label, "pantry": false, "chopped": false, "salt": slot.get("salt", 0.0),
		"dirty": slot.get("dirty_tool", false)})
	_refresh_all()


## Cuánto avanzó la cocción (para la pizza, la mitad que menos se cocinó)
func _doneness_progress(slot: Dictionary) -> float:
	if slot.has("ta"):
		return minf(slot["ta"], slot["tb"])
	return slot["t"]


## Calidad de la cocción de una pizza: las dos mitades tienen que estar en su punto
func _pizza_quality(e: Dictionary, target: float) -> float:
	var qa := _cook_quality(e["ta"], target, e["burn"])
	var qb := _cook_quality(e["tb"], target, e["burn"])
	return minf(qa, qb) * 0.6 + (qa + qb) / 2.0 * 0.4


func _cook_quality(t: float, target: float, burn: float) -> float:
	if t >= burn:
		return 0.0
	var diff := absf(t - target)
	if diff <= Data.ZONE:
		return 100.0
	return clampf(100.0 - (diff - Data.ZONE) * Data.COOK_PENALTY, 0.0, 100.0)


# =====================================================================
# Tabla de cortar
# =====================================================================

func _start_chop(item_id: String) -> void:
	if board != null:
		return
	var cuts: int = Data.ITEMS[item_id]["cuts"]
	if _has("procesadora"):
		cuts = int(ceil(cuts / 2.0))
	board = {"item": item_id, "cuts": 0, "need": cuts, "dirty_tool": not _take_tool("tabla")}
	board["tool_last"] = tool_last
	_refresh_all()


func _chop() -> void:
	if board == null:
		return
	board["cuts"] += 1
	_play_sfx("corte%d" % (rng.randi() % 3 + 1))
	if board["cuts"] >= board["need"]:
		var item_name: String = Data.ITEMS[board["item"]]["name"]
		prepared.append({"item": board["item"], "t": -1.0, "label": item_name + " cortada",
			"pantry": false, "chopped": true, "dirty": board.get("dirty_tool", false)})
		if board.get("tool_last", true):
			dirty.append("tabla")
		board = null
		_refresh_all()
	elif board_view != null and is_instance_valid(board_view):
		board_view.cuts = board["cuts"]
		board_view.hit()
		board_info.text = _board_text()


func _drop_chop() -> void:
	if board != null and board.get("tool_last", true):
		dirty.append("tabla")
	board = null
	_refresh_all()


func _board_text() -> String:
	if board == null:
		return ""
	return "Cortando %s\n\n%d de %d cortes\n\nClick en la tabla\no barra espaciadora\n\nLo cortado va a la bandeja\ndel Emplatado." % [
		Data.ITEMS[board["item"]]["name"], board["cuts"], board["need"]]


# =====================================================================
# Emplatado
# =====================================================================

func _plate_ready(idx: int) -> void:
	var o = _get_order(selected_id)
	if o == null or idx >= prepared.size():
		return
	o["plate"].append(prepared[idx])
	prepared.remove_at(idx)
	_refresh_all()


func _plate_pantry(item_id: String) -> void:
	var o = _get_order(selected_id)
	if o == null:
		return
	o["plate"].append({"item": item_id, "t": -1.0, "label": Data.ITEMS[item_id]["name"], "pantry": true,
		"chopped": false})
	_refresh_all()


func _on_plate_drop(data: Dictionary) -> void:
	match data["kind"]:
		"prepared": _plate_ready(data["index"])
		"pantry": _plate_pantry(data["item"])
		"sauce": _set_plate_sauce(data["name"])
		"drink":
			var o = _get_order(selected_id)
			if o != null:
				o["plate_drink"] = data["name"]
				_refresh_all()


func _on_condiment_click(_kind: String, _name: String) -> void:
	if _get_order(selected_id) != null:
		_hint("Arrastrá la salsa hasta el plato")


## Ingrediente crudo soltado sobre un aparato de la cocina
func _on_ingredient_to_appliance(item_id: String, appliance: String) -> void:
	var info: Dictionary = Data.ITEMS[item_id]
	if info["where"] != appliance:
		_hint("%s va en %s" % [info["name"], Data.APPLIANCES[info["where"]]["name"].to_lower()])
		return
	if not cookers[appliance].has(null):
		_hint("%s está llena" % Data.APPLIANCES[appliance]["name"])
		return
	_cook(item_id)


func _on_ingredient_to_board(item_id: String) -> void:
	if Data.ITEMS[item_id]["kind"] != "chop":
		_hint("Eso no se corta: va a la cocina")
		return
	if board != null:
		_hint("Terminá de cortar lo que está en la tabla")
		return
	_start_chop(item_id)


func _drag_hint(item_id: String) -> void:
	var info: Dictionary = Data.ITEMS[item_id]
	if info["kind"] == "chop":
		_hint("Arrastrá %s hasta la tabla" % info["name"].to_lower())
	else:
		_hint("Arrastrá %s hasta %s" % [info["name"].to_lower(), Data.APPLIANCES[info["where"]]["name"].to_lower()])


func _hint(text: String) -> void:
	if hint_label != null and is_instance_valid(hint_label):
		hint_label.queue_free()
	hint_label = _tag(text, Vector2.ZERO, 18)
	hint_label.position = Vector2(640 - hint_label.get_minimum_size().x / 2.0, 220)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(hint_label, "modulate:a", 0.0, 0.5)


func _set_plate_sauce(s: String) -> void:
	var o = _get_order(selected_id)
	if o != null:
		o["plate_sauce"] = s
		_refresh_all()


# --- Salero ---

func _start_salting() -> void:
	if paused or salting:
		return
	salting = true
	salt_sound_t = 0.0
	var cursor := Painter.new()
	cursor.animate = true
	cursor.size = Vector2(1, 1)
	cursor.z_index = 100
	cursor.fn = func(ci, time):
		var over := _salt_target() != []
		var shake := sin(time * 28.0) * 0.25 if over else 0.0
		Art.salt_shaker(ci, Vector2(10, -34), 1.3, PI + 0.5 + shake, over, time)
		if not over:
			Art.text(ci, Vector2(-90, 30), "Sacudilo encima de la plancha o la olla", 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 200, 4)
	add_child(cursor)
	salt_cursor = cursor
	salt_cursor.position = get_global_mouse_position()


## [aparato, lugar] que está debajo del salero (solo plancha y olla), o [] si no hay nada
func _salt_target() -> Array:
	for av in kitchen_views:
		if not is_instance_valid(av) or not av.kind in ["plancha", "olla"]:
			continue
		var i: int = av.slot_under_mouse()
		if i >= 0:
			return [av.kind, i]
	return []


func _update_salting(delta: float) -> void:
	if not salting:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or current_station != 1:
		_end_salting()
		return
	salt_cursor.position = get_global_mouse_position()
	var target := _salt_target()
	if target.is_empty():
		return
	var s = cookers[target[0]][target[1]]
	if s == null:
		return
	s["salt"] = s.get("salt", 0.0) + delta / Data.SALT_TIME
	var pts: Array = s.get("salt_pts", [])
	if pts.size() < 40:
		pts.append(Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.6, 0.6)))
	s["salt_pts"] = pts
	salt_sound_t -= delta
	if salt_sound_t <= 0.0:
		salt_sound_t = 0.42
		_play_sfx("salero")


func _end_salting() -> void:
	salting = false
	if salt_cursor != null and is_instance_valid(salt_cursor):
		salt_cursor.queue_free()
	salt_cursor = null


## Saca un topping del plato (click en su bowl cuando ya está puesto)
func _remove_topping(t: String) -> void:
	var o = _get_order(selected_id)
	if o == null:
		return
	o["plate_toppings"].erase(t)
	o["sprinkles"].erase(t)
	_refresh_all()


## Pone un topping completo de una (lo usan las pruebas automáticas)
func _sprinkle_full(t: String) -> void:
	var o = _get_order(selected_id)
	if o == null:
		return
	var pts := []
	for k in 30:
		pts.append(Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 0.8)
	o["sprinkles"][t] = {"amount": 1.0, "pts": pts}
	if not t in o["plate_toppings"]:
		o["plate_toppings"].append(t)


## Dónde se desparrama: en la mesa de pizza (Italia) o en el plato del pedido elegido
func _sprinkle_data():
	if current_station == 2 and mesa_pizza != null:
		return mesa_pizza
	return _get_order(selected_id)


func _sprinkle_view():
	if current_station == 2:
		return mesa_view if mesa_view != null and is_instance_valid(mesa_view) else null
	return plating_plate if plating_plate != null and is_instance_valid(plating_plate) else null


func _start_sprinkle(t: String) -> void:
	if _sprinkle_data() == null or paused:
		return
	if current_station == 2 and mesa_pizza != null and mesa_pizza["stretch"] < 1.0:
		_hint("Primero estirá la masa (tocala varias veces)")
		return
	sprinkle_name = t
	sprinkle_used = 0.0
	sprinkle_timer = 0.0
	var cursor := Painter.new()
	cursor.animate = true
	cursor.size = Vector2(1, 1)
	cursor.z_index = 100
	cursor.fn = func(ci, time): _draw_sprinkle_cursor(ci, time)
	add_child(cursor)
	sprinkle_cursor = cursor
	sprinkle_cursor.position = get_global_mouse_position()


func _draw_sprinkle_cursor(ci: CanvasItem, time: float) -> void:
	var o = _sprinkle_data()
	var amount := 0.0
	if o != null and o["sprinkles"].has(sprinkle_name):
		amount = o["sprinkles"][sprinkle_name]["amount"]
	var over := _sprinkle_over_food()
	# Bowl inclinado volcando el topping
	# Bowl apenas inclinado: deja caer un hilito fino
	ci.draw_set_transform(Vector2(18, -30), -0.45 if over else -0.15, Vector2.ONE)
	Art.draw_bowl(ci, Rect2(-26, -26, 52, 52), sprinkle_name)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if over:
		var info: Dictionary = Art.TOPPINGS.get(sprinkle_name, {"color": Color.WHITE, "shape": "dot"})
		if info["shape"] == "drizzle":
			# Gotitas que caen de la cuchara, de a una
			for k in 2:
				var ph := fmod(time * 1.6 + k * 0.5, 1.0)
				ci.draw_circle(Vector2(-2 + k * 1.5, -8 + ph * 20), 1.6 * (1.0 - ph * 0.4), Color(info["color"], 1.0 - ph * 0.6))
		else:
			for k in 4:
				var ph := fmod(time * 2.2 + k / 4.0, 1.0)
				ci.draw_circle(Vector2(-2 + sin(k * 2.3) * 2.5, -8 + ph * 20), 1.2, Color(info["color"], 1.0 - ph))
	# Anillo de progreso
	ci.draw_arc(Vector2(34, 10), 14, 0, TAU, 28, Color(0, 0, 0, 0.5), 5)
	ci.draw_arc(Vector2(34, 10), 14, -PI / 2, -PI / 2 + TAU * minf(amount, 1.0), 28,
		Color("5ee06a") if amount >= 1.0 else Color("ffd166"), 5)
	if not over:
		Art.text(ci, Vector2(-80, 46), "Pasalo por arriba de la comida", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 200, 4)


func _sprinkle_over_food() -> bool:
	var v = _sprinkle_view()
	if v == null:
		return false
	return v.rel_point(v.get_local_mouse_position()).length() <= 1.0


func _update_sprinkle(delta: float) -> void:
	if sprinkle_name == "":
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_sprinkle()
		return
	var o = _sprinkle_data()
	var v = _sprinkle_view()
	if o == null or v == null:
		_end_sprinkle()
		return
	sprinkle_cursor.position = get_global_mouse_position()
	if not _sprinkle_over_food():
		return
	var rel: Vector2 = v.rel_point(v.get_local_mouse_position())
	if not o["sprinkles"].has(sprinkle_name):
		o["sprinkles"][sprinkle_name] = {"amount": 0.0, "pts": []}
	var sp: Dictionary = o["sprinkles"][sprinkle_name]
	sp["amount"] += delta / Data.SPRINKLE_TIME
	sprinkle_used += delta
	var rate: Array = Art.sprinkle_rate(sprinkle_name)
	sprinkle_timer -= delta
	if sprinkle_timer <= 0.0 and sp["pts"].size() < rate[1]:
		sprinkle_timer = rate[0]
		# Las piezas caen cerca de donde está el bowl (poco salpicado)
		var jitter := Vector2.ZERO if rate[1] > 100 else Vector2.from_angle(rng.randf() * TAU) * rng.randf() * 0.07
		sp["pts"].append(rel + jitter)
	if sp["amount"] >= 1.0 and not sprinkle_name in o["plate_toppings"]:
		o["plate_toppings"].append(sprinkle_name)
		_hint("¡Listo: %s!" % sprinkle_name)
	v.queue_redraw()


func _end_sprinkle() -> void:
	if sprinkle_name == "":
		return
	var t := sprinkle_name
	sprinkle_name = ""
	if sprinkle_cursor != null and is_instance_valid(sprinkle_cursor):
		sprinkle_cursor.queue_free()
	sprinkle_cursor = null
	var o = _sprinkle_data()
	if o != null and sprinkle_used <= 0.0:
		# No lo pasó por la comida: si ya estaba puesto, el click lo saca; si no, se le explica
		if t in o["plate_toppings"]:
			o["plate_toppings"].erase(t)
			o["sprinkles"].erase(t)
			_refresh_all()
			return
		_hint("Mantené apretado el bowl y desparramalo arriba de la comida")
	elif o != null and not t in o["plate_toppings"]:
		_hint("Te faltó: seguí desparramando %s" % t.to_lower())
	_refresh_all()


func _reset_plate() -> void:
	var o = _get_order(selected_id)
	if o == null:
		return
	for e in o["plate"]:
		if not e["pantry"]:
			prepared.append(e)
	o["plate"] = []
	o["plate_sauce"] = ""
	o["plate_toppings"] = []
	o["sprinkles"] = {}
	o["plate_drink"] = ""
	_refresh_all()


func _discard_ready(idx: int) -> void:
	if idx < prepared.size():
		prepared.remove_at(idx)
		_refresh_all()


## Costo de tirar una preparación (sale de la caja)
func _waste_cost(e: Dictionary) -> int:
	if e.get("pantry", false):
		return Data.WASTE_COST["ready"]
	if e.get("chopped", false):
		return Data.WASTE_COST["chop"]
	return Data.WASTE_COST["cook"]


func _on_trash_drop(data: Dictionary) -> void:
	var cost := 0
	match data["kind"]:
		"prepared":
			var idx: int = data["index"]
			if idx >= prepared.size():
				return
			cost = _waste_cost(prepared[idx])
			prepared.remove_at(idx)
		"plate":
			var o = _get_order(selected_id)
			if o == null:
				return
			for e in o["plate"]:
				cost += _waste_cost(e)
			if o["plate_sauce"] != "":
				cost += Data.WASTE_COST["condiment"]
			cost += o["sprinkles"].size() * Data.WASTE_COST["condiment"]
			if o.get("plate_drink", "") != "":
				cost += Data.WASTE_COST["ready"]
			o["plate"] = []
			o["plate_sauce"] = ""
			o["plate_toppings"] = []
			o["sprinkles"] = {}
			o["plate_drink"] = ""
	money -= cost
	_refresh_all()
	if cost > 0:
		_hint("Tiraste comida: -$%d de la caja" % cost)


# =====================================================================
# Entrega y puntaje
# =====================================================================

func _deliver() -> void:
	var o = _get_order(selected_id)
	if o == null or o["plate"].is_empty():
		return

	# Componentes: ¿están los que pidió y nada de más? ¿y qué tan bien cocidos?
	var leftovers: Array = o["plate"].duplicate()
	var hits := 0
	var qualities := []
	for entry in o["items"]:
		for k in leftovers.size():
			var e: Dictionary = leftovers[k]
			if e["item"] == entry["item"]:
				hits += 1
				# La cocción se juzga contra el punto que pidió ESTE cliente
				var q := 100.0
				if e.has("ta"):
					q = _pizza_quality(e, _target_for(o, e["item"]))
					if e.get("pizza", {}).get("stretch", 0.0) < 1.0:
						q *= 0.5      # la masa no estaba bien estirada
				elif e.get("t", -1.0) >= 0.0:
					q = _cook_quality(e["t"], _target_for(o, e["item"]), e["burn"])
					q *= Data.salt_factor(e["item"], e.get("salt", 0.0))   # bien salado (o sin sal si no lleva)
				if e.get("dirty", false):
					q *= Data.DIRTY_FOOD     # se cocinó con un utensilio sucio
				qualities.append(q)
				leftovers.remove_at(k)
				break
	var needed: int = o["items"].size()
	var s_items := 100.0 * hits / (needed + leftovers.size())
	var s_cook := 0.0
	for q in qualities:
		s_cook += q
	if not qualities.is_empty():
		s_cook /= qualities.size()

	var plate_sauce: String = o["plate_sauce"]
	var put: Array = o["plate_toppings"]
	if Data.RECIPES[o["recipe"]].get("prebuilt", false):
		# Pizza: la salsa y los ingredientes son los que se pusieron en la mesa, antes del horno
		plate_sauce = ""
		put = []
		for e in o["plate"]:
			if e.get("item", "") == "pizza":
				plate_sauce = e["pizza"].get("sauce", "")
				put = e["pizza"].get("plate_toppings", [])
				break
	var s_sauce := 100.0 if plate_sauce == o["sauce"] else 0.0

	var wanted: Array = o["toppings"]
	var union := {}
	var top_hits := 0
	for t in wanted:
		union[t] = true
		if t in put:
			top_hits += 1
	for t in put:
		union[t] = true
	var s_tops := 100.0 if union.is_empty() else 100.0 * top_hits / union.size()

	var wait: float = elapsed - o["arrived"]
	var patience: float = _patience()
	var s_wait := clampf(100.0 - maxf(0.0, wait - patience) * 1.0, 0.0, 100.0)

	var total := s_items * 0.3 + s_cook * 0.3 + s_sauce * 0.1 + s_tops * 0.1 + s_wait * 0.2
	var s_drink := -1.0
	if o.get("drink", "") != "":
		# Con bebida: pesa un 10% y el resto se reparte en proporción
		s_drink = 100.0 if o.get("plate_drink", "") == o["drink"] else 0.0
		total = total * 0.9 + s_drink * 0.1
	var dirty_plate := not _take_tool("plato")
	if dirty_plate:
		total *= Data.DIRTY_PLATE
	dirty.append("plato")      # el plato vuelve sucio a la bacha
	var tip := int(round(total / 10.0))
	if s_drink >= 100.0:
		tip += 3
	if _has("caramelera"):
		tip += 1
	if _has("vajilla"):
		tip += 3
	var pay := 15 + tip

	var verdict := "Mmm... no vuelvo"
	if total >= 90.0:
		verdict = "¡Espectacular!"
	elif total >= 75.0:
		verdict = "Muy rico"
	elif total >= 55.0:
		verdict = "Zafa"

	last_result = {
		"name": o["name"], "look": o["look"], "total": total, "verdict": verdict, "pay": pay, "tip": tip,
		"lines": ["Ingredientes %d" % int(s_items), "Cocción %d" % int(s_cook), "Salsa %d" % int(s_sauce),
			"Toppings %d" % int(s_tops), "Espera %d" % int(s_wait)],
	}
	if dirty_plate:
		last_result["lines"].append("¡Plato sucio! -25%")

	served += 1
	score_sum += total
	money += pay
	_play_sfx("caja")
	# Lo que sigue en la cocina o en la bandeja queda disponible para los otros pedidos.
	orders.erase(o)
	selected_id = orders[0]["id"] if not orders.is_empty() else -1
	_refresh_all()


# =====================================================================
# Interfaz general
# =====================================================================

func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 18
	th.set_stylebox("normal", "Button", _sb(Color("f6e7c8"), Color("8a5a2b")))
	th.set_stylebox("hover", "Button", _sb(Color("fff4de"), Color("8a5a2b")))
	th.set_stylebox("pressed", "Button", _sb(Color("e9d2a6"), Color("8a5a2b")))
	th.set_stylebox("disabled", "Button", _sb(Color(0.85, 0.8, 0.72, 0.55), Color(0.5, 0.4, 0.3, 0.4)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		th.set_color(c, "Button", COL_INK)
	th.set_color("font_disabled_color", "Button", Color(0.35, 0.28, 0.2, 0.6))
	th.set_constant("icon_max_width", "Button", 40)
	th.set_constant("h_separation", "Button", 10)
	return th


func _sb(bg: Color, border: Color, radius := 10, bw := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var draw_hud := func(ci, _t):
		Art.wood(ci, Rect2(0, 0, 1280, 44), Color("7a4a2a"), 22)
		ci.draw_rect(Rect2(0, 40, 1280, 4), Color(0, 0, 0, 0.35))
	_painter(Rect2(0, 0, 1280, 44), draw_hud, false, self)
	lbl_level = _label("", 22, Color.WHITE, 5)
	lbl_level.position = Vector2(14, 6)
	add_child(lbl_level)
	lbl_customers = _label("", 19, Color.WHITE, 5)
	lbl_customers.position = Vector2(830, 9)
	add_child(lbl_customers)
	lbl_money = _label("", 19, Color("ffe08a"), 5)
	lbl_money.position = Vector2(1110, 9)
	add_child(lbl_money)
	music_button = _button("", _toggle_music, 14)
	music_button.position = Vector2(700, 5)
	music_button.tooltip_text = "Prender o apagar la música (tecla M)"
	add_child(music_button)
	pause_button = _button("Pausa", _toggle_pause, 14)
	pause_button.position = Vector2(450, 5)
	pause_button.tooltip_text = "Pausar el día (P o Esc)"
	add_child(pause_button)
	sfx_button = _button("", _toggle_sfx, 14)
	sfx_button.position = Vector2(560, 5)
	sfx_button.tooltip_text = "Prender o apagar los sonidos de la cocina"
	add_child(sfx_button)

	var draw_rail := func(ci, _t):
		Art.grad_rect(ci, Rect2(0, 0, 1280, 140), Color("4a4f55"), Color("2f3338"))
		Art.grad_rect(ci, Rect2(0, 4, 1280, 9), Color("e3e8ec"), Color("8d98a3"))
		ci.draw_rect(Rect2(0, 13, 1280, 3), Color(0, 0, 0, 0.3))
	_painter(Rect2(0, 44, 1280, 140), draw_rail, false, self)
	ticket_rail = HBoxContainer.new()
	ticket_rail.position = Vector2(10, 52)
	ticket_rail.size = Vector2(1260, 128)
	ticket_rail.add_theme_constant_override("separation", 8)
	add_child(ticket_rail)
	close_button = _button("Cerrar el local", _close_now, 20)
	close_button.position = Vector2(900, 92)
	close_button.visible = false
	add_child(close_button)

	station_box = Control.new()
	station_box.position = Vector2(0, 184)
	station_box.size = STATION_SIZE
	station_box.clip_contents = true
	add_child(station_box)

	var draw_tabs := func(ci, _t): Art.wood(ci, Rect2(0, 0, 1280, 70), Color("5e3a22"), 35)
	_painter(Rect2(0, 650, 1280, 70), draw_tabs, false, self)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(8, 656)
	tabs.size = Vector2(1264, 58)
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	for i in STATIONS.size():
		var b := _button("", _go_to_station.bind(i), 19)
		b.icon = Art.tex(TAB_ICONS[i])
		b.expand_icon = false
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		tab_buttons.append(b)


func _refresh_all() -> void:
	_refresh_tickets()
	_refresh_station()
	_update_hud()
	_update_tabs()


func _update_hud() -> void:
	lbl_level.text = level.get("name", "")
	lbl_customers.text = "Servidos: %d/%d" % [served, level.get("customers", 0)] + ("  (se fueron %d)" % lost if lost > 0 else "")
	lbl_money.text = "Caja: $%d" % money
	lbl_money.add_theme_color_override("font_color", Color("ff8a7a") if money < 0 else Color("ffe08a"))


func _update_tabs() -> void:
	var smoking := false
	for a in cookers:
		for s in cookers[a]:
			if s != null and s["t"] >= s["burn"] - 3.0:
				smoking = true
	for i in tab_buttons.size():
		var txt := "%d · %s" % [i + 1, "Mesa" if i == 2 and _uses_mesa() else STATIONS[i]]
		if i == 0 and not queue.is_empty():
			txt += " (%d)" % queue.size()
		if i == 1 and smoking:
			txt += " ¡se quema!"
		if i == 2 and board != null:
			txt += " (cortando)"
		var piling: bool = i == 5 and wash_alert >= 1
		if i == 5 and _dirty_count() > 0:
			txt += (" ¡%d sucios!" if piling else " (%d)") % _dirty_count()
		var b: Button = tab_buttons[i]
		b.text = txt
		if i == current_station:
			b.add_theme_stylebox_override("normal", _sb(COL_SELECTED, Color("8a5a2b"), 10, 3))
			b.add_theme_stylebox_override("hover", _sb(COL_SELECTED.lightened(0.2), Color("8a5a2b"), 10, 3))
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
		if piling and i != current_station:
			# Se apilan los sucios: la pestaña se pone colorada (y titila si es urgente)
			var hot: bool = wash_alert == 1 or fmod(elapsed, 1.0) < 0.5
			b.add_theme_stylebox_override("normal", _sb(Color("f6b3a2") if hot else Color("f6e7c8"), Color("c0281a"), 10, 3))
		if (i == 1 and smoking) or piling:
			b.add_theme_color_override("font_color", Color("c0281a"))
		else:
			b.remove_theme_color_override("font_color")


func _go_to_station(i: int) -> void:
	_end_sprinkle()
	current_station = i
	_refresh_station()
	_update_tabs()


func _select_order(id: int) -> void:
	selected_id = id
	_refresh_all()


# --- Tickets ---

func _refresh_tickets() -> void:
	_clear(ticket_rail)
	ticket_labels.clear()
	ticket_heads.clear()
	if orders.is_empty():
		ticket_rail.add_child(_label("Sin pedidos. Andá a Pedidos (tecla 1) a atender el mostrador.", 18, Color(1, 1, 1, 0.8), 4))
		return
	for o in orders:
		var b := _button("", _select_order.bind(o["id"]), 13)
		b.custom_minimum_size = Vector2(200, 126)
		var sel: bool = o["id"] == selected_id
		var sb := _sb(COL_SELECTED if sel else COL_PAPER, Color("c9a86a") if not sel else Color("b07a10"), 4, 3 if sel else 1)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
		var lbl := _label("", 13, COL_INK)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.offset_left = 8
		lbl.offset_top = 4
		lbl.offset_right = -6
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_child(lbl)
		var head := CustomerView.new()
		head.look = o["look"]
		head.head_only = true
		head.scale_factor = 0.62
		head.position = Vector2(150, 2)
		head.size = Vector2(46, 46)
		b.add_child(head)
		ticket_rail.add_child(b)
		ticket_labels[o["id"]] = lbl
		ticket_heads[o["id"]] = head
	_update_ticket_texts()


func _update_ticket_texts() -> void:
	for o in orders:
		if ticket_labels.has(o["id"]):
			ticket_labels[o["id"]].text = _ticket_text(o)
			ticket_heads[o["id"]].mood = _mood(elapsed - o["arrived"])


func _ticket_text(o) -> String:
	var wait := int(elapsed - o["arrived"])
	var head := "#%d %s · %ds" % [o["id"], o["name"], wait]
	if _mood(wait) >= 3:
		head = "#%d %s · ¡se va en %ds!" % [o["id"], o["name"], maxi(0, int(_patience() * Data.LEAVE_FACTOR) - wait)]
	var lines := [head,
		Data.RECIPES[o["recipe"]]["name"].to_upper()]
	for entry in o["items"]:
		lines.append("· %s %s" % [_req_text(entry), _item_progress(o, entry["item"])])
	if not Data.RECIPES[o["recipe"]]["sauces"].is_empty():
		lines.append("Salsa: " + (o["sauce"] if o["sauce"] != "" else "sin salsa"))
	var tops: Array = o["toppings"]
	if not tops.is_empty():
		lines.append("+ " + ", ".join(PackedStringArray(tops)))
	if o.get("drink", "") != "":
		lines.append("Bebida: " + o["drink"])
	return "\n".join(PackedStringArray(lines))


func _req_text(entry) -> String:
	var txt: String = Data.ITEMS[entry["item"]]["name"]
	if entry["doneness"] != "":
		txt += " " + entry["doneness"]
	return txt


func _item_progress(o, item_id: String) -> String:
	for e in o["plate"]:
		if e["item"] == item_id:
			return "(plato)"
	for e in prepared:
		if e["item"] == item_id:
			return "(bandeja)"
	for a in cookers:
		for s in cookers[a]:
			if s != null and s["item"] == item_id:
				return "(cocinando)"
	if board != null and board["item"] == item_id:
		return "(cortando)"
	return ""


# =====================================================================
# Estaciones
# =====================================================================

func _refresh_station() -> void:
	_clear(station_box)
	customer_views.clear()
	kitchen_views.clear()
	mesa_view = null
	sink_view = null
	rack_view = null
	plating_plate = null
	take_button = null
	board_view = null
	board_info = null
	if not playing:
		return
	match current_station:
		0: _build_orders_station()
		1: _build_kitchen_station()
		2: _build_mesa_station() if _uses_mesa() else _build_board_station()
		3: _build_plating_station()
		4: _build_delivery_station()
		5: _build_sink_station()
	# Luz ambiente por encima de todo (no bloquea el mouse)
	var light := func(ci, _t): Art.draw_lighting(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), light, false)


# --- 1. Mostrador ---

func _build_orders_station() -> void:
	var menu := []
	for r in recipes:
		menu.append(Data.RECIPES[r]["name"])
	var draw_bg := func(ci, t): Art.draw_dining(ci, Rect2(Vector2.ZERO, STATION_SIZE), menu, t, owned, current_country)
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, true)

	for wk in walkers:
		_add_customer_view(wk, false)
	for i in range(queue.size() - 1, -1, -1):
		_add_customer_view(queue[i], true)

	# La moza del mostrador, con libreta y birome
	if waiter_look.is_empty():
		waiter_look = Art.waiter_look()
	var waiter := CustomerView.new()
	waiter.look = waiter_look
	waiter.scale_factor = 1.25
	waiter.size = Vector2(240, 320)
	waiter.position = Vector2(WAITER_X - 120, 24)
	station_box.add_child(waiter)
	customer_views.append({"src": {}, "v": waiter, "queued": false, "waiter": true})

	var has_candy := _has("caramelera")
	var draw_front := func(ci, _t):
		Art.draw_counter(ci, Rect2(0, 0, 1280, 236), 88, current_country)
		Art.draw_tex(ci, Art.tex("kitchen/register"), Rect2(900, -6, 130, 100))
		if has_candy:
			Art.candy_jar(ci, Rect2(1060, 20, 60, 70))
	_painter(Rect2(0, 230, 1280, 236), draw_front, false)

	take_button = _prop(Rect2(420, 336, 150, 120))
	take_button.texture = Art.tex("kitchen/notepad")
	take_button.text = "Tomar pedido"
	take_button.text_size = 15
	take_button.pressed.connect(_begin_take_order)

	if queue.is_empty():
		var msg := "No hay nadie esperando."
		if spawned >= level["customers"]:
			msg = "Ya no entran más clientes hoy: terminá los pedidos que quedan."
		var t := _tag(msg, Vector2(0, 0), 18)
		t.position = Vector2(640 - t.get_minimum_size().x / 2.0, 250)
	_update_customer_views()


func _add_customer_view(src: Dictionary, queued: bool) -> void:
	var v := CustomerView.new()
	v.look = src["look"]
	v.scale_factor = 1.25
	v.size = Vector2(240, 320)
	v.position = Vector2(src["x"] - 120, 24)
	station_box.add_child(v)
	if queued:
		v.clicked.connect(_begin_take_order)
	else:
		v.bubble_lift = 46.0
		v.bubble_while_walking = true
	customer_views.append({"src": src, "v": v, "queued": queued})


func _update_customer_views() -> void:
	var first_ready := not queue.is_empty() and absf(queue[0]["x"] - _queue_x(0)) < 2.0
	var writing := not pending_order.is_empty()
	waiter_look["writing"] = writing
	for cv in customer_views:
		var v = cv["v"]
		if not is_instance_valid(v):
			continue
		if cv.get("waiter", false):
			v.bubble = "Anotado..." if writing else ("¡Buenas! ¿Qué le sirvo?" if first_ready else "")
			v.bubble_lift = 0.0
			continue
		var src: Dictionary = cv["src"]
		v.position.x = src["x"] - 120
		if cv["queued"]:
			var i := queue.find(src)
			if i == -1:
				v.visible = false
				continue
			v.walking = absf(src["x"] - _queue_x(i)) > 2.0
			v.mood = _mood(elapsed - src["arrived"])
			var is_first: bool = i == 0 and first_ready
			v.clickable = is_first and not writing
			v.bubble = ""
			v.bubble_lift = 46.0 if i % 2 == 1 else 0.0   # alternar alturas para que no se pisen
			if is_first and writing:
				v.bubble = _order_speech(pending_order)
				v.bubble_lift = 46.0
			elif is_first and v.mood >= 1:
				v.bubble = _wait_line(src, v.mood)
			elif not is_first and v.mood >= 2 and (int(elapsed / 5.0) + i) % 3 == 0:
				v.bubble = _wait_line(src, v.mood)   # los de atrás también se quejan, de a ratos
		else:
			var leaving: bool = src.get("dir", 1) < 0
			v.mood = src.get("mood", 0)
			v.walking = leaving or src["x"] > _queue_x(0) + 20.0
			v.bubble = src["bubble"] if leaving or src["x"] < WAITER_X - 60.0 else ""
	if take_button != null:
		take_button.visible = first_ready and not writing


# --- 2. Cocina ---

func _build_kitchen_station() -> void:
	var o = _get_order(selected_id)
	var draw_bg := func(ci, _t): Art.draw_kitchen_wall(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var header := "Lo que cocines va a la bandeja y sirve para cualquier pedido"
	if o != null:
		header = "Ticket #%d %s: %s  ·  lo cocinado va a la bandeja compartida" % [o["id"], o["name"], Data.RECIPES[o["recipe"]]["name"]]
	_tag(header, Vector2(12, 4), 15)

	var cook_items := _unlocked_items("cook")
	var used := Data.APPLIANCE_ORDER.filter(func(a):
		return not cook_items.filter(func(id): return Data.ITEMS[id]["where"] == a).is_empty())
	# Con muchos aparatos se achican un poco para que la heladera tenga lugar
	var k: float = [1.0, 1.0, 1.0, 0.92, 0.82][used.size()]
	var x := 12.0
	for a in used:
		var av := ApplianceView.new()
		av.kind = a
		av.slots = cookers[a]
		av.show_zone = level["show_zone"] or _has("reloj")
		av.position = Vector2(x, 36)
		av.size = Vector2(236, 330)
		av.scale = Vector2(k, k)
		av.slot_clicked.connect(_on_slot_clicked.bind(a))
		av.ingredient_dropped.connect(_on_ingredient_to_appliance.bind(a))
		station_box.add_child(av)
		kitchen_views.append(av)
		x += 236.0 * k + 10.0

	var book_btn := _button("Recetario general (R)", _toggle_recipes, 13)
	book_btn.position = Vector2(STATION_SIZE.x - 176, 1)
	book_btn.tooltip_text = "Tiempos de cocción y temperaturas de todo el menú"
	station_box.add_child(book_btn)

	# Abajo de los aparatos: la receta del ticket elegido
	var top := 36.0 + 330.0 * k + 6.0
	_build_order_recipe(o, Rect2(12, top, x - 110.0, STATION_SIZE.y - top - 4.0))
	# Salero: se mantiene apretado y se sacude encima de la plancha o la olla
	var shaker := _prop(Rect2(x - 94.0, top, 84.0, STATION_SIZE.y - top - 4.0))
	shaker.draw_fn = func(ci, r): Art.salt_shaker(ci, r.get_center() + Vector2(0, 4), minf(r.size.y / 50.0, 1.6), -0.2, false, 0.0)
	shaker.text = "Salero"
	shaker.text_size = 12
	shaker.mouse_default_cursor_shape = Control.CURSOR_DRAG
	shaker.tooltip_text = "Mantené apretado y sacudilo encima de lo que está en la plancha o la olla"
	shaker.held.connect(_start_salting)

	# Heladera con los ingredientes crudos: se arrastran hasta el aparato que corresponde
	var fx := x + 4.0
	var fw := STATION_SIZE.x - fx - 10.0
	var fridge_items := cook_items.filter(func(id): return not Data.ITEMS[id].get("built", false))   # la pizza se arma en la mesa
	var n := fridge_items.size()
	# Agrupados por tipo: carnes con carnes, pastas con pastas, verduras con verduras (un estante cada uno)
	var groups := []
	var placed := []
	for g in Data.FRIDGE_GROUPS:
		var ids: Array = g[1].filter(func(id): return id in fridge_items)
		if not ids.is_empty():
			groups.append([g[0], ids])
			placed.append_array(ids)
	var rest := fridge_items.filter(func(id): return not id in placed)
	if not rest.is_empty():
		groups.append(["Otros", rest])
	var cols := clampi(int(fw / 100.0), 1, maxi(n, 1))
	var total_rows := 0
	for g in groups:
		total_rows += int(ceil(g[1].size() / float(cols)))
	var cw := minf(fw / cols, 140.0)
	var head_h := 18.0
	var ch := minf((392.0 - head_h * groups.size()) / maxi(total_rows, 1), 120.0)
	var shelves := []      # [y del título, nombre, y del estante]
	var y0 := 30.0
	for g in groups:
		var rows_g := int(ceil(g[1].size() / float(cols)))
		shelves.append([y0, g[0], y0 + head_h + rows_g * ch])
		y0 += head_h + rows_g * ch
	var draw_fridge := func(ci, _t):
		Art.rrect(ci, Rect2(0, 0, fw, 430), Color("dfe5ea"), 10, Color("9aa3ab"), 4)
		Art.rrect(ci, Rect2(8, 26, fw - 16, 396), Color("f6f9fb"), 6)
		Art.text(ci, Vector2(0, 19), "HELADERA · arrastrá a la cocina", 13, Color("4a5560"), HORIZONTAL_ALIGNMENT_CENTER, fw)
		for s in shelves:
			Art.rrect(ci, Rect2(14, s[0] + 1, fw - 28, head_h - 3), Color(0.78, 0.84, 0.88, 0.6), 4)
			Art.text(ci, Vector2(20, s[0] + 13), s[1].to_upper(), 11, Color("4a5560"))
			ci.draw_rect(Rect2(8, s[2] - 4, fw - 16, 4), Color("c5ccd2"))
	_painter(Rect2(fx, 30, fw, 430), draw_fridge, false)
	if n == 0 and _uses_mesa():
		var note := _label("Hoy en la cocina solo va el horno de leña.\n\nLa pizza se arma en la Mesa (tecla 3):\nestirás la masa, ponés salsa e ingredientes\ny la mandás al horno.", 18, Color(0.3, 0.32, 0.36))
		note.position = Vector2(fx + 30, 150)
		station_box.add_child(note)
	for gi in groups.size():
		var ids: Array = groups[gi][1]
		var gy: float = 30.0 + shelves[gi][0] + head_h
		for j in ids.size():
			var id: String = ids[j]
			var b := _prop(Rect2(fx + (fw - cw * cols) / 2.0 + (j % cols) * cw, gy + (j / cols) * ch, cw, ch - 6))
			b.texture = Art.food_raw(id)
			b.text = Data.ITEMS[id]["name"]
			b.text_size = 13
			b.tooltip_text = "Arrastralo hasta %s" % Data.APPLIANCES[Data.ITEMS[id]["where"]]["name"].to_lower()
			b.drag_data = {"kind": "raw", "item": id}
			b.pressed.connect(_drag_hint.bind(id))
	recipe_panel = null


## Heladera de bebidas de la Entrega: se arrastra la bebida hasta la bandeja (o click)
func _build_drinks_fridge(o, rect: Rect2) -> void:
	var draw_fridge := func(ci, _t):
		Art.rrect(ci, Rect2(Vector2.ZERO, rect.size), Color("dfe5ea"), 8, Color("9aa3ab"), 3)
		Art.rrect(ci, Rect2(6, 22, rect.size.x - 12, rect.size.y - 28), Color("eaf4f8"), 5)
		Art.text(ci, Vector2(0, 16), "BEBIDAS", 12, Color("4a5560"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		for r in 3:
			ci.draw_rect(Rect2(6, 22 + (r + 1) * 86 - 3, rect.size.x - 12, 3), Color("c5ccd2"))
		ci.draw_rect(Rect2(6, 22, rect.size.x - 12, rect.size.y - 28), Color(0.7, 0.85, 1.0, 0.12))
	_painter(rect, draw_fridge, false)
	var names: Array = Data.DRINKS.keys()
	for k in names.size():
		var n: String = names[k]
		var b := _prop(Rect2(rect.position.x + 6 + (k % 2) * 57, rect.position.y + 24 + (k / 2) * 86, 57, 82))
		b.draw_fn = func(ci, rr): Art.draw_drink(ci, rr, n, Data.DRINKS)
		b.text = n
		b.text_size = 9
		b.selected = o.get("plate_drink", "") == n
		b.drag_data = {"kind": "drink", "name": n}
		b.tooltip_text = "Arrastrá %s hasta la bandeja" % n.to_lower()
		b.pressed.connect(_on_plate_drop.bind({"kind": "drink", "name": n}))


## Receta del pedido elegido: un paso por ingrediente (dónde va, a qué punto y cómo viene) y lo del emplatado.
func _build_order_recipe(o, rect: Rect2) -> void:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PAPER
	sb.set_corner_radius_all(8)
	sb.border_color = Color("c9a86a")
	sb.set_border_width_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(2, 3)
	card.add_theme_stylebox_override("panel", sb)
	card.position = rect.position
	card.size = rect.size
	card.custom_minimum_size = rect.size
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	station_box.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	if o == null:
		box.add_child(_label("RECETA · Elegí un ticket de arriba para ver acá qué lleva ese pedido.", 14, COL_INK))
		return
	var r: Dictionary = Data.RECIPES[o["recipe"]]
	box.add_child(_label("RECETA de #%d %s — %s" % [o["id"], o["name"], r["name"]], 14, COL_INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	var compact := rect.size.y < 110.0
	var n := 1
	for entry in o["items"]:
		row.add_child(_recipe_step(n, o, entry, compact))
		n += 1
	# Lo que va al emplatar
	var fin := []
	if not r["sauces"].is_empty():
		fin.append("Salsa: " + (o["sauce"] if o["sauce"] != "" else "sin salsa"))
	var tops: Array = o["toppings"]
	if not tops.is_empty():
		fin.append("Toppings: " + ", ".join(PackedStringArray(tops)))
	if o.get("drink", "") != "":
		fin.append("Bebida (en la Entrega): " + o["drink"])
	if not fin.is_empty():
		var step := VBoxContainer.new()
		step.add_theme_constant_override("separation", 0)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.add_child(_label("%d. %s" % [n, "En la mesa (antes del horno)" if r.get("prebuilt", false) else "Al emplatar"], 12, COL_INK))
		var l := _label("\n".join(PackedStringArray(fin)), 11, Color(0.3, 0.24, 0.18))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(120, 0)
		step.add_child(l)
		row.add_child(step)


func _recipe_step(n: int, o, entry: Dictionary, compact: bool) -> Control:
	var id: String = entry["item"]
	var info: Dictionary = Data.ITEMS[id]
	var step := HBoxContainer.new()
	step.add_theme_constant_override("separation", 4)
	step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pic := PropButton.new()
	pic.custom_minimum_size = Vector2(40, 40) if compact else Vector2(56, 56)
	pic.texture = Art.food_raw(id) if info["kind"] == "cook" else Art.food(id)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	step.add_child(pic)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2 if compact else 2)
	step.add_child(col)
	var fs := 0 if compact else 2   # con más lugar, letra más grande
	col.add_child(_label("%d. %s" % [n, _req_text(entry)], 12 + fs, COL_INK))
	var how := ""
	match info["kind"]:
		"cook":
			var where: String = Data.APPLIANCES[info["where"]]["name"]
			if id == "pizza":
				where = "Mesa: estirar y armar · Horno de leña: girala"
			if info.has("temps"):
				var temp: int = info.get("target_temp", 0)
				if entry["doneness"] != "":
					temp = info["doneness_temp"][entry["doneness"]]
				how = "%s · sacar a %d°C" % [where, temp]
			else:
				how = "%s · %d segundos" % [where, int(round(_target_for(o, id) * Data.COOK_SLOW))]
			if info.get("salt", false):
				how += " · con sal"
			elif info["where"] in ["plancha", "olla"]:
				how += " · ¡sin sal!"
		"chop":
			var cuts: int = info["cuts"]
			if _has("procesadora"):
				cuts = int(ceil(cuts / 2.0))
			how = "Tabla · %d cortes" % cuts
		"ready":
			how = "Despensa (en Emplatado)"
	col.add_child(_label(how, 11 + fs, Color("2f5d50")))
	var status := _item_progress(o, id)
	if status == "":
		status = "(falta)"
	col.add_child(_label(status, 11 + fs, Color("b0501a") if status == "(falta)" else Color("2f7a3a")))
	return step


func _toggle_recipes() -> void:
	if recipe_panel != null and is_instance_valid(recipe_panel):
		recipe_panel.queue_free()
		recipe_panel = null
		return
	if current_station != 1:
		return
	var lines := []
	for id in _unlocked_items("cook"):
		lines.append(_cook_time_text(id))
	var txt := "RECETARIO\n\n" + "\n".join(PackedStringArray(lines))
	txt += "\n\nLas carnes se miden con el termómetro: sacalas cuando llegan a la temperatura del punto pedido."
	recipe_panel = _card(Rect2(300, 30, 520, 400), txt, 15)
	recipe_panel.clip_text = false
	var close := _button("Cerrar", _toggle_recipes, 14)
	close.position = Vector2(720, 390)
	recipe_panel.add_child(close)
	close.position = Vector2(420, 350)


# --- 3 (Italia). Mesa de pizza ---

func _uses_mesa() -> bool:
	return Data.COUNTRIES[current_country].get("prep", "") == "mesa"


func _build_mesa_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var o = _get_order(selected_id)
	var head := "Mesa de pizza  ·  estirá la masa, poné salsa e ingredientes y mandala al horno de leña"
	if o != null:
		var tops_o: Array = o["toppings"]
		head = "Ticket #%d %s: %s%s" % [o["id"], o["name"], Data.RECIPES[o["recipe"]]["name"],
			(" con " + o["sauce"].to_lower()) if o["sauce"] != "" else ""]
		if not tops_o.is_empty():
			head += " + " + ", ".join(PackedStringArray(tops_o))
	_tag(head, Vector2(12, 4), 15)
	# Izquierda: bollos de masa
	_tag("Masa", Vector2(24, 44), 15)
	var dough := _prop(Rect2(20, 74, 150, 130))
	dough.draw_fn = func(ci, r): Art.draw_dough(ci, r)
	dough.text = "Bollo de masa"
	dough.text_size = 14
	dough.drag_data = {"kind": "dough"}
	dough.tooltip_text = "Arrastralo a la mesa (o tocalo)"
	dough.pressed.connect(_mesa_place_dough)
	if mesa_pizza != null:
		var drop := _button("Tirar la masa", _mesa_discard, 14)
		drop.position = Vector2(30, 230)
		station_box.add_child(drop)
	# Centro: la mesa con la pizza
	mesa_view = MesaView.new()
	mesa_view.position = Vector2(200, 40)
	mesa_view.size = Vector2(440, 420)
	mesa_view.pizza = mesa_pizza
	mesa_view.tapped.connect(_mesa_tap)
	mesa_view.dropped.connect(_mesa_drop)
	station_box.add_child(mesa_view)
	# Derecha: salsas, ingredientes y el horno
	var x0 := 680.0
	_tag("Salsa (arrastrala a la masa)", Vector2(x0, 44), 15)
	var sauces := _cat_options("Pizzas", "sauces")
	for k in sauces.size():
		var s: String = sauces[k]
		var b := _prop(Rect2(x0 + k * 90, 74, 84, 96))
		var col: Color = Art.SAUCE_COLORS.get(s, Color.WHITE)
		b.draw_fn = func(ci, rr): Art.draw_bottle(ci, rr, col)
		b.text = s
		b.text_size = 11
		b.selected = mesa_pizza != null and mesa_pizza["sauce"] == s
		b.drag_data = {"kind": "sauce", "name": s}
		b.pressed.connect(_hint.bind("Arrastrá la salsa hasta la masa"))
	_tag("Ingredientes (mantené y desparramá)", Vector2(x0, 182), 15)
	var tops := _cat_options("Pizzas", "toppings")
	for k in tops.size():
		var tname: String = tops[k]
		var b := _prop(Rect2(x0 + (k % 6) * 88, 212 + (k / 6) * 88, 84, 84))
		b.draw_fn = func(ci, rr): Art.draw_bowl(ci, rr, tname)
		b.selected = mesa_pizza != null and tname in mesa_pizza["plate_toppings"]
		b.mouse_default_cursor_shape = Control.CURSOR_DRAG
		b.tooltip_text = "%s: mantené apretado y pasalo por arriba de la masa" % tname
		b.held.connect(_start_sprinkle.bind(tname))
	var oven := _button("¡Al horno de leña!", _mesa_to_oven, 22)
	oven.position = Vector2(x0 + 150, 400)
	oven.custom_minimum_size = Vector2(280, 54)
	oven.disabled = mesa_pizza == null or mesa_pizza["stretch"] < 1.0
	station_box.add_child(oven)


func _mesa_place_dough() -> void:
	if mesa_pizza != null:
		_hint("Ya hay una masa en la mesa")
		return
	mesa_pizza = {"stretch": 0.0, "sauce": "", "sprinkles": {}, "plate_toppings": []}
	_refresh_station()


func _mesa_tap() -> void:
	if mesa_pizza == null:
		_hint("Arrastrá un bollo de masa a la mesa")
		return
	if mesa_pizza["stretch"] >= 1.0:
		return
	mesa_pizza["stretch"] = minf(1.0, mesa_pizza["stretch"] + 1.0 / 6.0)
	if mesa_pizza["stretch"] > 0.99:
		mesa_pizza["stretch"] = 1.0     # sin errores de redondeo: 6 toques = estirada
	_play_sfx("corte%d" % (rng.randi() % 3 + 1), -4.0)
	if mesa_view != null and is_instance_valid(mesa_view):
		mesa_view.bump()
	if mesa_pizza["stretch"] >= 1.0:
		_hint("¡Masa estirada! Ahora la salsa y los ingredientes")
		_refresh_station()


func _mesa_drop(data: Dictionary) -> void:
	match data["kind"]:
		"dough":
			_mesa_place_dough()
		"sauce":
			if mesa_pizza == null or mesa_pizza["stretch"] < 1.0:
				_hint("Primero estirá la masa")
				return
			mesa_pizza["sauce"] = data["name"]
			_refresh_station()


func _mesa_to_oven() -> void:
	if mesa_pizza == null or mesa_pizza["stretch"] < 1.0:
		return
	var slots: Array = cookers["horno_lena"]
	var idx := slots.find(null)
	if idx == -1:
		_hint("El horno de leña está lleno")
		return
	var info: Dictionary = Data.ITEMS["pizza"]
	slots[idx] = {"item": "pizza", "t": 0.0, "ta": 0.0, "tb": 0.0, "target": info["target"], "burn": info["burn"],
		"pizza": mesa_pizza, "rot": 0.0, "rot_vis": 0.0}
	mesa_pizza = null
	_hint("¡Al horno! Girala con la pala a mitad de cocción")
	slots[idx]["dirty_tool"] = not _take_tool("pala")
	slots[idx]["tool_last"] = tool_last
	_refresh_all()


func _mesa_discard() -> void:
	if mesa_pizza == null:
		return
	mesa_pizza = null
	money -= Data.WASTE_COST["ready"]
	_hint("Tiraste la masa: -$%d de la caja" % Data.WASTE_COST["ready"])
	_refresh_all()


func _cook_time_text(id: String) -> String:
	var info: Dictionary = Data.ITEMS[id]
	if id == "pizza":
		return "Pizza: %ds en el horno de leña (girala a la mitad)" % int(round(info["target"] * Data.COOK_SLOW * 1.0))
	if info.has("doneness_temp"):
		var parts := []
		for dn in info["doneness_temp"]:
			parts.append("%s %d°C" % [dn, int(info["doneness_temp"][dn])])
		return "%s: %s" % [info["name"], " · ".join(PackedStringArray(parts))]
	if info.has("target_temp"):
		return "%s: %d°C (termómetro)" % [info["name"], int(info["target_temp"])]
	return "%s: %ds" % [info["name"], int(round(info["target"] * Data.COOK_SLOW))]


# --- 3. Tabla ---

func _build_board_station() -> void:
	var o = _get_order(selected_id)
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var chop_items := _unlocked_items("chop")
	if chop_items.is_empty():
		_tag("Todavía no hay nada para cortar en el menú de hoy.", Vector2(20, 8), 18)
		return
	var head := "Tabla de cortar  ·  lo cortado va a la bandeja compartida"
	if o != null:
		head = "Ticket #%d %s: %s  ·  lo cortado va a la bandeja" % [o["id"], o["name"], Data.RECIPES[o["recipe"]]["name"]]
	_tag(head, Vector2(12, 4), 15)

	for j in chop_items.size():
		var id: String = chop_items[j]
		var b := _prop(Rect2(24 + (j % 2) * 116, 50 + (j / 2) * 110, 110, 104))
		b.food_id = id
		b.text = Data.ITEMS[id]["name"]
		b.text_size = 14
		b.draw_fn = func(ci, r):
			Art.ellipse(ci, r.get_center() + Vector2(0, r.size.y * 0.25), Vector2(r.size.x * 0.48, r.size.y * 0.22), Color("8a5a2b"))
			Art.ellipse(ci, r.get_center() + Vector2(0, r.size.y * 0.2), Vector2(r.size.x * 0.44, r.size.y * 0.18), Color("b98249"))
			Art.draw_food(ci, id, r.grow(-6))
		b.disabled = board != null
		b.drag_data = {"kind": "raw", "item": id}
		b.tooltip_text = "Arrastrala hasta la tabla"
		b.pressed.connect(_drag_hint.bind(id))

	board_view = BoardView.new()
	board_view.position = Vector2(290, 46)
	board_view.size = Vector2(620, 414)
	if board != null:
		board_view.item_id = board["item"]
		board_view.cuts = board["cuts"]
		board_view.need = board["need"]
	board_view.chop_clicked.connect(_chop)
	board_view.ingredient_dropped.connect(_on_ingredient_to_board)
	station_box.add_child(board_view)

	var info_text := _board_text()
	if board == null:
		info_text = "Arrastrá una verdura\nde la izquierda hasta\nla tabla para cortarla."
	board_info = _card(Rect2(940, 60, 320, 230), info_text, 18)
	if board != null:
		var drop := _button("Dejar esto", _drop_chop, 16)
		drop.position = Vector2(1030, 310)
		station_box.add_child(drop)


# --- 4. Emplatado ---

func _build_plating_station() -> void:
	var o = _get_order(selected_id)
	var draw_bg := func(ci, _t): Art.draw_marble(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	if o == null:
		_tag("Elegí un ticket de arriba para armar el plato.", Vector2(12, 4), 16)
		return
	var r: Dictionary = Data.RECIPES[o["recipe"]]
	_tag("Plato de #%d %s — %s" % [o["id"], o["name"], r["name"]], Vector2(12, 4), 16)

	# Izquierda: la bandeja compartida y la despensa (se arrastran al plato o click)
	_tag("Bandeja (arrastrá al plato)", Vector2(16, 42), 15)
	if prepared.is_empty():
		_label_at("(vacía: cociná o cortá\nen las otras estaciones)", Vector2(20, 80), 14, Color(0.25, 0.2, 0.15))
	var cols := 3 if prepared.size() <= 6 else 4
	var tw := 384.0 / cols
	var shown := mini(prepared.size(), cols * 3)
	for k in shown:
		var e: Dictionary = prepared[k]
		var b := _prop(Rect2(16 + (k % cols) * tw, 72 + (k / cols) * 90, tw - 4, 86))
		b.entry = e
		b.text = e["label"]
		b.text_size = 11 if cols == 3 else 10
		b.tooltip_text = "Arrastralo al plato (o hacé click). Para tirarlo, arrastralo al cesto (cuesta plata)."
		b.drag_data = {"kind": "prepared", "index": k}
		b.pressed.connect(_plate_ready.bind(k))
	var pantry := _unlocked_items("ready")
	if not pantry.is_empty():
		var py := 72.0 + maxi(1, int(ceil(shown / float(cols)))) * 90.0 + 6.0
		_tag("Despensa", Vector2(16, py), 15)
		for k in pantry.size():
			var b := _prop(Rect2(16 + k * 128, py + 28, 124, 84))
			b.food_id = pantry[k]
			b.text = Data.ITEMS[pantry[k]]["name"]
			b.text_size = 12
			b.drag_data = {"kind": "pantry", "item": pantry[k]}
			b.pressed.connect(_plate_pantry.bind(pantry[k]))

	# La pila de platos limpios (se va achicando: hay que lavar)
	var n_clean: int = clean_stock.get("plato", 0)
	var stack := _painter(Rect2(712, 360, 92, 104), func(ci, _t): Art.draw_plate_stack(ci, Rect2(0, 0, 92, 104), n_clean), false)
	stack.tooltip_text = "Platos limpios que quedan. Los sucios se lavan en la Bacha (tecla 6)."
	stack.mouse_filter = Control.MOUSE_FILTER_PASS
	# Centro: el plato (recibe lo que se arrastra)
	var drinks := false     # las bebidas se sirven en la Entrega (se ven en el plato si ya están)
	var plate := PlateView.new()
	plate.position = Vector2(396 if drinks else 410, 36)
	plate.size = Vector2(400 if drinks else 420, 384)
	plate.items = o["plate"]
	plate.sauce = o["plate_sauce"]
	plate.toppings = o["plate_toppings"]
	plate.sprinkles = o["sprinkles"]
	plate.drink = o.get("plate_drink", "")
	plate.gold = _has("vajilla")
	plate.seed = o["id"]
	plate.accept_drops = true
	plate.dropped.connect(_on_plate_drop)
	station_box.add_child(plate)
	plating_plate = plate
	var reset := _button("Rehacer plato", _reset_plate, 15)
	reset.position = Vector2(540 if drinks else 556, 424)
	reset.tooltip_text = "Devuelve lo del plato a la bandeja. Para tirar el plato, arrastralo al cesto."
	station_box.add_child(reset)

	# Cesto de basura: abajo a la derecha (en los días con bebida sube, y abajo va la heladera)
	var trash := TrashView.new()
	trash.position = Vector2(1170, 40) if drinks else Vector2(1188, 344)
	trash.size = Vector2(84, 118)
	trash.dropped.connect(_on_trash_drop)
	station_box.add_child(trash)
	if drinks:
		_build_drinks_fridge(o, Rect2(1146, 176, 126, 286))

	# Derecha: salsas y toppings del mismo tipo de plato
	var x0 := 806.0 if drinks else 846.0
	var y := 42.0
	var prebuilt: bool = r.get("prebuilt", false)   # la pizza ya viene con salsa e ingredientes de la mesa
	var sauces := [] if prebuilt else _cat_options(r["cat"], "sauces")
	if not sauces.is_empty():
		_tag("Salsas (arrastrá al plato)", Vector2(x0, y), 15)
		var opts := [""] + sauces
		for k in opts.size():
			var s: String = opts[k]
			var b := _prop(Rect2(x0 + (k % 4) * 84, y + 30 + (k / 4) * 92, 80, 88))
			b.text = s if s != "" else "Sin salsa"
			b.text_size = 10
			b.selected = o["plate_sauce"] == s
			if s == "":
				b.draw_fn = func(ci, rr): Art.draw_none(ci, rr)
				b.tooltip_text = "Sacar la salsa"
				b.pressed.connect(_set_plate_sauce.bind(""))
			else:
				var col: Color = Art.SAUCE_COLORS.get(s, Color.WHITE)
				b.draw_fn = func(ci, rr): Art.draw_bottle(ci, rr, col)
				b.drag_data = {"kind": "sauce", "name": s}
				b.tooltip_text = "Arrastrá la salsa hasta el plato"
				b.pressed.connect(_on_condiment_click.bind("sauce", s))
		y += 30 + ceil(opts.size() / 4.0) * 92 + 4
	var tops := [] if prebuilt else _cat_options(r["cat"], "toppings")
	if prebuilt:
		_tag("La pizza ya viene armada de la mesa", Vector2(x0, y), 15)
	if not tops.is_empty():
		_tag("Toppings (mantené y desparramá)", Vector2(x0, y), 15)
		for k in tops.size():
			var tname: String = tops[k]
			var b := _prop(Rect2(x0 + (k % 4) * 84, y + 30 + (k / 4) * 82, 80, 80))
			var pct := 0
			if o["sprinkles"].has(tname):
				pct = int(minf(o["sprinkles"][tname]["amount"], 1.0) * 100.0)
			# Sin texto: el bowl muestra el dibujo del topping; a medias, un anillo de progreso
			b.selected = tname in o["plate_toppings"]
			var frac := pct / 100.0
			b.draw_fn = func(ci, rr):
				Art.draw_bowl(ci, rr, tname)
				if frac > 0.0 and frac < 1.0:
					var cc: Vector2 = rr.get_center()
					var rad := minf(rr.size.x, rr.size.y) * 0.5
					ci.draw_arc(cc, rad, 0, TAU, 32, Color(0, 0, 0, 0.25), 4)
					ci.draw_arc(cc, rad, -PI / 2, -PI / 2 + TAU * frac, 32, Color("ffd166"), 4)
			b.mouse_default_cursor_shape = Control.CURSOR_DRAG
			b.tooltip_text = "%s: mantené apretado y pasalo unos segundos por arriba de la comida (click si ya está puesto para sacarlo)" % tname
			b.held.connect(_start_sprinkle.bind(tname))


# --- 5. Entrega ---

func _build_delivery_station() -> void:
	var o = _get_order(selected_id)
	var draw_bg := func(ci, t): Art.draw_pass(ci, Rect2(Vector2.ZERO, STATION_SIZE), t)
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, true)

	if not last_result.is_empty():
		var res := last_result
		var draw_res := func(ci, t):
			Art.draw_paper(ci, Rect2(0, 0, 274, 270))
			Art.text(ci, Vector2(0, 40), "ÚLTIMA ENTREGA", 15, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, 274)
			var mood := 0 if res["total"] >= 75.0 else (1 if res["total"] >= 55.0 else 3)
			Art.draw_character(ci, res["look"], Vector2(52, 112), 0.85, mood, t, true)
			Art.text(ci, Vector2(96, 76), res["name"], 16, COL_INK)
			Art.text(ci, Vector2(96, 104), "%d%%" % int(res["total"]), 28, COL_INK)
			Art.stars(ci, Vector2(200, 97), 9, _stars(res["total"]))
			Art.text(ci, Vector2(14, 140), "\"%s\"" % res["verdict"], 17, COL_INK)
			var lines: Array = res["lines"]
			for k in lines.size():
				Art.text(ci, Vector2(14 + (k % 2) * 130, 166 + (k / 2) * 22), lines[k], 13, Color(0.3, 0.25, 0.2))
			Art.text(ci, Vector2(14, 250), "+$%d (propina $%d)" % [res["pay"], res["tip"]], 16, Color("2f7a3a"))
		_painter(Rect2(990, 24, 274, 270), draw_res, true)

	if o == null:
		_tag("Elegí un ticket de arriba para servir.", Vector2(12, 4), 16)
		return
	_tag("Servir a #%d %s" % [o["id"], o["name"]], Vector2(12, 4), 16)

	var cv := CustomerView.new()
	cv.look = o["look"]
	cv.scale_factor = 1.15
	cv.position = Vector2(530, 4)
	cv.size = Vector2(220, 298)
	cv.mood = _mood(elapsed - o["arrived"])
	if cv.mood >= 1:
		cv.bubble = _wait_line(o, cv.mood)
	station_box.add_child(cv)

	var plate := PlateView.new()
	plate.position = Vector2(520, 262)
	plate.size = Vector2(240, 200)
	plate.items = o["plate"]
	plate.sauce = o["plate_sauce"]
	plate.toppings = o["plate_toppings"]
	plate.sprinkles = o["sprinkles"]
	plate.gold = _has("vajilla")
	plate.drink = o.get("plate_drink", "")
	plate.seed = o["id"]
	var wants_drink: bool = o.get("drink", "") != ""
	if wants_drink:
		# La bebida se pone acá, en la bandeja, justo antes de servir
		plate.accept_drops = true
		plate.dropped.connect(_delivery_drop)
	station_box.add_child(plate)
	if wants_drink:
		_build_drinks_fridge(o, Rect2(352, 160, 126, 286))
		if o.get("plate_drink", "") == "":
			_tag("Falta la bebida: %s" % o["drink"], Vector2(330, 128), 14)

	var bell := _prop(Rect2(800, 330, 120, 126))
	bell.texture = Art.tex("kitchen/bell")
	bell.text = "¡Servir!"
	bell.text_size = 17
	bell.disabled = o["plate"].is_empty()
	bell.pressed.connect(_deliver)

	var txt := "PIDIÓ\n" + _order_text(o) + "\n\nEN EL PLATO\n" + _plate_text(o)
	if o["plate"].is_empty():
		txt += "\n\n(Armá el plato en Emplatado, tecla 4)"
	_card(Rect2(16, 40, 300, 290), txt, 14)


func _order_text(o) -> String:
	var lines := []
	for entry in o["items"]:
		lines.append("· " + _req_text(entry))
	if not Data.RECIPES[o["recipe"]]["sauces"].is_empty():
		lines.append("· " + (o["sauce"] if o["sauce"] != "" else "sin salsa"))
	for t in o["toppings"]:
		lines.append("+ " + t)
	if o.get("drink", "") != "":
		lines.append("Bebida: " + o["drink"])
	return "\n".join(PackedStringArray(lines))


func _plate_text(o) -> String:
	if o["plate"].is_empty() and o["plate_toppings"].is_empty() and o["plate_sauce"] == "" and o.get("plate_drink", "") == "":
		return "(vacío)"
	var lines := []
	for e in o["plate"]:
		lines.append("· " + e["label"])
	lines.append("· " + (o["plate_sauce"] if o["plate_sauce"] != "" else "sin salsa"))
	for t in o["plate_toppings"]:
		lines.append("+ " + t)
	if o.get("plate_drink", "") != "":
		lines.append("Bebida: " + o["plate_drink"])
	return "\n".join(PackedStringArray(lines))


# =====================================================================
# Utilidades
# =====================================================================

func _unlocked_items(kind: String) -> Array:
	var out := []
	for r in recipes:
		for part in Data.RECIPES[r]["parts"]:
			for id in part:
				if Data.ITEMS[id]["kind"] == kind and not id in out:
					out.append(id)
	return out


func _cat_options(cat: String, field: String) -> Array:
	var out := []
	for r in recipes:
		var rec: Dictionary = Data.RECIPES[r]
		if rec["cat"] != cat:
			continue
		for opt in rec[field]:
			if opt != "Sin salsa" and not opt in out:
				out.append(opt)
	return out


func _get_order(id: int):
	for o in orders:
		if o["id"] == id:
			return o
	return null


func _pick(arr: Array):
	return arr[rng.randi() % arr.size()]


func _painter(rect: Rect2, fn: Callable, animate := false, parent: Node = null) -> Control:
	var p := Painter.new()
	p.position = rect.position
	p.size = rect.size
	p.fn = fn
	p.animate = animate
	(parent if parent != null else station_box).add_child(p)
	return p


func _prop(rect: Rect2) -> Control:
	var b := PropButton.new()
	b.position = rect.position
	b.size = rect.size
	station_box.add_child(b)
	return b


func _tag(text: String, pos: Vector2, fsize := 16) -> Label:
	var l := _label(text, fsize)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.07, 0.82)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", sb)
	l.position = pos
	station_box.add_child(l)
	return l


func _card(rect: Rect2, text: String, fsize := 16) -> Label:
	var l := _label(text, fsize, COL_INK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PAPER
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(3, 4)
	l.add_theme_stylebox_override("normal", sb)
	l.position = rect.position
	l.size = rect.size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.clip_text = true
	station_box.add_child(l)
	return l


func _label_at(text: String, pos: Vector2, fsize: int, color: Color) -> Label:
	var l := _label(text, fsize, color)
	l.position = pos
	station_box.add_child(l)
	return l


func _paper_card(min_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PAPER
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(26)
	sb.border_color = Color("c9a86a")
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(4, 6)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = min_size
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	return card


func _open_overlay() -> VBoxContainer:
	_close_overlay()
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.05, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	overlay = bg
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var card := _paper_card(Vector2(560, 0))
	center.add_child(card)
	return card.get_child(0)


func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _label(text: String, size := 20, color := Color.WHITE, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return l


func _button(text: String, cb: Callable, size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE   # así la barra espaciadora no "aprieta" botones
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	return b


func _close_now() -> void:
	if playing and closing:
		_finish_level()


## En la Entrega la bandeja sólo recibe la bebida
func _delivery_drop(data: Dictionary) -> void:
	if data.get("kind", "") == "drink":
		_on_plate_drop(data)
