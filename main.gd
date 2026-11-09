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
const PastaView = preload("res://views/pasta_board_view.gd")
const PressView = preload("res://views/tortilla_press_view.gd")
const MolcajeteView = preload("res://views/molcajete_view.gd")
const CrepeView = preload("res://views/crepe_view.gd")
const PipingView = preload("res://views/piping_view.gd")
const SushiView = preload("res://views/sushi_view.gd")
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
	"comal": ["res://assets/sfx/chisporroteo.wav", -24.0],     # la tortilla chisporrotea apenas
	"licuadora": ["res://assets/sfx/licuadora.wav", -20.0],
	"crepera": ["res://assets/sfx/chisporroteo.wav", -26.0],
	"tandoor": ["res://assets/sfx/horno.wav", -22.0],
	"wok": ["res://assets/sfx/chisporroteo.wav", -18.0],
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
# Servir vino: se mantiene la botella volcada sobre la copa
var wine_pouring := false
var wine_cursor: Control = null
var wine_tilt := 0.0
var wine_flow := 0.0
var wine_slosh := 0.0
var wine_glass: Control = null
var wine_player: AudioStreamPlayer = null
var closing_t := 0.0                  # segundos que quedan para lavar antes de que cierre solo
var close_button: Button = null
var mesa_pizza = null                # Italia: la pizza que se está armando en la mesa {stretch, sauce, sprinkles, plate_toppings}
var mesa_view = null
var mesa_mode := "pizza"               # Italia: la Mesa sirve para pizza o para amasar pasta fresca
var mesa_pasta = null                 # la pasta que se está amasando {stage, knead, roll, cuts, need_cuts}
var pasta_view = null
var fresh_pasta := 0                  # porciones de pasta fresca listas para la olla
var knead_sound_t := 0.0
var tort_mode := "tortillas"          # México: la Tortillería sirve para la prensa o para el molcajete
var press_masa = null                 # bolita en la prensa {pressed}
var press_view = null
var molcajete = null                  # lo que se está moliendo {sauce, ground, items}
var molcajete_view = null
var salsa_stock := {}                 # porciones de cada salsa molida
var burger_stack = null               # EE.UU.: la hamburguesa que se está armando {layers, patty}
var crepe_mode := "crepes"             # Francia: la Crêperie sirve para esparcir crêpes o para la manga
var crepe_batter = null               # la crêpe que se está esparciendo {spread}
var pipe = null                       # el éclair que se está decorando {flavor, pts, covered, mess}
var masala_pan = null                  # India: el masala que se está haciendo {spices}
var sushi_roll = null                  # Japón: el maki que se está armando {stage, rice, fillings, rolled, cuts}
var sushi_view = null
var tips_on := true                   # consejos para el que juega por primera vez
var tips_seen: Array = []             # consejos que ya se mostraron (por perfil)
var tips_done := false                # ya jugó su primer día: los consejos no se muestran más
var tip_refs := {}                    # cosas de la pantalla a las que puede señalar un consejo
var tip_view: Control = null
var tip_id := ""
var tip_age := 0.0
var tip_check := 0.0
var critic_at := -1                  # qué cliente del día es el crítico de la guía (-1 = hoy no viene)
var critic_score := -1.0             # nota que le dio al plato (-1 = todavía no comió)
var critic_name := ""
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
	if save_path == SAVE_PATH:
		_load_profiles()      # las pruebas automáticas usan su propio archivo y no tocan los perfiles
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
	if c.get("critic", false):
		critic_score = 0.0     # el crítico se fue sin comer: no hay estrella
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
	tip_refs["esponja"] = sponge
	sponge.draw_fn = func(ci, r): Art.draw_sponge(ci, r.grow(-8), 0.0, soap_now)
	sponge.text = "Esponja" if sponge_soap > 0.0 else "Esponja (seca)"
	sponge.text_size = 12
	sponge.mouse_default_cursor_shape = Control.CURSOR_DRAG
	sponge.tooltip_text = "Mantené apretado y frotá sobre las manchas"
	sponge.held.connect(_start_scrub)
	var soap := _prop(Rect2(845, 172, 100, 130))
	tip_refs["detergente"] = soap
	soap.draw_fn = func(ci, r): Art.draw_detergent(ci, r.grow(-6), 0.7)
	soap.text = "Detergente"
	soap.text_size = 12
	soap.tooltip_text = "Tocalo para cargar la esponja"
	soap.pressed.connect(_load_soap)
	var faucet := _button("Cerrar grifo" if water_on else "Abrir grifo", _toggle_water, 14)
	tip_refs["grifo"] = faucet
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
	_hide_tip(false)
	for key in cook_players:
		cook_players[key].stream_paused = true
	var box := _open_overlay()
	box.add_child(_label("Pausa", 44, COL_INK))
	box.add_child(_label("El local está en pausa: la cocina y los clientes esperan.", 17, COL_INK))
	box.add_child(_label("(P o Esc para seguir)", 14, Color(0.4, 0.3, 0.2)))
	var go := _button("Seguir cocinando", _resume, 22)
	go.custom_minimum_size = Vector2(320, 56)
	box.add_child(go)
	if not tips_done:
		var tb := _button("Consejos: " + ("sí" if tips_on else "no"), _toggle_tips, 16)
		tb.tooltip_text = "Ayudas para el que juega por primera vez"
		box.add_child(tb)
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
		if tip_view != null:
			_hide_tip(false)
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
	_update_pour(delta)
	knead_sound_t -= delta
	_update_tips(delta)
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
			if a == "wok":
				# Wok: si no se saltea, se pega y se quema el doble de rápido
				slot["stick"] = float(slot.get("stick", 0.0)) + delta
				if slot["stick"] > Data.WOK_STICK:
					slot["t"] += delta / Data.COOK_SLOW
					slot["stuck"] = float(slot.get("stuck", 0.0)) + delta
			if slot.has("ta"):
				if slot.get("flip", false):
					# Tortilla en el comal: se cocina el lado de abajo; el de arriba apenas se entibia
					slot["ta"] += delta / Data.COOK_SLOW
					slot["tb"] += delta / Data.COOK_SLOW * 0.12
				else:
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
		if mesa_mode == "pasta" and not _fresh_items().is_empty():
			_pasta_tap()
		else:
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
		tips_on = cfg.get_value("opciones", "consejos", true)
		tips_seen = cfg.get_value("ayuda", "vistos", [])
		# Partidas de antes de los consejos: si ya jugó algún día, no es su primera vez
		var played := false
		for cid in country_progress:
			if not country_progress[cid].get("mejores", {}).is_empty():
				played = true
		tips_done = cfg.get_value("ayuda", "terminado", played)
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
	cfg.set_value("opciones", "consejos", tips_on)
	cfg.set_value("ayuda", "vistos", tips_seen)
	cfg.set_value("ayuda", "terminado", tips_done)
	cfg.save(save_path)


func _reset_progress() -> void:
	savings = 0
	tips_seen = []
	tips_done = false
	tips_on = true
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


## Estrellas de la guía que tiene un local (0 a 3)
func _guide_stars(id: String) -> int:
	return int(country_progress.get(id, {}).get("estrellas", 0))


## ¿Viene el crítico de la guía en este día? Solo si al local le faltan estrellas y el día es lo bastante avanzado.
func _critic_comes(day: int) -> bool:
	var st := _guide_stars(current_country)
	return st < 3 and day >= Data.critic_min_day(_levels().size(), st)


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
	p.fps = 12.0     # el salón solo anima detalles lentos (lámparas, ventilador)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var light := func(ci, _t): Art.draw_lighting(ci, Rect2(0, 0, 1280, 720))
	_painter(Rect2(0, 0, 1280, 720), light, false, bg)
	var chef := CustomerView.new()
	chef.look = _player_look()
	chef.scale_factor = 2.3
	chef.position = Vector2(60, 40)
	chef.size = Vector2(380, 450)
	chef.bubble = "¡A cocinar, %s!" % _player_name() if _player_name() != "" else "¡Bienvenido a la cocina!"
	bg.add_child(chef)

	var card := _paper_card(Vector2(560, 0))
	card.position = Vector2(470, 24)
	bg.add_child(card)
	var box: VBoxContainer = card.get_child(0)
	var cdata: Dictionary = Data.COUNTRIES[current_country]
	box.add_child(_label(cdata["restaurant"], 46, COL_INK))
	box.add_child(_label("%s, %s  ·  reputación %d%%" % [cdata["city"], cdata["name"], _reputation(current_country)], 17, COL_INK))
	# Estrellas de la guía: el sello y qué hace falta para la próxima
	var gst := _guide_stars(current_country)
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 8)
	box.add_child(grow)
	var gseal := Painter.new()
	gseal.custom_minimum_size = Vector2(56, 50)
	gseal.animate = true
	gseal.fn = func(ci, t): Art.draw_guide_seal(ci, Vector2(28, 22), 20.0, gst, t)
	grow.add_child(gseal)
	var gtxt := "%s: %d de 3 estrellas (+$%d de propina por cliente)" % [Data.GUIDE_NAME, gst, Data.STAR_TIP * gst]
	if gst < 3:
		var from_day := Data.critic_min_day(_levels().size(), gst) + 1
		gtxt += "\nPróxima: desde el día %d viene un crítico de incógnito. Su plato tiene que llegar al %d%%." % [from_day, int(Data.CRITIC_NEEDS[gst])]
	else:
		gtxt += "\n¡Local con las tres estrellas de la guía!"
	var gl := _label(gtxt, 14, COL_INK)
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gl.custom_minimum_size = Vector2(460, 0)
	grow.add_child(gl)
	box.add_child(_spacer(2))
	for i in _levels().size():
		var lv: Dictionary = _levels()[i]
		var txt: String = lv["name"]
		if best_scores.has(i):
			txt += "   ·   %d%%  ·  %d de 3 estrellas" % [int(best_scores[i]), _stars(best_scores[i])]
		elif i > unlocked_level:
			txt += "   (bloqueado)"
		var b := _button(txt, _show_intro.bind(i), 19)
		b.custom_minimum_size = Vector2(520, 42)
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
	_painter(Rect2(0, 0, 1280, 720), drift, true, bg).fps = 24.0
	var logo := func(ci, t): Art.draw_logo(ci, Vector2(640, 300), 1.25 + sin(t * 1.5) * 0.015, t)
	_painter(Rect2(0, 0, 1280, 720), logo, true, bg).fps = 24.0
	var sub := _label("Un viaje de cocina por el mundo", 22, Color("fdf6e3"), 5)
	sub.position = Vector2(0, 492)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(sub)
	var play := _button("Jugar", _on_play, 28)
	play.custom_minimum_size = Vector2(260, 64)
	play.position = Vector2(510, 540)
	bg.add_child(play)
	# Quién está jugando: su cocinero y el botón para cambiar de perfil
	if not profile.is_empty() and not profile.get("nuevo", false):
		var look := _player_look()
		var nm := _player_name()
		var who := func(ci, t):
			Art.rrect(ci, Rect2(470, 622, 340, 60), Color(0.12, 0.09, 0.07, 0.8), 14)
			Art.draw_character(ci, look, Vector2(512, 672), 0.62, 0, t, true)
			Art.text(ci, Vector2(552, 647), "Cocinera" if look.get("fem", false) else "Cocinero", 13, Color(1, 1, 1, 0.6))
			Art.text(ci, Vector2(552, 670), nm, 20, Color.WHITE)
		_painter(Rect2(0, 0, 1280, 720), who, true, bg).fps = 20.0
		var change := _button("Cambiar", _show_profiles, 14)
		change.position = Vector2(712, 636)
		bg.add_child(change)
	elif profiles.size() > 1:
		var change := _button("Elegir perfil", _show_profiles, 14)
		change.position = Vector2(570, 636)
		bg.add_child(change)
	var reset := _button("Borrar partida", _reset_progress, 13)
	reset.position = Vector2(1140, 676)
	reset.tooltip_text = "Borra la partida del cocinero que está jugando"
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
	_painter(Rect2(0, 0, 1280, 80), bar, true, bg).fps = 12.0
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
		for n in _drinks():
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
		tip = "Cada pedido viene con bebida: en la Entrega (tecla 5) arrastrala desde la heladera hasta la bandeja. El vino se sirve en copa: mantené la botella volcada sobre la copa hasta la parte más ancha."
	elif not lv["show_zone"]:
		tip = "Desde hoy la barra NO marca el punto: mirá el reloj, el termómetro de las carnes y el recetario (tecla R)."
	if lv.has("tip"):
		tip = lv["tip"]
	var step3 := "3. Tabla: arrastrá la verdura hasta la tabla y cortala (click en la tabla o barra espaciadora).\n"
	match _prep():
		"mesa": step3 = "3. Mesa: estirá la masa de pizza, poné salsa e ingredientes y mandala al horno de leña.\n"
		"tortilleria": step3 = "3. Tortillería: prensá las tortillas y mandalas al comal; en el molcajete se muelen las salsas.\n"
		"armado": step3 = "3. Armado: apilá la hamburguesa capa por capa en el orden exacto del ticket.\n"
		"creperie": step3 = "3. Crêperie: esparcí la masa de crêpe en círculos y mandala a la crepera; con la manga se decoran los éclairs.\n"
		"especiero": step3 = "3. Especiero: agregá las especias de la masala dabba en el orden exacto del ticket.\n"
		"esterilla": step3 = "3. Esterilla: alga, arroz frotando, el relleno pedido, enrollá deslizando hacia arriba y cortá.\n"
	if i == 0 and tips_on and not tips_done:
		# Con los consejos prendidos no hace falta la guía: se aprende jugando
		tip = "Tomá el pedido, cociná, armá el plato, servilo y lavá lo sucio. No te preocupes: mientras jugás te van a ir apareciendo consejos justo cuando los necesitás (se pueden apagar en la pausa).\n" + \
			"Teclas 1 a 6: cambiar de estación.\n\n" + tip
	elif i == 0:
		tip = "Cómo se juega:\n1. Pedidos: tomá el pedido del cliente del mostrador.\n" + \
			"2. Cocina: arrastrá los ingredientes de la heladera al aparato y sacalos en su punto (click). Las carnes tienen termómetro. Lo de la plancha y la olla se sala con el salero.\n" + \
			step3 + \
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
	if _critic_comes(i):
		box.add_child(_label("Dicen que hoy viene un crítico de la guía, de incógnito. Si le encanta su plato (%d%%), el local gana una estrella." % int(Data.CRITIC_NEEDS[_guide_stars(current_country)]), 14, Color("8a5a10")))
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
	mesa_pasta = null
	mesa_mode = "pizza"
	fresh_pasta = 0
	tort_mode = "tortillas"
	press_masa = null
	molcajete = null
	salsa_stock = {}
	burger_stack = null
	crepe_mode = "crepes"
	crepe_batter = null
	pipe = null
	masala_pan = null
	sushi_roll = null
	mesa_pizza = null
	# ¿Viene hoy el crítico de la guía? Llega mezclado entre los clientes (nunca primero ni último)
	critic_at = -1
	critic_score = -1.0
	critic_name = ""
	if _critic_comes(i):
		critic_at = rng.randi_range(2, maxi(2, int(level["customers"]) - 1))
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
	if critic_at > 0:
		sub = "Dicen que hoy viene un crítico de la guía..."
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
	# Terminó su primer día: desde ahora ya sabe jugar y los consejos no vuelven
	tips_done = true
	_hide_tip(false)
	# El crítico de la guía: si su plato llegó a la nota y el día se aprobó, el local gana una estrella
	var critic_msg := ""
	var star_won := 0
	if critic_at > 0 and critic_score >= 0.0:
		var st := _guide_stars(current_country)
		var need: float = Data.CRITIC_NEEDS[st]
		if passed and critic_score >= need:
			star_won = st + 1
			var cp: Dictionary = country_progress.get(current_country, {})
			cp["estrellas"] = star_won
			country_progress[current_country] = cp
			critic_msg = "¡%s era el crítico de la %s! Le puso %d%% a tu plato:\n¡el local gana su %s estrella!" % [
				critic_name, Data.GUIDE_NAME, int(critic_score), ["primera", "segunda", "tercera"][st]]
		elif critic_score <= 0.0:
			critic_msg = "%s era el crítico de la guía... y se fue sin comer. Va a volver otro día." % critic_name
		elif not passed:
			critic_msg = "%s era el crítico de la guía: le puso %d%% al plato, pero el día no se aprobó. Va a volver." % [critic_name, int(critic_score)]
		else:
			critic_msg = "%s era el crítico de la guía: le puso %d%% al plato y para la estrella hacía falta %d%%. Va a volver." % [
				critic_name, int(critic_score), int(need)]
	_save_progress()

	var box := _open_overlay()
	box.add_child(_label("¡Cerró el local!", 40, COL_INK))
	box.add_child(_label(level["name"], 20, COL_INK))
	var n_stars := _stars(avg)
	# Tu cocinero, contento o preocupado según cómo salió el día, y las estrellas al lado
	var look := _player_look()
	var mood := 0 if avg >= 75.0 else (1 if avg >= Data.PASS_SCORE else 2)
	var stars_pic := Painter.new()
	stars_pic.custom_minimum_size = Vector2(320, 104)
	stars_pic.animate = true
	stars_pic.fn = func(ci, t):
		Art.draw_character(ci, look, Vector2(70, 102), 0.95, mood, t, true)
		Art.stars(ci, Vector2(190, 56), 20, n_stars)
	box.add_child(stars_pic)
	box.add_child(_label("Platos servidos: %d" % served + ("   ·   Se fueron sin comer: %d" % lost if lost > 0 else ""), 20, COL_INK))
	box.add_child(_label("Calificación promedio: %d%%" % int(avg), 20, COL_INK))
	if dirty_left > 0:
		box.add_child(_label("Quedaron %d cosas sin lavar: -%d de reputación" % [dirty_left, int(dirty_pen)], 18, Color("a8321e")))
	box.add_child(_label("Recaudado hoy: $%d   ·   Ahorros: $%d" % [money, savings], 20, COL_INK))
	if critic_msg != "":
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 10)
		box.add_child(crow)
		var seal := Painter.new()
		seal.custom_minimum_size = Vector2(86, 70)
		seal.animate = true
		var won := star_won
		seal.fn = func(ci, t): Art.draw_guide_seal(ci, Vector2(43, 35), 30.0, won, t)
		crow.add_child(seal)
		var cl := _label(critic_msg, 16, Color("8a5a10") if star_won > 0 else COL_INK)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.custom_minimum_size = Vector2(620, 0)
		crow.add_child(cl)
		if star_won > 0:
			_play_sfx("timbre")
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
	var c := {"name": _pick(Data.COUNTRIES[current_country].get("names", NAMES)), "arrived": elapsed, "look": Art.random_look(rng), "x": DOOR_X}
	if spawned == critic_at:
		c["look"] = Art.critic_look(rng)
		c["critic"] = true
		critic_name = c["name"]
		_hint("Entró alguien de sombrero y anteojos oscuros que anota todo... ¿será el crítico de la guía?")
	queue.append(c)
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
		"critic": c.get("critic", false),
		"recipe": rkey,
		"items": items,
		"sauce": sauce,
		"toppings": pool.slice(0, rng.randi_range(min_t, max_t)),
		"plate": [],          # lo que ya está en el plato (preparaciones sacadas de la bandeja)
		"plate_sauce": "",
		"plate_toppings": [],  # toppings completos (desparramados lo suficiente)
		"sprinkles": {},       # cómo quedaron desparramados: {nombre: {amount, pts}}
		"drink": _pick(_drinks()) if level.get("drinks", false) else "",
		"plate_drink": "",
	}
	if r.get("layered", false):
		# Hamburguesa por capas: los ingredientes en un orden exacto, con la carne en algún lugar del medio
		var layers: Array = order["toppings"].duplicate()
		layers.insert(rng.randi_range(0, layers.size()), "Carne")
		order["layers"] = layers
	if r.get("spiced", false):
		# Masala: las especias en un orden exacto (más especias en los días difíciles)
		var sp: Array = Data.SPICES.keys()
		sp.shuffle()
		order["spices"] = sp.slice(0, 3 if int(level["max_toppings"]) < 3 else 4)
	return order


# =====================================================================
# Cocina
# =====================================================================

func _target_for(o, item_id: String) -> float:
	var info: Dictionary = Data.ITEMS[item_id]
	for entry in o["items"]:
		if entry["item"] == item_id and entry["doneness"] != "":
			return info["doneness"][entry["doneness"]]
		# El medallón de una hamburguesa armada: el punto que pidió para la hamburguesa
		if Data.ITEMS[entry["item"]].get("patty", "") == item_id and entry["doneness"] != "" and info.has("doneness"):
			return info["doneness"].get(entry["doneness"], info["target"])
	return info["target"]


func _cook(item_id: String) -> void:
	var info: Dictionary = Data.ITEMS[item_id]
	var slots: Array = cookers[info["where"]]
	var idx := slots.find(null)
	if idx == -1:
		return
	if info.get("fresh", false) and _uses_mesa():
		# La pasta fresca primero hay que amasarla en la Mesa
		if fresh_pasta <= 0:
			_hint("No hay %s fresco: amasalo en la Mesa (tecla 3, botón Pasta fresca)" % info["name"].to_lower())
			return
		fresh_pasta -= 1
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
	if slot.get("flip", false):
		# Tortilla: se lleva la cocción de cada lado
		var burnt_t: bool = maxf(slot["ta"], slot["tb"]) >= slot["burn"]
		var raw_t: bool = minf(slot["ta"], slot["tb"]) < slot["target"] * 0.6
		var fname: String = Data.ITEMS[slot["item"]]["name"]
		prepared.append({"item": slot["item"], "t": maxf(slot["ta"], slot["tb"]), "ta": slot["ta"], "tb": slot["tb"],
			"vtarget": slot["target"], "burn": slot["burn"], "pantry": false, "chopped": false,
			"dirty": slot.get("dirty_tool", false),
			"label": (fname + " quemada") if burnt_t else ((fname + " cruda de un lado") if raw_t else fname)})
		_refresh_all()
		return
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
		"stuck": slot.get("stuck", 0.0),
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
	if Data.ITEMS[e["item"]].get("flip", false) and minf(e["ta"], e["tb"]) < target * 0.6:
		return minf(qa, qb) * 0.5     # tortilla cruda de un lado: no se puede comer así
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
				if data["name"] != "Vino tinto":
					o["wine_fill"] = 0.0      # cambió de bebida: la copa queda vacía
					o["wine_spill"] = 0.0
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
		if s != "" and s != o["plate_sauce"] and _ground_sauce(s):
			# Salsa del molcajete: se gasta una porción
			if int(salsa_stock.get(s, 0)) <= 0:
				_hint("No queda %s: molela en el molcajete (tecla 3)" % s.to_lower())
				return
			salsa_stock[s] = int(salsa_stock[s]) - 1
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
	var spice_q := 0.0         # curry: qué tan bien siguió el orden de las especias
	for entry in o["items"]:
		for k in leftovers.size():
			var e: Dictionary = leftovers[k]
			if e["item"] == entry["item"]:
				hits += 1
				# La cocción se juzga contra el punto que pidió ESTE cliente
				var q := 100.0
				if e.has("ta"):
					q = _pizza_quality(e, _target_for(o, e["item"]))
					if e.has("pizza") and e["pizza"].get("stretch", 0.0) < 1.0:
						q *= 0.5      # la masa no estaba bien estirada
				elif e.has("spices"):
					spice_q = _seq_score(o.get("spices", []), e["spices"])    # masala: las especias en el orden pedido (se puntúa aparte)
				elif e.has("pipe_q"):
					q = e["pipe_q"]       # éclair: qué tan bien se siguió la guía con la manga
				elif e.has("patty_t"):
					# Hamburguesa armada: se juzga el medallón (punto y sal)
					q = _cook_quality(e["patty_t"], _target_for(o, e["item"]), e["burn"])
					q *= Data.salt_factor(Data.ITEMS[e["item"]]["patty"], e.get("salt", 0.0))
				elif e.get("t", -1.0) >= 0.0:
					q = _cook_quality(e["t"], _target_for(o, e["item"]), e["burn"])
					q *= Data.salt_factor(e["item"], e.get("salt", 0.0))   # bien salado (o sin sal si no lleva)
					q *= maxf(0.4, 1.0 - float(e.get("stuck", 0.0)) * 0.12)   # wok sin saltear: se pegó
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
			if e.has("fillings"):
				put = e["fillings"]       # maki: el relleno que se puso en la esterilla
				break
			if e.has("piped"):
				plate_sauce = e["piped"]      # el sabor del glaseado
				break
			if e.has("layers"):
				# Hamburguesa: los ingredientes son las capas que se apilaron en el Armado
				put = e["layers"].filter(func(l): return l != "Carne")
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
	var order_ok := -1.0
	if o.has("layers"):
		# Además, el orden de las capas: cuántas quedaron en su lugar
		var built: Array = []
		for e in o["plate"]:
			if e.has("layers"):
				built = e["layers"]
				break
		var want: Array = o["layers"]
		var same := 0
		for k in mini(want.size(), built.size()):
			if want[k] == built[k]:
				same += 1
		order_ok = 100.0 * same / maxi(want.size(), built.size()) if not built.is_empty() else 0.0
		s_tops = s_tops * 0.4 + order_ok * 0.6

	var wait: float = elapsed - o["arrived"]
	var patience: float = _patience()
	var s_wait := clampf(100.0 - maxf(0.0, wait - patience) * 1.0, 0.0, 100.0)

	var total := s_items * 0.3 + s_cook * 0.3 + s_sauce * 0.1 + s_tops * 0.1 + s_wait * 0.2
	if o.has("layers"):
		# Hamburguesa por capas: el armado en orden pesa como la cocción (no lleva salsa aparte)
		total = s_items * 0.25 + s_cook * 0.25 + s_tops * 0.3 + s_wait * 0.2
	if Data.RECIPES[o["recipe"]].get("rolled", false):
		# Maki: el relleno pedido pesa como la cocción
		total = s_items * 0.25 + s_cook * 0.25 + s_tops * 0.3 + s_wait * 0.2
	if o.has("spices"):
		# Curry: el orden de las especias pesa casi como la cocción
		total = s_items * 0.25 + s_cook * 0.25 + spice_q * 0.2 + s_sauce * 0.05 + s_tops * 0.05 + s_wait * 0.2
	var s_drink := -1.0
	if o.get("drink", "") != "":
		# Con bebida: pesa un 10% y el resto se reparte en proporción
		s_drink = 100.0 if o.get("plate_drink", "") == o["drink"] else 0.0
		if s_drink > 0.0 and o["drink"] == "Vino tinto":
			s_drink = Data.wine_score(o.get("wine_fill", 0.0), o.get("wine_spill", 0.0))
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
	tip += Data.STAR_TIP * _guide_stars(current_country)   # un local con estrellas de la guía deja más propina
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
	if o.get("drink", "") == "Vino tinto" and o.get("plate_drink", "") == "Vino tinto":
		last_result["lines"].append("Copa: %s" % Data.wine_desc(o.get("wine_fill", 0.0), o.get("wine_spill", 0.0)))
	if order_ok >= 0.0:
		last_result["lines"].append("Capas en orden %d" % int(order_ok))
	if o.has("spices"):
		last_result["lines"].append("Especias %d" % int(spice_q))
	if o.get("critic", false):
		critic_score = total
		last_result["verdict"] = "Mmm... (anota en la libreta)"
		_hint("El de anteojos oscuros probó, anotó algo y no dijo nada... al cerrar vas a saber qué escribió")

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
		var txt := "%d · %s" % [i + 1, _prep_name() if i == 2 else STATIONS[i]]
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
	if o.has("spices"):
		lines.append("%d especias en orden (Especiero)" % o["spices"].size())
	if o.has("layers"):
		lines.append("Capas: " + " / ".join(PackedStringArray(o["layers"])))
	elif not tops.is_empty():
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
	tip_refs.clear()
	customer_views.clear()
	kitchen_views.clear()
	mesa_view = null
	pasta_view = null
	press_view = null
	molcajete_view = null
	sushi_view = null
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
		2: _build_prep_station()
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
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, true).fps = 12.0

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
	var fridge_items := cook_items.filter(func(id): return not Data.ITEMS[id].get("built", false))   # la pizza se arma en la mesa
	var n := fridge_items.size()
	var rw := x - 110.0 if n > 0 else 640.0     # sin heladera, la receta tiene más lugar
	_build_order_recipe(o, Rect2(12, top, rw, STATION_SIZE.y - top - 4.0))
	# Salero: se mantiene apretado y se sacude encima de la plancha o la olla
	var shaker := _prop(Rect2(12.0 + rw + 16.0, top, 84.0, STATION_SIZE.y - top - 4.0))
	tip_refs["salero"] = shaker
	shaker.draw_fn = func(ci, r): Art.salt_shaker(ci, r.get_center() + Vector2(0, 4), minf(r.size.y / 50.0, 1.6), -0.2, false, 0.0)
	shaker.text = "Salero"
	shaker.text_size = 12
	shaker.mouse_default_cursor_shape = Control.CURSOR_DRAG
	shaker.tooltip_text = "Mantené apretado y sacudilo encima de lo que está en la plancha o la olla"
	shaker.held.connect(_start_salting)

	# Heladera con los ingredientes crudos: se arrastran hasta el aparato que corresponde
	var fx := x + 4.0
	var fw := STATION_SIZE.x - fx - 10.0
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
	if n > 0:
		tip_refs["heladera"] = _painter(Rect2(fx, 30, fw, 430), draw_fridge, false)
	else:
		# Sin nada de la heladera: se explica de dónde sale lo que va acá
		var msg := "Hoy no hace falta la heladera."
		match _prep():
			"mesa": msg = "Hoy en la cocina solo va el horno de leña.\n\nLa pizza se arma en la Mesa (tecla 3):\nestirás la masa, ponés salsa e ingredientes\ny la mandás al horno."
			"creperie": msg = "Hoy en la cocina solo va la crepera.\n\nLa masa se esparce en la Crêperie (tecla 3)\ny acá se da vuelta: tocá la crêpe cuando\nse dore abajo, y sacala con los dos lados listos."
			"tortilleria": msg = "Las tortillas se prensan en la Tortillería (tecla 3)\ny acá, en el comal, se dan vuelta."
		var note := _label(msg, 18, Color.WHITE, 5)
		note.position = Vector2(fx + 40, 80)
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
			if Data.ITEMS[id].get("fresh", false) and _uses_mesa():
				# Pasta fresca: solo lo que se amasó en la Mesa
				b.text = "%s (%d)" % [Data.ITEMS[id]["name"], fresh_pasta]
				if fresh_pasta <= 0:
					b.modulate.a = 0.45     # se puede tocar igual: avisa dónde se amasa
				b.tooltip_text = "Pasta fresca: se amasa en la Mesa (tecla 3). Quedan %d porciones" % fresh_pasta
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
	var names: Array = _drinks().filter(func(d): return Data.DRINKS[d]["kind"] != "vino")   # el vino va en copa, aparte
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
			if info.get("flip", false):
				where = "%s y %s: dala vuelta" % [_prep_name(), where.to_lower()]
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
		"assembled":
			match id:
				"masala": how = "Especiero: " + " > ".join(PackedStringArray(o.get("spices", [])))
				"eclair": how = "Crêperie: manga de %s" % o["sauce"].to_lower()
				_: how = "Plancha: medallón %s · Armado: capas en orden" % (entry["doneness"].to_lower() if entry["doneness"] != "" else "")
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


## Bebidas que se piden en este país (si no dice nada, todas)
func _drinks() -> Array:
	return Data.COUNTRIES[current_country].get("drinks", Data.DRINKS.keys())


func _prep() -> String:
	return Data.COUNTRIES[current_country].get("prep", "")


## Nombre de la estación 3: la tabla de cortar, o la estación propia del país
func _prep_name() -> String:
	match _prep():
		"mesa": return "Mesa"
		"tortilleria": return "Tortillería"
		"armado": return "Armado"
		"creperie": return "Crêperie"
		"especiero": return "Especiero"
		"esterilla": return "Esterilla"
	return "Tabla"


func _build_prep_station() -> void:
	match _prep():
		"mesa": _build_mesa_station()
		"tortilleria": _build_tortilleria_station()
		"armado": _build_armado_station()
		"creperie": _build_creperie_station()
		"especiero": _build_especiero_station()
		"esterilla": _build_esterilla_station()
		_: _build_board_station()


## ¿Hoy hay pasta fresca en el menú? (entonces la Mesa también sirve para amasarla)
func _fresh_items() -> Array:
	return _unlocked_items("cook").filter(func(id): return Data.ITEMS[id].get("fresh", false))


func _set_mesa_mode(m: String) -> void:
	mesa_mode = m
	_refresh_station()


func _build_mesa_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	if not _fresh_items().is_empty():
		# Arriba a la derecha: pizza o pasta fresca
		var modes := HBoxContainer.new()
		modes.position = Vector2(STATION_SIZE.x - 330, 2)
		modes.add_theme_constant_override("separation", 6)
		station_box.add_child(modes)
		for m in [["pizza", "Pizza"], ["pasta", "Pasta fresca (%d)" % fresh_pasta]]:
			var mb := _button(m[1], _set_mesa_mode.bind(m[0]), 14)
			mb.custom_minimum_size = Vector2(150, 30)
			if mesa_mode == m[0]:
				mb.add_theme_stylebox_override("normal", _sb(COL_SELECTED, Color("8a5a2b")))
			modes.add_child(mb)
		if mesa_mode == "pasta":
			_build_pasta_table()
			return
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


# --- 3 (Japón). Esterilla: maki roll ---

func _build_esterilla_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var o = _get_order(selected_id)
	_tag("Esterilla  ·  alga, arroz, el relleno pedido, enrollar y cortar", Vector2(12, 4), 15)
	var nori := _prop(Rect2(16, 40, 130, 100))
	nori.draw_fn = func(ci, r): Art.draw_nori_stack(ci, r)
	nori.text = "Alga nori"
	nori.text_size = 13
	nori.drag_data = {"kind": "nori"}
	nori.tooltip_text = "Arrastrala a la esterilla (o tocala)"
	nori.pressed.connect(_sushi_drop.bind({"kind": "nori"}))
	# Rellenos: se tocan cuando el arroz ya está
	var fills := _cat_options("Sushi", "toppings")
	var have: Array = sushi_roll["fillings"] if sushi_roll != null else []
	for k in fills.size():
		var fname: String = fills[k]
		var b := _prop(Rect2(16 + (k % 2) * 92, 150 + (k / 2) * 92, 88, 88))
		b.draw_fn = func(ci, rr): Art.draw_bowl(ci, rr, fname)
		b.text = fname
		b.text_size = 11
		b.selected = fname in have
		b.tooltip_text = "Relleno: %s (tocalo para ponerlo o sacarlo)" % fname.to_lower()
		b.pressed.connect(_sushi_filling.bind(fname))
	sushi_view = SushiView.new()
	sushi_view.position = Vector2(200, 36)
	sushi_view.size = Vector2(620, 428)
	sushi_view.roll = sushi_roll
	sushi_view.need_cuts = Data.SUSHI_CUTS
	sushi_view.dropped.connect(_sushi_drop)
	sushi_view.rice.connect(_sushi_rice)
	sushi_view.rolling.connect(_sushi_rolling)
	sushi_view.tapped.connect(_sushi_tap)
	station_box.add_child(sushi_view)
	var go := _button("¡Enrollar!", _sushi_start_roll, 20)
	go.position = Vector2(860, 50)
	go.custom_minimum_size = Vector2(200, 50)
	go.disabled = sushi_roll == null or int(sushi_roll["stage"]) != 2
	station_box.add_child(go)
	var drop := _button("Tirar", _sushi_discard, 14)
	drop.position = Vector2(1080, 60)
	drop.disabled = sushi_roll == null
	station_box.add_child(drop)
	# Lo que pidió el cliente
	var want: Array = o["toppings"] if o != null and Data.RECIPES[o["recipe"]].get("rolled", false) else []
	var title := "Elegí un ticket de maki" if want.is_empty() else "#%d %s pidió:" % [o["id"], o["name"]]
	var draw_want := func(ci, _t):
		Art.draw_paper(ci, Rect2(0, 0, 400, 330))
		Art.text(ci, Vector2(20, 40), title, 17, COL_INK)
		for k in want.size():
			Art.draw_bowl(ci, Rect2(24, 60 + k * 64, 56, 56), want[k])
			Art.text(ci, Vector2(96, 96 + k * 64), want[k], 19, COL_INK)
			if want[k] in have:
				Art.text(ci, Vector2(280, 96 + k * 64), "listo", 16, Color("2f7a3a"))
	_painter(Rect2(850, 120, 400, 330), draw_want, false)


func _sushi_drop(data: Dictionary) -> void:
	if data.get("kind", "") != "nori":
		return
	if sushi_roll != null:
		_hint("Ya hay un maki en la esterilla")
		return
	var cells := []
	cells.resize(SushiView.COLS * SushiView.ROWS)
	cells.fill(false)
	sushi_roll = {"stage": 1, "rice": cells, "fillings": [], "rolled": 0.0, "cuts": 0}
	_refresh_station()


func _sushi_rice() -> void:
	if sushi_roll == null or int(sushi_roll["stage"]) != 1:
		return
	if knead_sound_t <= 0.0:
		_play_sfx("frotar", -12.0)
		knead_sound_t = 0.3
	var cells: Array = sushi_roll["rice"]
	if cells.filter(func(x): return x).size() >= int(cells.size() * 0.9):
		for k in cells.size():
			cells[k] = true
		sushi_roll["stage"] = 2
		_hint("¡Arroz listo! Ahora el relleno que pidió")
		_refresh_station()


func _sushi_filling(fname: String) -> void:
	if sushi_roll == null or int(sushi_roll["stage"]) != 2:
		_hint("Primero el alga y el arroz" if sushi_roll == null or int(sushi_roll["stage"]) < 2 else "El maki ya está enrollado")
		return
	var f: Array = sushi_roll["fillings"]
	if fname in f:
		f.erase(fname)
	elif f.size() >= 4:
		_hint("No entra más relleno")
		return
	else:
		f.append(fname)
	_refresh_station()


func _sushi_start_roll() -> void:
	if sushi_roll == null or int(sushi_roll["stage"]) != 2:
		return
	if sushi_roll["fillings"].is_empty():
		_hint("Le falta el relleno")
		return
	sushi_roll["stage"] = 3
	_hint("Deslizá hacia arriba para enrollar")
	_refresh_station()


func _sushi_rolling(dy: float) -> void:
	if sushi_roll == null or int(sushi_roll["stage"]) != 3:
		return
	sushi_roll["rolled"] = minf(1.0, float(sushi_roll["rolled"]) + dy / Data.ROLL_PX)
	if sushi_roll["rolled"] >= 1.0:
		sushi_roll["stage"] = 4
		_hint("¡Enrollado! Cortalo en piezas")
		_refresh_station()


func _sushi_tap() -> void:
	if sushi_roll == null:
		_hint("Arrastrá una hoja de alga a la esterilla")
		return
	match int(sushi_roll["stage"]):
		2:
			_hint("Tocá los rellenos de la izquierda y después ¡Enrollar!")
		4:
			sushi_roll["cuts"] = int(sushi_roll["cuts"]) + 1
			_play_sfx("corte%d" % (rng.randi() % 3 + 1), -4.0)
			if sushi_view != null and is_instance_valid(sushi_view):
				sushi_view.bump()
			if int(sushi_roll["cuts"]) >= Data.SUSHI_CUTS:
				var f: Array = sushi_roll["fillings"]
				prepared.append({"item": "maki", "t": -1.0, "fillings": f.duplicate(), "pantry": false, "chopped": false,
					"label": "Maki (%s)" % ", ".join(PackedStringArray(f)).to_lower()})
				sushi_roll = null
				_hint("¡Maki listo! Está en la bandeja del Emplatado")
				_refresh_all()


func _sushi_discard() -> void:
	if sushi_roll == null:
		return
	sushi_roll = null
	money -= Data.WASTE_COST["chop"]
	_refresh_station()


# --- 3 (India). Especiero: el masala con las especias en el orden del ticket ---

## Qué tan bien coincide una secuencia con la pedida: cada elemento en su lugar suma; de más o de menos resta
func _seq_score(want: Array, got: Array) -> float:
	if want.is_empty():
		return 100.0
	var same := 0
	for k in mini(want.size(), got.size()):
		if want[k] == got[k]:
			same += 1
	return 100.0 * same / maxi(want.size(), got.size())


func _build_especiero_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var o = _get_order(selected_id)
	_tag("Especiero  ·  tocá las especias de la masala dabba en el orden del ticket y servilo cuando esté completo", Vector2(12, 4), 15)
	# Izquierda: la masala dabba (la caja redonda con las latitas)
	var names: Array = Data.SPICES.keys()
	var dabba := func(ci, _t):
		ci.draw_circle(Vector2(170, 210), 166, Color(0, 0, 0, 0.25))
		ci.draw_circle(Vector2(166, 204), 164, Color("c9ccd0"))
		ci.draw_circle(Vector2(166, 204), 152, Color("e2e5e8"))
	_painter(Rect2(10, 40, 340, 420), dabba, false)
	for k in names.size():
		var nm: String = names[k]
		var col: Color = Data.SPICES[nm]
		var p: Vector2 = Vector2(176, 244) + (Vector2.ZERO if k == names.size() - 1 else Vector2.from_angle(-PI / 2.0 + k * TAU / (names.size() - 1)) * 102.0)
		var b := _prop(Rect2(p - Vector2(50, 50), Vector2(100, 100)))
		b.draw_fn = func(ci, r): Art.draw_spice_tin(ci, r, col)
		b.text = nm
		b.text_size = 12
		b.pressed.connect(_masala_add.bind(nm))
	# Centro: el karahi con lo que se va agregando
	var added: Array = masala_pan["spices"] if masala_pan != null else []
	var karahi := func(ci, t):
		Art.draw_karahi(ci, Vector2(190, 170), 150.0, added, t)
		if added.is_empty():
			Art.text(ci, Vector2(0, 340), "Tocá la primera especia", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 380, 4)
	_painter(Rect2(360, 40, 380, 360), karahi, true)
	var undo := _button("Empezar de nuevo", _masala_discard, 15)
	undo.position = Vector2(390, 410)
	undo.disabled = masala_pan == null
	station_box.add_child(undo)
	var done := _button("¡Masala listo!", _masala_finish, 19)
	done.position = Vector2(570, 406)
	done.custom_minimum_size = Vector2(170, 0)
	done.disabled = added.is_empty()
	station_box.add_child(done)
	# Derecha: el orden que pidió el cliente
	var want: Array = o.get("spices", []) if o != null else []
	var title := "Elegí un ticket con curry" if want.is_empty() else "#%d %s: %s" % [o["id"], o["name"], Data.RECIPES[o["recipe"]]["name"]]
	var draw_want := func(ci, _t):
		Art.draw_paper(ci, Rect2(0, 0, 500, 420))
		Art.text(ci, Vector2(20, 40), title, 17, COL_INK)
		if want.is_empty():
			return
		Art.text(ci, Vector2(20, 66), "Especias, en este orden:", 14, Color(0.35, 0.28, 0.2))
		for k in want.size():
			var nm: String = want[k]
			var y := 110.0 + k * 52.0
			Art.draw_spice_tin(ci, Rect2(24, y - 22, 44, 44), Data.SPICES[nm])
			Art.text(ci, Vector2(80, y + 7), "%d. %s" % [k + 1, nm], 19, COL_INK)
			if k < added.size():
				var good: bool = added[k] == nm
				Art.text(ci, Vector2(330, y + 7), "bien" if good else "¡no era esa!", 16, Color("2f7a3a") if good else Color("c0281a"))
	_painter(Rect2(760, 36, 500, 420), draw_want, false)


func _masala_add(nm: String) -> void:
	if masala_pan == null:
		masala_pan = {"spices": []}
	if masala_pan["spices"].size() >= 6:
		_hint("¡Ya tiene demasiadas especias!")
		return
	masala_pan["spices"].append(nm)
	_play_sfx("salero", -4.0)
	_refresh_station()


func _masala_finish() -> void:
	if masala_pan == null or masala_pan["spices"].is_empty():
		return
	prepared.append({"item": "masala", "t": -1.0, "spices": masala_pan["spices"].duplicate(), "pantry": false, "chopped": false,
		"label": "Masala (%d especias)" % masala_pan["spices"].size()})
	masala_pan = null
	_play_sfx("plato", -6.0)
	_hint("¡Masala listo! Está en la bandeja del Emplatado")
	_refresh_all()


func _masala_discard() -> void:
	if masala_pan == null:
		return
	masala_pan = null
	money -= Data.WASTE_COST["chop"]
	_refresh_station()


# --- 3 (Francia). Crêperie: esparcir crêpes y decorar éclairs con la manga ---

func _set_crepe_mode(m: String) -> void:
	crepe_mode = m
	_refresh_station()


func _build_creperie_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var has_eclair := "eclair" in _unlocked_items("assembled")
	if has_eclair:
		var modes := HBoxContainer.new()
		modes.position = Vector2(STATION_SIZE.x - 330, 2)
		modes.add_theme_constant_override("separation", 6)
		station_box.add_child(modes)
		for m in [["crepes", "Crêpes"], ["manga", "Manga · éclairs"]]:
			var mb := _button(m[1], _set_crepe_mode.bind(m[0]), 14)
			mb.custom_minimum_size = Vector2(150, 30)
			if crepe_mode == m[0]:
				mb.add_theme_stylebox_override("normal", _sb(COL_SELECTED, Color("8a5a2b")))
			modes.add_child(mb)
		if crepe_mode == "manga":
			_build_piping()
			return
	_tag("Crêpes  ·  cucharón de masa a la crêpière, esparcila en círculos con el rastrillo y a la crepera", Vector2(12, 4), 15)
	var bowl := _prop(Rect2(20, 70, 160, 150))
	bowl.draw_fn = func(ci, r): Art.draw_batter_bowl(ci, r)
	bowl.text = "Masa de crêpes"
	bowl.text_size = 14
	bowl.drag_data = {"kind": "batter"}
	bowl.tooltip_text = "Arrastrá el cucharón a la crêpière (o tocalo)"
	bowl.pressed.connect(_crepe_drop.bind({"kind": "batter"}))
	if crepe_batter != null:
		var drop := _button("Tirar la masa", _crepe_discard, 14)
		drop.position = Vector2(40, 250)
		station_box.add_child(drop)
	var cv := CrepeView.new()
	cv.position = Vector2(220, 36)
	cv.size = Vector2(560, 428)
	cv.crepe = crepe_batter
	cv.dropped.connect(_crepe_drop)
	cv.spread.connect(_crepe_spread)
	cv.tapped.connect(_crepe_tap)
	station_box.add_child(cv)
	var go := _button("¡A la crepera!", _crepe_to_pan, 22)
	go.position = Vector2(880, 120)
	go.custom_minimum_size = Vector2(260, 60)
	go.disabled = crepe_batter == null or float(crepe_batter["spread"]) < 1.0
	station_box.add_child(go)
	var used := 0
	for s in cookers.get("crepera", []):
		if s != null:
			used += 1
	var n_slots: int = cookers.get("crepera", []).size()
	var info := func(ci, _t):
		Art.rrect(ci, Rect2(0, 0, 340, 150), Color(0, 0, 0, 0.35), 12)
		Art.text(ci, Vector2(0, 34), "Crepera: %d de %d lugares ocupados" % [used, n_slots], 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 340, 4)
		Art.text(ci, Vector2(16, 70), "En la Cocina: tocá la crêpe para darla", 15, Color(1, 1, 1, 0.85))
		Art.text(ci, Vector2(16, 94), "vuelta cuando se dore abajo, y tocá el", 15, Color(1, 1, 1, 0.85))
		Art.text(ci, Vector2(16, 118), "cartelito para sacarla con los dos lados.", 15, Color(1, 1, 1, 0.85))
	_painter(Rect2(840, 210, 340, 150), info, false)


func _crepe_drop(data: Dictionary) -> void:
	if data.get("kind", "") != "batter":
		return
	if crepe_batter != null:
		_hint("Ya hay masa en la crêpière")
		return
	crepe_batter = {"spread": 0.0}
	_play_sfx("chapoteo", -10.0)
	_refresh_station()


func _crepe_spread(turns: float) -> void:
	if crepe_batter == null or float(crepe_batter["spread"]) >= 1.0:
		return
	crepe_batter["spread"] = minf(1.0, float(crepe_batter["spread"]) + turns / Data.CREPE_SPREAD_TURNS)
	if knead_sound_t <= 0.0:
		_play_sfx("frotar", -12.0)
		knead_sound_t = 0.35
	if crepe_batter["spread"] >= 1.0:
		_hint("¡Bien finita! Mandala a la crepera")
		_refresh_station()


func _crepe_tap() -> void:
	if crepe_batter == null:
		_hint("Arrastrá el cucharón con masa a la crêpière")
	elif float(crepe_batter["spread"]) >= 1.0:
		_crepe_to_pan()


func _crepe_to_pan() -> void:
	if crepe_batter == null or float(crepe_batter["spread"]) < 1.0:
		return
	var slots: Array = cookers["crepera"]
	var idx := slots.find(null)
	if idx == -1:
		_hint("La crepera está llena: sacá alguna crêpe en la Cocina")
		return
	var info: Dictionary = Data.ITEMS["crepe"]
	slots[idx] = {"item": "crepe", "t": 0.0, "ta": 0.0, "tb": 0.0, "target": info["target"], "burn": info["burn"], "flip": true}
	crepe_batter = null
	_hint("¡A la crepera! Dala vuelta cuando se dore")
	_refresh_all()


func _crepe_discard() -> void:
	if crepe_batter == null:
		return
	crepe_batter = null
	money -= Data.WASTE_COST["chop"]
	_hint("Tiraste la masa: -$%d de la caja" % Data.WASTE_COST["chop"])
	_refresh_station()


func _build_piping() -> void:
	var o = _get_order(selected_id)
	var head := "Manga  ·  elegí el sabor y seguí la línea punteada sobre el éclair manteniendo apretado"
	if o != null and o["recipe"] == "eclair":
		head = "Ticket #%d %s: éclair de %s" % [o["id"], o["name"], o["sauce"].to_lower()]
	_tag(head, Vector2(12, 4), 15)
	var flavors: Array = Data.PIPE_FLAVORS.keys()
	for k in flavors.size():
		var fl: String = flavors[k]
		var col: Color = Data.PIPE_FLAVORS[fl]
		var b := _prop(Rect2(16, 44 + k * 132, 170, 126))
		b.draw_fn = func(ci, r): Art.draw_piping_bag(ci, r, col)
		b.text = fl
		b.text_size = 15
		b.selected = pipe != null and pipe["flavor"] == fl
		b.tooltip_text = "Manga de %s" % fl.to_lower()
		b.pressed.connect(_pipe_start.bind(fl))
	var pv := PipingView.new()
	pv.position = Vector2(200, 40)
	pv.size = Vector2(760, 420)
	pv.pipe = pipe
	if pipe != null:
		pv.color = Data.PIPE_FLAVORS[pipe["flavor"]]
	station_box.add_child(pv)
	var done := _button("¡Éclair listo!", _pipe_finish, 20)
	done.position = Vector2(990, 160)
	done.custom_minimum_size = Vector2(250, 56)
	done.disabled = pipe == null
	station_box.add_child(done)
	var again := _button("Empezar de nuevo", _pipe_discard, 15)
	again.position = Vector2(1020, 240)
	again.disabled = pipe == null
	station_box.add_child(again)


func _pipe_start(fl: String) -> void:
	if pipe != null and not pipe["pts"].is_empty() and pipe["flavor"] != fl:
		_hint("Ya empezaste con %s: terminalo o empezá de nuevo" % pipe["flavor"].to_lower())
		return
	var cov := []
	cov.resize(41)
	cov.fill(false)
	pipe = {"flavor": fl, "pts": [], "covered": cov, "mess": 0.0}
	_refresh_station()


## Nota del éclair: cuánto de la guía se cubrió, menos lo que se ensució afuera
func _pipe_score(p: Dictionary) -> float:
	var cov: Array = p["covered"]
	var n := cov.filter(func(x): return x).size()
	return clampf(100.0 * n / cov.size() * 1.1 - float(p["mess"]) * 0.8, 0.0, 100.0)


func _pipe_finish() -> void:
	if pipe == null or pipe["pts"].is_empty():
		return
	var q := _pipe_score(pipe)
	prepared.append({"item": "eclair", "t": -1.0, "piped": pipe["flavor"], "pipe_q": q, "pantry": false, "chopped": false,
		"label": "Éclair de %s" % pipe["flavor"].to_lower()})
	pipe = null
	_play_sfx("plato", -6.0)
	_hint("¡Éclair decorado (%d%%)! Está en la bandeja del Emplatado" % int(q))
	_refresh_all()


func _pipe_discard() -> void:
	if pipe == null:
		return
	pipe = null
	money -= Data.WASTE_COST["chop"]
	_refresh_station()


# --- 3 (EE.UU.). Armado: la hamburguesa capa por capa, en el orden del ticket ---

func _patties() -> Array:
	return prepared.filter(func(e): return Data.ITEMS[e["item"]].get("where", "") == "plancha" and \
		not Data.RECIPES.values().filter(func(r): return e["item"] in r.get("uses", [])).is_empty())


func _build_armado_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var o = _get_order(selected_id)
	_tag("Armado  ·  tocá los ingredientes en el orden del ticket, de abajo hacia arriba, y cerrá con el pan", Vector2(12, 4), 15)
	# Izquierda: los cajones de ingredientes (la carne sale de la bandeja: hay que cocinarla antes)
	var names: Array = ["Carne"] + _cat_options("Burgers", "toppings")
	var n_patty := _patties().size()
	for k in names.size():
		var nm: String = names[k]
		var b := _prop(Rect2(12 + (k % 3) * 104, 40 + (k / 3) * 104, 100, 100))
		b.draw_fn = func(ci, r): Art.draw_layer_bin(ci, r, nm)
		b.text = nm if nm != "Carne" else "Carne (%d)" % n_patty
		b.text_size = 13
		if nm == "Carne" and n_patty == 0:
			b.modulate.a = 0.5
			b.tooltip_text = "No hay medallones en la bandeja: cociná uno en la plancha"
		b.pressed.connect(_armado_add.bind(nm))
	# Centro: la hamburguesa que se está armando
	var layers: Array = burger_stack["layers"] if burger_stack != null else []
	var draw_stack := func(ci, _t):
		Art.rrect(ci, Rect2(20, 300, 340, 40), Color("dfe5ea"), 18, Color("aab3ba"), 2)
		if burger_stack == null:
			Art.text(ci, Vector2(0, 200), "Tocá un ingrediente para empezar", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 380, 4)
			return
		Art.draw_burger(ci, Rect2(60, 10, 260, 302), layers, false, -1.0, 7.0, 14.0, true)
	_painter(Rect2(330, 40, 380, 340), draw_stack, true)
	var undo := _button("Sacar la última capa", _armado_undo, 15)
	undo.position = Vector2(350, 396)
	undo.disabled = layers.is_empty()
	station_box.add_child(undo)
	var close := _button("¡Tapa y lista!", _armado_close, 19)
	close.position = Vector2(540, 392)
	close.custom_minimum_size = Vector2(170, 0)
	close.disabled = burger_stack == null or burger_stack.get("patty") == null
	station_box.add_child(close)
	# Derecha: lo que pidió el cliente, capa por capa (con tilde si coincide)
	var want: Array = o.get("layers", []) if o != null else []
	var title := "Elegí un ticket con hamburguesa" if want.is_empty() else "#%d %s: %s" % [o["id"], o["name"], _req_text(o["items"][0])]
	var draw_want := func(ci, _t):
		Art.draw_paper(ci, Rect2(0, 0, 520, 420))
		Art.text(ci, Vector2(20, 40), title, 17, COL_INK)
		if want.is_empty():
			return
		Art.text(ci, Vector2(20, 66), "Capas, de abajo hacia arriba:", 14, Color(0.35, 0.28, 0.2))
		var rows: Array = ["PanAbajo"] + want + ["PanArriba"]
		for k in rows.size():
			var nm: String = rows[k]
			var y := 380.0 - k * 40.0
			var shown: String = {"PanAbajo": "Pan de abajo", "PanArriba": "Pan de arriba"}.get(nm, nm)
			Art.draw_layer_bin(ci, Rect2(30, y - 34, 60, 38), nm)
			Art.text(ci, Vector2(104, y - 8), shown, 17, COL_INK)
			if k >= 1 and k <= want.size() and k - 1 < layers.size():
				var good: bool = layers[k - 1] == nm
				Art.text(ci, Vector2(300, y - 8), "bien" if good else "¡no va acá!", 15, Color("2f7a3a") if good else Color("c0281a"))
	_painter(Rect2(740, 36, 520, 420), draw_want, false)


func _armado_add(nm: String) -> void:
	if burger_stack == null:
		burger_stack = {"layers": [], "patty": null}
	if nm == "Carne":
		if burger_stack["patty"] != null:
			_hint("Ya tiene la carne")
			return
		var pats := _patties()
		if pats.is_empty():
			_hint("No hay medallones en la bandeja: cociná uno en la plancha (Cocina)")
			return
		# El que está más cerca del punto que pidió el ticket elegido
		var o = _get_order(selected_id)
		var best: Dictionary = pats[0]
		if o != null:
			for p in pats:
				if absf(p["t"] - _target_for(o, p["item"])) < absf(best["t"] - _target_for(o, best["item"])):
					best = p
		prepared.erase(best)
		burger_stack["patty"] = best
	if burger_stack["layers"].size() >= 8:
		_hint("¡No entra nada más!")
		return
	burger_stack["layers"].append(nm)
	_play_sfx("plato", -10.0)
	_refresh_station()


func _armado_undo() -> void:
	if burger_stack == null or burger_stack["layers"].is_empty():
		return
	var last: String = burger_stack["layers"].pop_back()
	if last == "Carne" and burger_stack["patty"] != null:
		prepared.append(burger_stack["patty"])     # el medallón vuelve a la bandeja
		burger_stack["patty"] = null
	if burger_stack["layers"].is_empty():
		burger_stack = null
	_refresh_station()


func _armado_close() -> void:
	if burger_stack == null or burger_stack["patty"] == null:
		_hint("Falta la carne: cociná un medallón y agregalo")
		return
	var p: Dictionary = burger_stack["patty"]
	var layers: Array = burger_stack["layers"]
	prepared.append({"item": "burger", "t": -1.0, "patty_t": p["t"], "vtarget": p.get("vtarget", 7.0), "burn": p["burn"],
		"salt": p.get("salt", 0.0), "dirty": p.get("dirty", false), "layers": layers.duplicate(), "pantry": false, "chopped": false,
		"label": "Hamburguesa (%d capas)" % layers.size()})
	burger_stack = null
	_play_sfx("plato", -6.0)
	_hint("¡Hamburguesa armada! Está en la bandeja del Emplatado")
	_refresh_all()


# --- 3 (México). Tortillería: prensa de tortillas y molcajete ---

func _set_tort_mode(m: String) -> void:
	tort_mode = m
	_refresh_station()


func _build_tortilleria_station() -> void:
	var draw_bg := func(ci, _t): Art.draw_wood_counter(ci, Rect2(Vector2.ZERO, STATION_SIZE))
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, false)
	var modes := HBoxContainer.new()
	modes.position = Vector2(STATION_SIZE.x - 380, 2)
	modes.add_theme_constant_override("separation", 6)
	station_box.add_child(modes)
	var total_salsa := 0
	for s in salsa_stock:
		total_salsa += int(salsa_stock[s])
	for m in [["tortillas", "Prensa y comal"], ["molcajete", "Molcajete · salsas (%d)" % total_salsa]]:
		var mb := _button(m[1], _set_tort_mode.bind(m[0]), 14)
		mb.custom_minimum_size = Vector2(150, 30)
		if tort_mode == m[0]:
			mb.add_theme_stylebox_override("normal", _sb(COL_SELECTED, Color("8a5a2b")))
		modes.add_child(mb)
	if tort_mode == "molcajete":
		_build_molcajete()
		return
	_tag("Tortillas  ·  bolita de masa a la prensa, bajá la palanca y al comal (en la Cocina se dan vuelta)", Vector2(12, 4), 15)
	var masa := _prop(Rect2(20, 70, 160, 150))
	masa.draw_fn = func(ci, r): Art.draw_masa_bowl(ci, r)
	masa.text = "Masa de maíz"
	masa.text_size = 14
	masa.drag_data = {"kind": "masa"}
	masa.tooltip_text = "Arrastrá una bolita a la prensa (o tocala)"
	masa.pressed.connect(_press_drop.bind({"kind": "masa"}))
	if press_masa != null:
		var drop := _button("Tirar la masa", _press_discard, 14)
		drop.position = Vector2(40, 250)
		station_box.add_child(drop)
	press_view = PressView.new()
	press_view.position = Vector2(220, 36)
	press_view.size = Vector2(560, 428)
	press_view.masa = press_masa
	press_view.dropped.connect(_press_drop)
	press_view.pressing.connect(_press_lever)
	press_view.tapped.connect(_press_tap)
	station_box.add_child(press_view)
	# Derecha: mandar al comal y cómo está el comal
	var go := _button("¡Al comal!", _press_to_comal, 22)
	go.position = Vector2(880, 120)
	go.custom_minimum_size = Vector2(260, 60)
	go.disabled = press_masa == null or float(press_masa["pressed"]) < 1.0
	station_box.add_child(go)
	var used := 0
	for s in cookers.get("comal", []):
		if s != null:
			used += 1
	var n_slots: int = cookers.get("comal", []).size()
	var info := func(ci, _t):
		Art.rrect(ci, Rect2(0, 0, 340, 150), Color(0, 0, 0, 0.35), 12)
		Art.text(ci, Vector2(0, 34), "Comal: %d de %d lugares ocupados" % [used, n_slots], 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 340, 4)
		Art.text(ci, Vector2(16, 70), "En la Cocina: tocá la tortilla para darla", 15, Color(1, 1, 1, 0.85))
		Art.text(ci, Vector2(16, 94), "vuelta (se cocina el lado de abajo) y tocá", 15, Color(1, 1, 1, 0.85))
		Art.text(ci, Vector2(16, 118), "el cartelito para sacarla cuando están los dos.", 15, Color(1, 1, 1, 0.85))
	_painter(Rect2(840, 210, 340, 150), info, false)


func _press_drop(data: Dictionary) -> void:
	if data.get("kind", "") != "masa":
		return
	if press_masa != null:
		_hint("Ya hay masa en la prensa")
		return
	press_masa = {"pressed": 0.0}
	_refresh_station()


func _press_lever(amount: float) -> void:
	if press_masa == null or float(press_masa["pressed"]) >= 1.0:
		return
	press_masa["pressed"] = minf(1.0, float(press_masa["pressed"]) + amount)
	if press_masa["pressed"] >= 1.0:
		_play_sfx("plato", -6.0)
		_hint("¡Tortilla aplanada! Mandala al comal")
		_refresh_station()


func _press_tap() -> void:
	if press_masa == null:
		_hint("Arrastrá una bolita de masa a la prensa")
	elif float(press_masa["pressed"]) >= 1.0:
		_press_to_comal()


func _press_to_comal() -> void:
	if press_masa == null or float(press_masa["pressed"]) < 1.0:
		return
	var slots: Array = cookers["comal"]
	var idx := slots.find(null)
	if idx == -1:
		_hint("El comal está lleno: sacá alguna tortilla en la Cocina")
		return
	var info: Dictionary = Data.ITEMS["tortilla"]
	slots[idx] = {"item": "tortilla", "t": 0.0, "ta": 0.0, "tb": 0.0, "target": info["target"], "burn": info["burn"], "flip": true}
	press_masa = null
	_hint("¡Al comal! Dala vuelta cuando se infle")
	_refresh_all()


func _press_discard() -> void:
	if press_masa == null:
		return
	press_masa = null
	money -= Data.WASTE_COST["chop"]
	_hint("Tiraste la masa: -$%d de la caja" % Data.WASTE_COST["chop"])
	_refresh_station()


func _build_molcajete() -> void:
	_tag("Molcajete  ·  elegí la salsa y molela haciendo círculos. Cada molida rinde %d porciones" % Data.MOLCAJETE_YIELD, Vector2(12, 4), 15)
	var names: Array = Data.MOLCAJETE.keys()
	for k in names.size():
		var sname: String = names[k]
		var ings: Array = Data.MOLCAJETE[sname]
		var have: int = salsa_stock.get(sname, 0)
		var b := _prop(Rect2(16, 44 + k * 136, 250, 130))
		b.draw_fn = func(ci, r):
			Art.rrect(ci, r.grow(-4), Color(0, 0, 0, 0.3), 10)
			Art.draw_bottle(ci, Rect2(r.position + Vector2(12, 10), Vector2(64, 90)), Art.SAUCE_COLORS.get(sname, Color.WHITE))
			Art.text(ci, r.position + Vector2(84, 34), sname, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
			for j in ings.size():
				ci.draw_circle(r.position + Vector2(94 + j * 26, 60), 9, MolcajeteView.piece_color(ings[j]))
			Art.text(ci, r.position + Vector2(84, 98), "Listas: %d" % have, 16, Color("ffe08a") if have > 0 else Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		b.selected = molcajete != null and molcajete["sauce"] == sname
		b.tooltip_text = "Poner los ingredientes de %s en el molcajete" % sname.to_lower()
		b.pressed.connect(_molcajete_load.bind(sname))
	if molcajete != null:
		var drop := _button("Vaciar el molcajete", _molcajete_discard, 14)
		drop.position = Vector2(320, 44)
		station_box.add_child(drop)
	molcajete_view = MolcajeteView.new()
	molcajete_view.position = Vector2(300, 36)
	molcajete_view.size = Vector2(560, 428)
	molcajete_view.bowl = molcajete
	molcajete_view.ground.connect(_molcajete_grind)
	molcajete_view.tapped.connect(_hint.bind("Elegí una salsa de la izquierda para cargar el molcajete"))
	station_box.add_child(molcajete_view)
	var tip := func(ci, _t):
		Art.rrect(ci, Rect2(0, 0, 360, 140), Color(0, 0, 0, 0.35), 12)
		Art.text(ci, Vector2(16, 34), "Las salsas molidas se usan en el", 15, Color.WHITE)
		Art.text(ci, Vector2(16, 58), "Emplatado. Si se acaba una, no se puede", 15, Color.WHITE)
		Art.text(ci, Vector2(16, 82), "servir: conviene tener las tres listas", 15, Color.WHITE)
		Art.text(ci, Vector2(16, 106), "antes de que se llene el mostrador.", 15, Color.WHITE)
	_painter(Rect2(890, 120, 360, 140), tip, false)


func _molcajete_load(sname: String) -> void:
	if molcajete != null:
		if molcajete["sauce"] == sname:
			return
		_hint("El molcajete está ocupado: terminá de moler o vacialo")
		return
	molcajete = {"sauce": sname, "ground": 0.0, "items": Data.MOLCAJETE[sname]}
	_refresh_station()


func _molcajete_grind(turns: float) -> void:
	if molcajete == null:
		return
	molcajete["ground"] = minf(1.0, float(molcajete["ground"]) + turns / Data.MOLCAJETE_TURNS)
	if knead_sound_t <= 0.0:
		_play_sfx("frotar", -8.0)
		knead_sound_t = 0.3
	if molcajete["ground"] >= 1.0:
		var sname: String = molcajete["sauce"]
		salsa_stock[sname] = int(salsa_stock.get(sname, 0)) + Data.MOLCAJETE_YIELD
		molcajete = null
		_hint("¡%s lista! %d porciones para el Emplatado" % [sname, Data.MOLCAJETE_YIELD])
		_refresh_all()


func _molcajete_discard() -> void:
	if molcajete == null:
		return
	molcajete = null
	money -= Data.WASTE_COST["chop"]
	_hint("Vaciaste el molcajete: -$%d de la caja" % Data.WASTE_COST["chop"])
	_refresh_station()


## ¿Esta salsa sale del molcajete? (en ese caso tiene porciones contadas)
func _ground_sauce(s: String) -> bool:
	return _prep() == "tortilleria" and Data.MOLCAJETE.has(s)


## Mesa en modo pasta: harina y huevos a la izquierda, la tabla en el medio, lo que hay listo a la derecha
func _build_pasta_table() -> void:
	_tag("Pasta fresca  ·  volcán de harina, huevos, amasar, estirar y cortar. Cada tanda rinde %d porciones" % Data.PASTA_YIELD, Vector2(12, 4), 15)
	var flour := _prop(Rect2(20, 60, 150, 140))
	flour.draw_fn = func(ci, r): Art.draw_flour_bag(ci, r)
	flour.text = "Harina"
	flour.text_size = 14
	flour.drag_data = {"kind": "harina"}
	flour.tooltip_text = "Arrastrala a la tabla (o tocala)"
	flour.pressed.connect(_pasta_drop.bind({"kind": "harina"}))
	var eggs := _prop(Rect2(20, 220, 150, 120))
	eggs.draw_fn = func(ci, r): Art.draw_eggs(ci, r)
	eggs.text = "Huevos"
	eggs.text_size = 14
	eggs.drag_data = {"kind": "huevo"}
	eggs.tooltip_text = "Arrastralos al medio del volcán de harina (o tocalos)"
	eggs.pressed.connect(_pasta_drop.bind({"kind": "huevo"}))
	if mesa_pasta != null:
		var drop := _button("Tirar la masa", _pasta_discard, 14)
		drop.position = Vector2(30, 370)
		station_box.add_child(drop)
	pasta_view = PastaView.new()
	pasta_view.position = Vector2(190, 40)
	pasta_view.size = Vector2(560, 424)
	pasta_view.pasta = mesa_pasta
	pasta_view.dropped.connect(_pasta_drop)
	pasta_view.worked.connect(_pasta_work)
	pasta_view.tapped.connect(_pasta_tap)
	station_box.add_child(pasta_view)
	# Derecha: las porciones listas, como nidos de fettuccine
	var n := fresh_pasta
	var draw_ready := func(ci, _t):
		Art.rrect(ci, Rect2(0, 0, 480, 380), Color(1, 1, 1, 0.12), 12, Color(1, 1, 1, 0.4), 2)
		Art.text(ci, Vector2(0, 30), "PASTA FRESCA LISTA", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 480, 4)
		for k in mini(n, 8):
			Art.draw_pasta_nest(ci, Vector2(70 + (k % 4) * 112, 110 + (k / 4) * 110), 46.0, k)
		if n == 0:
			Art.text(ci, Vector2(20, 150), "Todavía no hay: amasá una tanda.", 17, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 440, 4)
		Art.text(ci, Vector2(20, 300), "%d %s · van a la olla desde la heladera de la Cocina" % [n, "porción" if n == 1 else "porciones"],
			15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 440, 4)
		Art.text(ci, Vector2(20, 330), "Consejo: amasá antes de que lleguen los pedidos", 14, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 440, 4)
	_painter(Rect2(780, 60, 480, 380), draw_ready, false)


func _pasta_drop(data: Dictionary) -> void:
	match data.get("kind", ""):
		"harina":
			if mesa_pasta != null:
				_hint("Ya hay masa en la tabla")
				return
			mesa_pasta = {"stage": 1, "knead": 0.0, "roll": 0.0, "cuts": 0, "need_cuts": Data.PASTA_CUTS}
			_refresh_station()
		"huevo":
			if mesa_pasta == null:
				_hint("Primero la harina: hacé el volcán")
				return
			if int(mesa_pasta["stage"]) != 1:
				_hint("Los huevos ya están")
				return
			mesa_pasta["stage"] = 2
			_refresh_station()


## Frotar la masa (amasar) o pasar el palote (estirar): avanza según cuánto se movió la mano
func _pasta_work(dist: float) -> void:
	if mesa_pasta == null:
		return
	match int(mesa_pasta["stage"]):
		2:
			mesa_pasta["knead"] = minf(1.0, float(mesa_pasta["knead"]) + dist / Data.PASTA_KNEAD_PX)
			if mesa_pasta["knead"] >= 1.0:
				mesa_pasta["stage"] = 3
				_hint("¡Masa lisa! Ahora estirala con el palote")
		3:
			mesa_pasta["roll"] = minf(1.0, float(mesa_pasta["roll"]) + dist / Data.PASTA_ROLL_PX)
			if mesa_pasta["roll"] >= 1.0:
				mesa_pasta["stage"] = 4
				_hint("¡Lámina lista! Cortá las tiras: tocá la masa")
		_:
			return
	if knead_sound_t <= 0.0:
		_play_sfx("frotar", -6.0)
		knead_sound_t = 0.3


func _pasta_tap() -> void:
	if mesa_pasta == null:
		_hint("Arrastrá la harina a la tabla")
		return
	match int(mesa_pasta["stage"]):
		1:
			_hint("Faltan los huevos en el medio del volcán")
		2:
			_hint("Mantené apretado y frotá para amasar")
		3:
			_hint("Mantené apretado y pasá el palote")
		4:
			mesa_pasta["cuts"] = int(mesa_pasta["cuts"]) + 1
			_play_sfx("corte%d" % (rng.randi() % 3 + 1), -4.0)
			if pasta_view != null and is_instance_valid(pasta_view):
				pasta_view.bump()
			if int(mesa_pasta["cuts"]) >= int(mesa_pasta["need_cuts"]):
				fresh_pasta += Data.PASTA_YIELD
				mesa_pasta = null
				_hint("¡%d porciones de fettuccine fresco! Están en la heladera de la Cocina" % Data.PASTA_YIELD)
				_refresh_all()


func _pasta_discard() -> void:
	if mesa_pasta == null:
		return
	mesa_pasta = null
	money -= Data.WASTE_COST["chop"]
	_hint("Tiraste la masa: -$%d de la caja" % Data.WASTE_COST["chop"])
	_refresh_station()


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
	if info.get("flip", false):
		return "%s: %ds de cada lado en el comal (dala vuelta)" % [info["name"], int(round(info["target"] * Data.COOK_SLOW))]
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
	plate.drink = o.get("plate_drink", "") if o.get("plate_drink", "") != "Vino tinto" else ""   # la copa está en la Entrega
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
				if _ground_sauce(s):
					var left: int = salsa_stock.get(s, 0)
					b.text = "%s (%d)" % [s, left]
					if left <= 0:
						b.modulate.a = 0.45
					b.tooltip_text = "Salsa del molcajete: quedan %d porciones" % left
				b.pressed.connect(_on_condiment_click.bind("sauce", s))
		y += 30 + ceil(opts.size() / 4.0) * 92 + 4
	var tops := [] if prebuilt else _cat_options(r["cat"], "toppings")
	if prebuilt:
		_tag("Ya viene armada desde la otra estación", Vector2(x0, y), 15)
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
	_painter(Rect2(Vector2.ZERO, STATION_SIZE), draw_bg, true).fps = 12.0

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
		_painter(Rect2(990, 24, 274, 270), draw_res, true).fps = 12.0

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
	plate.drink = o.get("plate_drink", "") if o.get("plate_drink", "") != "Vino tinto" else ""   # la copa está al lado
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
		_build_wine_corner(o)

	var bell := _prop(Rect2(800, 330, 120, 126))
	tip_refs["campanita"] = bell
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
	if o.has("spices"):
		lines.append("Especias (en orden):")
		lines.append("  " + " > ".join(PackedStringArray(o["spices"])))
	if o.has("layers"):
		lines.append("Capas (de abajo arriba):")
		lines.append("  " + " / ".join(PackedStringArray(o["layers"])))
	else:
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
		var parts: Array = Data.RECIPES[r]["parts"].duplicate()
		parts.append(Data.RECIPES[r].get("uses", []))     # lo que se usa adentro (por ejemplo, el medallón de la hamburguesa)
		for part in parts:
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


# =====================================================================
# Servir vino en copa
# =====================================================================

## Botella de vino y copa sobre el mostrador de la Entrega
func _build_wine_corner(o) -> void:
	var bottle := _prop(Rect2(786, 120, 72, 182))
	bottle.draw_fn = func(ci, r): Art.draw_wine_bottle(ci, Vector2(r.get_center().x, r.position.y + 4), 1.1, 0.0)
	bottle.text = "Vino"
	bottle.text_size = 12
	bottle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	bottle.tooltip_text = "Mantené apretada la botella y volcala sobre la copa: llenala hasta la parte más ancha"
	bottle.held.connect(_start_pour)
	var oid: int = o["id"]
	wine_glass = _painter(Rect2(878, 156, 92, 146), func(ci, t):
		var oo = _get_order(oid)
		var fill: float = oo.get("wine_fill", 0.0) if oo != null else 0.0
		var spill: float = oo.get("wine_spill", 0.0) if oo != null else 0.0
		Art.draw_wine_glass(ci, Rect2(0, 0, 92, 146), fill, t, wine_slosh, spill), true)
	wine_glass.tooltip_text = "Copa de vino"
	if o.get("wine_fill", 0.0) > 0.0 or o.get("wine_spill", 0.0) > 0.0:
		var empty := _button("Vaciar copa", _empty_glass, 12)
		empty.position = Vector2(880, 124)
		station_box.add_child(empty)


func _empty_glass() -> void:
	var o: Variant = _get_order(selected_id)
	if o == null:
		return
	o["wine_fill"] = 0.0
	o["wine_spill"] = 0.0
	if o.get("plate_drink", "") == "Vino tinto":
		o["plate_drink"] = ""
	_refresh_all()


func _start_pour() -> void:
	if paused or wine_pouring:
		return
	var o: Variant = _get_order(selected_id)
	if o == null:
		return
	wine_pouring = true
	wine_tilt = 0.0
	wine_flow = 0.0
	var cursor := Painter.new()
	cursor.animate = true
	cursor.size = Vector2(1, 1)
	cursor.z_index = 100
	cursor.fn = func(ci, time): _draw_pour_cursor(ci, time)
	add_child(cursor)
	wine_cursor = cursor
	wine_cursor.position = get_global_mouse_position()


## ¿El pico de la botella está arriba de la boca de la copa?
func _over_glass() -> bool:
	if wine_glass == null or not is_instance_valid(wine_glass):
		return false
	var g := wine_glass.get_global_rect()
	var m := get_global_mouse_position()
	return m.x > g.position.x + g.size.x * 0.18 and m.x < g.end.x - g.size.x * 0.18 \
		and m.y > g.position.y - 110.0 and m.y < g.position.y + g.size.y * 0.25


## Altura (global) de la superficie del vino de la copa
func _wine_surface_y() -> float:
	var g := wine_glass.get_global_rect()
	var o: Variant = _get_order(selected_id)
	var fill: float = o.get("wine_fill", 0.0) if o != null else 0.0
	var top := g.position.y + g.size.y * 0.04
	return top + Art.wine_surface_u(fill) * g.size.y * 0.5


func _update_pour(delta: float) -> void:
	wine_slosh = move_toward(wine_slosh, 0.0, delta * 0.7)
	var want_sound := false
	if wine_pouring:
		var o: Variant = _get_order(selected_id)
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or o == null or current_station != 4:
			_end_pour()
		else:
			wine_cursor.position = get_global_mouse_position()
			var over := _over_glass()
			# Sobre la copa se va volcando de a poco (al principio no sale nada, después cae el chorro)
			wine_tilt = move_toward(wine_tilt, -2.05 if over else -0.5, delta * (2.2 if over else 4.0))
			wine_flow = clampf((-wine_tilt - 1.55) / 0.45, 0.0, 1.0) if over else 0.0
			if wine_flow > 0.0:
				_pour_into(o, delta, wine_flow)
				want_sound = true
	# Sonido del vino cayendo (glu-glu)
	if want_sound and sfx_on and wine_player == null:
		var st := _looped("res://assets/sfx/vino.wav")
		if st != null:
			wine_player = AudioStreamPlayer.new()
			wine_player.stream = st
			wine_player.volume_db = -30.0
			add_child(wine_player)
			wine_player.play()
	if wine_player != null:
		var target := -12.0 + linear_to_db(maxf(wine_flow, 0.05)) if want_sound else -45.0
		wine_player.volume_db = move_toward(wine_player.volume_db, target, 80.0 * delta)
		if not want_sound and wine_player.volume_db <= -44.0:
			wine_player.queue_free()
			wine_player = null


func _end_pour() -> void:
	wine_pouring = false
	wine_flow = 0.0
	if wine_cursor != null and is_instance_valid(wine_cursor):
		wine_cursor.queue_free()
	wine_cursor = null
	var o: Variant = _get_order(selected_id)
	if o != null and o.get("plate_drink", "") == "Vino tinto":
		var fill: float = o.get("wine_fill", 0.0)
		if o.get("wine_spill", 0.0) > 0.02:
			_hint("¡Se derramó! Vaciá la copa y servila de nuevo")
		elif fill < Data.WINE_OK.x:
			_hint("Le falta vino: llenala hasta la parte más ancha de la copa")
		elif fill > Data.WINE_OK.y:
			_hint("Está muy llena: el vino se sirve hasta la parte más ancha")
		else:
			_hint("¡Copa justa!")
	if current_station == 4:
		_refresh_station()


func _draw_pour_cursor(ci: CanvasItem, time: float) -> void:
	# El chorro: sale del pico con algo de impulso y cae curvándose hasta la superficie del vino
	if wine_flow > 0.0 and wine_glass != null and is_instance_valid(wine_glass):
		var mouth := Vector2.ZERO
		var hit := Vector2(wine_glass.get_global_rect().get_center().x, _wine_surface_y()) - wine_cursor.position
		var w := 1.5 + 3.0 * wine_flow
		var pts := PackedVector2Array()
		for k in 13:
			var t := k / 12.0
			# parábola: arranca hacia adelante (la botella está volcada) y cae
			var p := mouth.lerp(hit, t)
			p.x += sin(t * PI) * 6.0 * wine_flow + sin(time * 20.0 + t * 8.0) * 0.6
			pts.append(p)
		ci.draw_polyline(pts, Art.WINE.darkened(0.2), w + 1.0, true)
		ci.draw_polyline(pts, Art.WINE, w, true)
		var hl := PackedVector2Array()
		for p in pts:
			hl.append(p + Vector2(-w * 0.25, 0))
		ci.draw_polyline(hl, Color(1, 0.7, 0.75, 0.35), 1.0, true)
		# Ondas donde pega
		for k in 3:
			var ph := fmod(time * 3.0 + k / 3.0, 1.0)
			ci.draw_arc(hit, 3.0 + ph * 12.0, PI * 1.1, PI * 1.9, 10, Color(0.9, 0.4, 0.5, 0.5 * (1.0 - ph)), 1.2)
	Art.draw_wine_bottle(ci, Vector2.ZERO, 0.85, wine_tilt)
	if not _over_glass():
		Art.text(ci, Vector2(-100, 40), "Llevala arriba de la copa", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 200, 4)


## Cae vino en la copa del pedido o durante delta segundos con este caudal (0-1)
func _pour_into(o: Dictionary, delta: float, flow: float) -> void:
	var fill: float = o.get("wine_fill", 0.0)
	var hw := Art.glass_halfw(Art.wine_surface_u(fill))
	# Abajo el cáliz es angosto y sube rápido; cerca de la parte ancha, más despacio
	fill += Data.WINE_POUR * flow * delta / (0.45 + 0.55 * hw * hw)
	if fill >= Art.WINE_RIM_FILL:
		fill = Art.WINE_RIM_FILL
		o["wine_spill"] = minf(1.0, o.get("wine_spill", 0.0) + delta * flow * 0.8)
	o["wine_fill"] = fill
	o["plate_drink"] = "Vino tinto"
	wine_slosh = minf(1.0, wine_slosh + delta * 2.5 * flow)


# =====================================================================
# Perfiles: cada uno con su nombre, su cocinero y su propia partida
# =====================================================================

var profiles_path := "user://perfiles.cfg"   # las pruebas usan otro archivo
var profile_prefix := "user://progreso_"     # archivo de partida de cada perfil nuevo (las pruebas usan otro)
const MAX_PROFILES := 4
## Opciones del cocinero: [clave, título, [[nombre, valor], ...]]
const COOK_OPTIONS := [
	["tipo", "Perfil", [["Masculino", "m"], ["Femenino", "f"]]],
	["piel", "Piel", [["Muy clara", 0], ["Clara", 1], ["Trigueña", 2], ["Morena", 3], ["Oscura", 4], ["Muy oscura", 5]]],
	["pelo", "Pelo", [["Negro", 0], ["Castaño oscuro", 1], ["Castaño", 2], ["Rubio oscuro", 3], ["Rubio", 4],
		["Canoso", 5], ["Colorado", 6], ["Azabache", 7]]],
	["peinado", "Peinado", [["Corto", 0], ["Largo", 1], ["Rulos", 2], ["Rodete", 3], ["Pelado", 4], ["Punk", 6],
		["Melena", 8], ["Cola de caballo", 9], ["Trenza", 10]]],   # los nuevos van al final para no cambiar perfiles ya hechos
	["gorro", "Gorro", [["De chef", "toque"], ["Pañuelo", "bandana"], ["Gorra", "gorra"], ["Sin gorro", ""]]],
	["gorro_color", "Color del gorro", [["Blanco", Color("f4f1ea")], ["Rojo", Color("c8463c")], ["Azul", Color("3d6fb0")],
		["Verde", Color("3f8f5a")], ["Negro", Color("2b2b30")], ["Amarillo", Color("e6b83a")]]],
	["chaqueta", "Chaqueta", [["Blanca", Color("fbfbf8")], ["Negra", Color("2b2b30")], ["Gris", Color("6b737b")],
		["Azul", Color("2f4f7a")], ["Bordó", Color("7a1f2b")]]],
	["delantal", "Delantal", [["Crema", Color("f4efe2")], ["Bordó", Color("7a1426")], ["Verde", Color("2f5d50")],
		["Azul", Color("2f4f7a")], ["Negro", Color("2b2b30")], ["Sin delantal", null]]],
	["panuelo", "Pañuelo al cuello", [["Rojo", Color("d9534a")], ["Azul", Color("3d7ab8")], ["Verde", Color("4caf6a")],
		["Amarillo", Color("e6a33a")], ["Negro", Color("2b2b30")], ["Sin pañuelo", null]]],
	["detalle", "Detalle", [["Nada", 0], ["Anteojos", 1], ["Bigote", 2], ["Aros", 3], ["Pecas", 4]]],
	["cuerpo", "Contextura", [["Flaco", 0.9], ["Normal", 1.0], ["Grandote", 1.13]]],
]

var profiles: Array = []          # [{id, name, cook: {clave: índice}, file, nuevo?}]
var profile := {}                 # el perfil que está jugando
var edit_cook := {}               # el cocinero que se está armando en el editor
var edit_new := false
var edit_name_field: LineEdit = null
var edit_value_labels := {}
var delete_armed := ""            # id del perfil que se está por borrar (segundo toque)
var profile_title: Label = null       # título de la pantalla de perfil (se adapta a cocinero/cocinera)


func _default_cook() -> Dictionary:
	return {"piel": 1, "pelo": 1, "peinado": 0, "gorro": 0, "gorro_color": 0, "chaqueta": 0, "delantal": 1,
		"panuelo": 0, "detalle": 0, "cuerpo": 1}


func _random_cook() -> Dictionary:
	var c := {}
	for opt in COOK_OPTIONS:
		c[opt[0]] = rng.randi() % opt[2].size()
	return c


func _cook_value(cook: Dictionary, key: String) -> Variant:
	for opt in COOK_OPTIONS:
		if opt[0] == key:
			var idx: int = clampi(cook.get(key, 0), 0, opt[2].size() - 1)
			return opt[2][idx][1]
	return null


## Arma el "look" para dibujar al cocinero a partir de lo elegido
func _cook_look(cook: Dictionary) -> Dictionary:
	var hat: String = _cook_value(cook, "gorro")
	var apron = _cook_value(cook, "delantal")
	var look := {
		"skin": Art.SKINS[_cook_value(cook, "piel")],
		"hair": Art.HAIRS[_cook_value(cook, "pelo")],
		"style": _cook_value(cook, "peinado"),
		"shirt": _cook_value(cook, "chaqueta"),
		"cap": _cook_value(cook, "gorro_color"),
		"hat": hat,
		"acc": _cook_value(cook, "detalle"),
		"w": _cook_value(cook, "cuerpo"),
		"seed": 7,
		"jacket": true,
		"scarf": _cook_value(cook, "panuelo"),
		"apron": apron != null,
		"fem": _cook_value(cook, "tipo") == "f",
	}
	if apron != null:
		look["apron_color"] = apron
	return look


## El cocinero del perfil que está jugando (o el chef de siempre si no hay perfil)
func _player_look() -> Dictionary:
	if profile.is_empty():
		return Art.chef_look()
	return _cook_look(profile.get("cook", _default_cook()))


func _player_name() -> String:
	return profile.get("name", "") if not profile.is_empty() else ""


func _load_profiles() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(profiles_path) == OK:
		profiles = cfg.get_value("perfiles", "lista", [])
		var cur: String = cfg.get_value("perfiles", "actual", "")
		for p in profiles:
			if p["id"] == cur:
				profile = p
		if profile.is_empty() and not profiles.is_empty():
			profile = profiles[0]
	elif FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(OS.get_data_dir().path_join("Godot/app_userdata/Viandas/progreso.cfg")):
		# Ya había una partida de antes de los perfiles: pasa a ser el primer perfil (falta ponerle nombre y cocinero)
		profile = {"id": "p1", "name": "", "cook": _default_cook(), "file": SAVE_PATH, "nuevo": true}
		profiles = [profile]
		_save_profiles()
	if not profile.is_empty():
		save_path = profile["file"]


func _save_profiles() -> void:
	if save_path != SAVE_PATH and profile.is_empty() and profiles_path == "user://perfiles.cfg":
		return      # pruebas automáticas: no tocar los perfiles de verdad
	var cfg := ConfigFile.new()
	cfg.set_value("perfiles", "lista", profiles)
	cfg.set_value("perfiles", "actual", profile.get("id", ""))
	cfg.save(profiles_path)


## Vuelve todo al estado de una partida nueva (sin guardar)
func _reset_state() -> void:
	savings = 0
	tips_seen = []
	tips_done = false
	tips_on = true
	owned = []
	country_progress = {}
	owned_countries = ["argentina"]
	current_country = "argentina"
	_use_country(current_country)


func _switch_profile(p: Dictionary) -> void:
	if not profile.is_empty() and profile["id"] == p["id"]:
		return
	if not profile.is_empty():
		_save_progress()
	profile = p
	save_path = p["file"]
	_reset_state()
	_load_progress()
	_save_profiles()
	_update_music_button()
	if music != null:
		if music_on and not music.playing:
			music.play()
		elif not music_on:
			music.stop()


## Lo que dice la tarjeta de un perfil: ahorros y locales (se lee su archivo de partida)
func _profile_summary(p: Dictionary) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(p["file"]) != OK:
		return "Partida nueva"
	var sv: int = cfg.get_value("progreso", "ahorros", 0)
	var locs: Array = cfg.get_value("paises", "locales", ["argentina"])
	var days := 0
	var prog: Dictionary = cfg.get_value("paises", "progreso", {})
	for c in prog:
		days += prog[c].get("mejores", {}).size()
	return "Ahorros $%d\n%d %s · %d %s jugados" % [sv, locs.size(), "local" if locs.size() == 1 else "locales",
		days, "día" if days == 1 else "días"]


## "Jugar" del título: si todavía no hay cocinero, primero se arma
func _on_play() -> void:
	if profile.is_empty():
		_show_cook_editor(true)
	elif profile.get("nuevo", false):
		_show_cook_editor(false)
	else:
		_show_map()


## Fondo de las pantallas de perfil: la cocina con luz cálida
func _profile_bg(title: String) -> Control:
	_stop_everything()
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	overlay = bg
	var draw_bg := func(ci, _t):
		Art.draw_kitchen_wall(ci, Rect2(0, 0, 1280, 520))
		Art.draw_wood_counter(ci, Rect2(0, 520, 1280, 200))
		Art.draw_lighting(ci, Rect2(0, 0, 1280, 720))
	var p := _painter(Rect2(0, 0, 1280, 720), draw_bg, false, bg)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := _label(title, 34, Color.WHITE, 6)
	profile_title = t
	t.position = Vector2(0, 18)
	t.size = Vector2(1280, 50)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(t)
	return bg


# --- Editor del cocinero ---

func _show_cook_editor(is_new: bool) -> void:
	edit_new = is_new
	edit_cook = _random_cook() if is_new else profile.get("cook", _default_cook()).duplicate()
	if is_new:
		edit_cook["gorro"] = 0       # de entrada, con gorro de chef
	delete_armed = ""
	var bg := _profile_bg("")
	# Izquierda: el cocinero grande, con el nombre abajo
	var preview := func(ci, t):
		var look := _cook_look(edit_cook)
		Art.ellipse(ci, Vector2(330, 612), Vector2(150, 18), Color(0, 0, 0, 0.25))
		Art.draw_character(ci, look, Vector2(330, 610), 2.6, 0, t, false, sin(t * 2.0) * 1.5)
		var nm := ""
		if edit_name_field != null and is_instance_valid(edit_name_field):
			nm = edit_name_field.text.strip_edges()
		Art.rrect(ci, Rect2(170, 628, 320, 52), Color(0.12, 0.09, 0.07, 0.85), 12)
		Art.text(ci, Vector2(170, 664), nm if nm != "" else "¿Cómo te llamás?", 26,
			Color.WHITE if nm != "" else Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, 320)
	_painter(Rect2(0, 0, 1280, 720), preview, true, bg).fps = 30.0
	# Derecha: el nombre y las opciones
	var card := _paper_card(Vector2(600, 0))
	card.position = Vector2(640, 76)
	bg.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	col.add_child(name_row)
	var nl := _label("Nombre", 18, COL_INK)
	nl.custom_minimum_size = Vector2(170, 0)
	name_row.add_child(nl)
	edit_name_field = LineEdit.new()
	edit_name_field.text = "" if is_new else String(profile.get("name", ""))
	edit_name_field.placeholder_text = "Tu nombre"
	edit_name_field.max_length = 16
	edit_name_field.custom_minimum_size = Vector2(360, 42)
	edit_name_field.add_theme_font_size_override("font_size", 20)
	var le_sb := _sb(Color("fffdf5"), Color("c9a86a"), 8, 2)
	edit_name_field.add_theme_stylebox_override("normal", le_sb)
	edit_name_field.add_theme_stylebox_override("focus", _sb(Color("ffffff"), Color("d9a520"), 8, 3))
	edit_name_field.add_theme_color_override("font_color", COL_INK)
	edit_name_field.add_theme_color_override("caret_color", COL_INK)
	edit_name_field.add_theme_color_override("font_placeholder_color", Color(0.4, 0.33, 0.25, 0.6))
	name_row.add_child(edit_name_field)
	col.add_child(HSeparator.new())
	edit_value_labels = {}
	for opt in COOK_OPTIONS:
		var key: String = opt[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		col.add_child(row)
		var l := _label(opt[1], 16, COL_INK)
		l.custom_minimum_size = Vector2(170, 0)
		row.add_child(l)
		var prev := _button("<", _cook_step.bind(key, -1), 16)
		prev.custom_minimum_size = Vector2(46, 34)
		row.add_child(prev)
		var v := _label("", 17, COL_INK)
		v.custom_minimum_size = Vector2(200, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(v)
		edit_value_labels[key] = v
		var nxt := _button(">", _cook_step.bind(key, 1), 16)
		nxt.custom_minimum_size = Vector2(46, 34)
		row.add_child(nxt)
	_refresh_cook_labels()
	col.add_child(HSeparator.new())
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)
	btns.add_child(_button("Al azar", _cook_randomize, 16))
	var first_time: bool = (is_new and profiles.is_empty()) or (not is_new and profile.get("nuevo", false))
	if not first_time:
		btns.add_child(_button("Cancelar", _show_profiles, 16))
	var ok := _button("¡Listo, a cocinar!", _save_cook, 18)
	ok.custom_minimum_size = Vector2(230, 0)
	btns.add_child(ok)
	if not is_new and profile.get("nuevo", false):
		var note := _label("Tu partida de antes sigue intacta: ponele nombre y armá tu cocinero.", 14, Color.WHITE, 4)
		note.position = Vector2(660, 684)
		bg.add_child(note)


func _cook_step(key: String, d: int) -> void:
	for opt in COOK_OPTIONS:
		if opt[0] == key:
			var n: int = opt[2].size()
			edit_cook[key] = (int(edit_cook.get(key, 0)) + d + n) % n
	_refresh_cook_labels()


func _cook_randomize() -> void:
	edit_cook = _random_cook()
	_refresh_cook_labels()


func _refresh_cook_labels() -> void:
	if profile_title != null and is_instance_valid(profile_title):
		var fem: bool = _cook_value(edit_cook, "tipo") == "f"
		if edit_new and not profiles.is_empty():
			profile_title.text = "Nueva cocinera" if fem else "Nuevo cocinero"
		else:
			profile_title.text = "Tu cocinera" if fem else "Tu cocinero"
	for opt in COOK_OPTIONS:
		var key: String = opt[0]
		if edit_value_labels.has(key) and is_instance_valid(edit_value_labels[key]):
			var idx: int = clampi(edit_cook.get(key, 0), 0, opt[2].size() - 1)
			var txt: String = opt[2][idx][0]
			# El color del gorro no se usa con el gorro de chef (siempre es blanco) ni sin gorro
			if key == "gorro_color" and String(_cook_value(edit_cook, "gorro")) in ["toque", ""]:
				txt = "-"
			edit_value_labels[key].text = txt


func _save_cook() -> void:
	var nm := ""
	if edit_name_field != null and is_instance_valid(edit_name_field):
		nm = edit_name_field.text.strip_edges()
	if nm == "":
		_toast_name_needed()
		return
	if edit_new:
		if not profile.is_empty():
			_save_progress()
		var n := 1
		var ids: Array = profiles.map(func(pr): return pr["id"])
		while ("p%d" % n) in ids:
			n += 1
		var id := "p%d" % n
		var p := {"id": id, "name": nm, "cook": edit_cook.duplicate(), "file": profile_prefix + id + ".cfg"}
		profiles.append(p)
		profile = p
		save_path = p["file"]
		_reset_state()
		_save_progress()
	else:
		profile["name"] = nm
		profile["cook"] = edit_cook.duplicate()
		profile.erase("nuevo")
	_save_profiles()
	_show_map()


func _toast_name_needed() -> void:
	if edit_name_field != null and is_instance_valid(edit_name_field):
		edit_name_field.placeholder_text = "¡Poné tu nombre!"
		edit_name_field.grab_focus()


# --- Elegir perfil ---

func _show_profiles() -> void:
	var bg := _profile_bg("¿Quién cocina hoy?")
	var n := profiles.size()
	var cw := 260.0
	var cards := n + (1 if n < MAX_PROFILES else 0)
	var total := cw * cards + 24.0 * maxi(cards - 1, 0)
	var x := 640.0 - total / 2.0
	for p in profiles:
		var pp: Dictionary = p
		var cur: bool = pp["id"] == profile.get("id", "")
		var look := _cook_look(pp.get("cook", _default_cook()))
		var nm: String = pp["name"] if pp["name"] != "" else "Sin nombre"
		var summary := _profile_summary(pp)
		var cx := x
		var draw_card := func(ci, t):
			Art.rrect(ci, Rect2(cx + 4, 108, cw, 470), Color(0, 0, 0, 0.3), 14)
			Art.rrect(ci, Rect2(cx, 104, cw, 470), COL_PAPER, 14, Color("e0b44a") if cur else Color("c9a86a"), 4 if cur else 2)
			Art.draw_character(ci, look, Vector2(cx + cw / 2.0, 352), 1.22, 0, t)
			Art.rrect(ci, Rect2(cx, 380, cw, 120), COL_PAPER, 10)
			Art.text(ci, Vector2(cx, 418), nm, 26, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, cw)
			var lines := summary.split("\n")
			for k in lines.size():
				Art.text(ci, Vector2(cx, 450 + k * 22), lines[k], 15, Color(0.35, 0.28, 0.2), HORIZONTAL_ALIGNMENT_CENTER, cw)
			if cur:
				Art.rrect(ci, Rect2(cx + cw / 2.0 - 70, 92, 140, 24), Color("e0b44a"), 12)
				Art.text(ci, Vector2(cx, 109), "ÚLTIMO EN JUGAR", 12, Color("4a3410"), HORIZONTAL_ALIGNMENT_CENTER, cw)
		_painter(Rect2(0, 0, 1280, 720), draw_card, true, bg).fps = 20.0
		var play := _button("Jugar", _pick_profile.bind(pp, "jugar"), 18)
		play.position = Vector2(cx + 20, 506)
		play.custom_minimum_size = Vector2(cw - 40, 0)
		bg.add_child(play)
		var edit := _button("Editar", _pick_profile.bind(pp, "editar"), 14)
		edit.position = Vector2(cx, 590)
		bg.add_child(edit)
		var armed: bool = delete_armed == pp["id"]
		var del := _button("¿Seguro? Tocá otra vez" if armed else "Borrar", _delete_profile.bind(pp), 14)
		del.position = Vector2(cx + cw - (180.0 if armed else 76.0), 590)
		if armed:
			del.add_theme_color_override("font_color", Color("c0281a"))
		bg.add_child(del)
		x += cw + 24.0
	if n < MAX_PROFILES:
		var nx := x
		var draw_new := func(ci, _t):
			Art.rrect(ci, Rect2(nx, 104, cw, 470), Color(1, 1, 1, 0.12), 14, Color(1, 1, 1, 0.6), 3)
			Art.text(ci, Vector2(nx, 330), "+", 90, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, cw)
			Art.text(ci, Vector2(nx, 400), "Nuevo perfil", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, cw, 4)
		_painter(Rect2(0, 0, 1280, 720), draw_new, false, bg)
		var add := _button("Crear", _show_cook_editor.bind(true), 18)
		add.position = Vector2(nx + 20, 506)
		add.custom_minimum_size = Vector2(cw - 40, 0)
		bg.add_child(add)
	var back := _button("Volver", _show_title, 16)
	back.position = Vector2(20, 660)
	bg.add_child(back)
	var note := _label("Cada perfil tiene su propia partida, guardada en este dispositivo.", 15, Color.WHITE, 4)
	note.position = Vector2(0, 664)
	note.size = Vector2(1280, 30)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(note)


func _pick_profile(p: Dictionary, action: String) -> void:
	_switch_profile(p)
	delete_armed = ""
	if action == "editar" or p.get("nuevo", false) or String(p.get("name", "")) == "":
		_show_cook_editor(false)
	else:
		_show_map()


func _delete_profile(p: Dictionary) -> void:
	if delete_armed != p["id"]:
		delete_armed = p["id"]       # primer toque: pide confirmación
		_show_profiles()
		return
	delete_armed = ""
	profiles.erase(p)
	if FileAccess.file_exists(p["file"]):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p["file"]))
	if profile.get("id", "") == p["id"]:
		profile = {}
		_reset_state()
		if not profiles.is_empty():
			_switch_profile(profiles[0])
		else:
			save_path = SAVE_PATH
	_save_profiles()
	_show_profiles()



# =====================================================================
# Consejos para el que juega por primera vez: aparecen solos en el momento justo, una sola vez,
# con una flecha a lo que hay que usar. Se van al hacerlo (o con "Entendido") y se apagan desde la pausa.
# =====================================================================

func _toggle_tips() -> void:
	tips_on = not tips_on
	if not tips_on:
		_hide_tip(false)
	_save_progress()
	if paused:
		_resume()
		_toggle_pause()


func _seen(id: String) -> bool:
	return id in tips_seen


func _tab(i: int) -> Control:
	return tab_buttons[i] if i < tab_buttons.size() else null


## El consejo que corresponde ahora: [id, texto, a qué señala] (o vacío si no hay ninguno)
func _next_tip() -> Array:
	var o: Variant = _get_order(selected_id)
	var cooking := false
	for a in cookers:
		for s in cookers[a]:
			if s != null:
				cooking = true
	# El cliente impaciente le gana a todo: es lo más urgente de entender
	if not _seen("paciencia"):
		for c in queue + orders:
			if _mood(elapsed - c["arrived"]) >= 2:
				var lbl = ticket_labels.get(c.get("id", -1))
				return ["paciencia", "Este cliente se está impacientando: cuanto más espera, menos puntos te da. Si espera demasiado, se va sin comer.",
					lbl if lbl != null and is_instance_valid(lbl) else _tab(0)]
	if close_button != null and close_button.visible:
		return ["cierre", "¡Atendiste a todos! Lavá lo que quedó sucio y después tocá acá para cerrar el día.", close_button]
	match current_station:
		0:
			if not queue.is_empty() and orders.is_empty() and served == 0 and take_button != null and is_instance_valid(take_button):
				return ["tomar", "Llegó tu primer cliente. Tocá acá para tomarle el pedido.", take_button]
			if not orders.is_empty() and not cooking and prepared.is_empty() and served == 0:
				if _prep() != "" and not _seen("prep_" + _prep()):
					return ["prep_" + _prep(), "Esta cocina tiene su estación propia: %s (tecla 3). Ahí se prepara lo típico del país." % _prep_name(), _tab(2)]
				return ["ir_cocina", "El pedido quedó anotado en el ticket de arriba. Andá a la Cocina (tecla 2) a prepararlo.", _tab(1)]
		1:
			for a in cookers:
				for i in cookers[a].size():
					var s = cookers[a][i]
					if s == null:
						continue
					var info: Dictionary = Data.ITEMS[s["item"]]
					var view := _appliance_view(a)
					if info.get("salt", false) and float(s.get("salt", 0.0)) < Data.SALT_OK.x and tip_refs.has("salero") and not _seen("sal"):
						return ["sal", "¡Esto lleva sal! Mantené apretado el salero y sacudilo encima de la comida hasta que la S se ponga verde.", tip_refs["salero"]]
					if info.has("temps") and view != null and _seen("sal") and not _seen("termometro"):
						return ["termometro", "Las carnes se sacan por temperatura: mirá el termómetro clavado en la carne y la receta de abajo.", view]
					if s.get("flip", false) and view != null and not _seen("dar_vuelta"):
						return ["dar_vuelta", "Se cocina el lado de abajo: tocala para darla vuelta cuando el cartel dice que la des vuelta.", view]
					if a == "wok" and view != null and not _seen("saltear"):
						return ["saltear", "Tocá el wok seguido para saltear: si lo dejás quieto, la comida se pega y se quema.", view]
					if view != null and not _seen("sacar") and _doneness_progress(s) >= s["target"] - Data.ZONE * 0.5 and float(s["t"]) < float(s["burn"]):
						return ["sacar", "¡Está en su punto! Tocá el cartelito para sacarlo a la bandeja antes de que se pase.", view]
			if not cooking and prepared.is_empty() and o != null and tip_refs.has("heladera"):
				return ["heladera", "Arrastrá el ingrediente desde la heladera hasta el aparato que corresponde. Abajo tenés la receta del pedido.", tip_refs["heladera"]]
		3:
			if o != null and plating_plate != null and is_instance_valid(plating_plate):
				if o["plate"].is_empty() and not prepared.is_empty():
					return ["al_plato", "Arrastrá lo de la bandeja (a la izquierda) hasta el plato. La salsa también se arrastra.", plating_plate]
				var tops: Array = o["toppings"]
				if not o["plate"].is_empty() and not tops.is_empty() and not Data.RECIPES[o["recipe"]].get("prebuilt", false) \
						and o["plate_toppings"].size() < tops.size():
					return ["toppings", "Para los toppings: mantené apretado el bowl y pasalo por arriba de la comida un par de segundos.", plating_plate]
		4:
			if o != null and not o["plate"].is_empty() and tip_refs.has("campanita"):
				return ["campanita", "Cuando el plato está completo, tocá la campanita para servirlo.", tip_refs["campanita"]]
		5:
			if sink_item == null and not dirty.is_empty() and sink_view != null and is_instance_valid(sink_view):
				return ["pileta", "Arrastrá lo sucio de la izquierda hasta la pileta (o tocalo).", sink_view]
			if sink_item != null:
				if not water_on and tip_refs.has("grifo") and not _seen("grifo"):
					return ["grifo", "Abrí el grifo para lavar y enjuagar.", tip_refs["grifo"]]
				if sponge_soap <= 0.0 and float(sink_item["dirt"]) > 0.0 and not sink_item.get("soaped", false) and tip_refs.has("detergente") and not _seen("detergente"):
					return ["detergente", "Tocá el detergente para cargar la esponja: con una carga alcanza para una pieza entera.", tip_refs["detergente"]]
				if float(sink_item["dirt"]) > 0.0 and tip_refs.has("esponja") and not _seen("frotar"):
					return ["frotar", "Mantené apretada la esponja y frotá las manchas hasta que desaparezcan.", tip_refs["esponja"]]
				if float(sink_item["dirt"]) <= 0.0 and sink_item["bubbles"].is_empty() and rack_view != null and is_instance_valid(rack_view):
					return ["escurridor", "¡Limpio! Arrastralo al escurridor de la derecha.", rack_view]
	# Avisos que llevan a otra estación
	if o != null and not prepared.is_empty() and o["plate"].is_empty() and current_station in [0, 1, 2] and not _seen("ir_emplatado"):
		return ["ir_emplatado", "Lo cocinado quedó en la bandeja. Armá el plato en Emplatado (tecla 4).", _tab(3)]
	if o != null and o["plate"].size() >= o["items"].size() and current_station in [0, 1, 2, 5] and not _seen("ir_entrega"):
		return ["ir_entrega", "El plato está listo: servilo en la Entrega (tecla 5).", _tab(4)]
	if not dirty.is_empty() and current_station in [0, 1, 4] and not _seen("ir_bacha"):
		return ["ir_bacha", "Quedó algo sucio. Si no lavás, te quedás sin platos limpios: lavá en la Bacha (tecla 6) cuando tengas un rato.", _tab(5)]
	return []


func _appliance_view(a: String) -> Control:
	for v in kitchen_views:
		if is_instance_valid(v) and v.kind == a:
			return v
	return null


func _update_tips(delta: float) -> void:
	if not tips_on or tips_done or intro_t >= 0.0:
		return
	if tip_view != null:
		tip_age += delta
		_place_tip()
	tip_check -= delta
	if tip_check > 0.0:
		return
	tip_check = 0.25
	var want := _next_tip()
	if not want.is_empty() and _seen(want[0]):
		want = []
	if want.is_empty() or want[2] == null or not is_instance_valid(want[2]):
		if tip_view != null:
			_hide_tip(true)     # se resolvió (o se fue a otra cosa): ya lo vio
		return
	if want[0] != tip_id:
		if tip_view != null:
			_hide_tip(true)
		_show_tip(want[0], want[1], want[2])
	else:
		tip_view.set_meta("target", want[2])


func _show_tip(id: String, text: String, target: Control) -> void:
	tip_id = id
	tip_age = 0.0
	var v := Control.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.z_index = 45
	v.set_meta("target", target)
	add_child(v)
	tip_view = v
	# Anillo que late alrededor de lo que hay que usar, y la flecha
	var ring := Painter.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.animate = true
	ring.fps = 30.0
	ring.fn = func(ci, t):
		var tg = v.get_meta("target")
		var bubble: Control = v.get_node_or_null("Globo")
		if tg == null or not is_instance_valid(tg) or bubble == null:
			return
		var r: Rect2 = tg.get_global_rect()
		var pulse := 0.5 + 0.5 * sin(t * 6.0)
		Art.rrect(ci, r.grow(6 + pulse * 4), Color(0, 0, 0, 0), 12, Color(1, 0.82, 0.25, 0.55 + 0.45 * pulse), 4)
		var b := bubble.get_global_rect()
		var above := b.end.y < r.position.y
		var from := Vector2(clampf(r.get_center().x, b.position.x + 20, b.end.x - 20), b.end.y if above else b.position.y)
		var to := Vector2(r.get_center().x, r.position.y - 8 if above else r.end.y + 8)
		if from.distance_to(to) > 12.0:
			ci.draw_line(from, to, Color("ffd166"), 4)
			var dir := (to - from).normalized()
			ci.draw_colored_polygon(PackedVector2Array([to, to - dir * 16 + dir.orthogonal() * 9, to - dir * 16 - dir.orthogonal() * 9]), Color("ffd166"))
	v.add_child(ring)
	var panel := PanelContainer.new()
	panel.name = "Globo"
	panel.add_theme_stylebox_override("panel", _sb(Color("fff6dc"), Color("e0a82e"), 12, 3))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	v.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var l := _label(text, 16, COL_INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(320, 0)
	row.add_child(l)
	var ok := _button("Entendido", _hide_tip.bind(true), 13)
	ok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ok)
	_place_tip()


## El globo va arriba o abajo de lo que señala, sin taparlo y sin salirse de la pantalla
func _place_tip() -> void:
	if tip_view == null:
		return
	var tg = tip_view.get_meta("target")
	var panel: Control = tip_view.get_node_or_null("Globo")
	if tg == null or not is_instance_valid(tg) or panel == null:
		return
	var r: Rect2 = tg.get_global_rect()
	var sz := panel.get_combined_minimum_size()
	var vs := get_viewport_rect().size
	var y := r.position.y - sz.y - 30.0
	if y < 50.0:
		y = minf(r.end.y + 30.0, vs.y - sz.y - 8.0)
	panel.position = Vector2(clampf(r.get_center().x - sz.x / 2.0, 8.0, vs.x - sz.x - 8.0), y)


func _hide_tip(mark_seen := true) -> void:
	if tip_view != null and is_instance_valid(tip_view):
		tip_view.queue_free()
	if mark_seen and tip_id != "" and not tip_id in tips_seen:
		tips_seen.append(tip_id)
	tip_view = null
	tip_id = ""
