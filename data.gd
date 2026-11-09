extends RefCounted
## Datos del juego: aparatos, ingredientes, recetas y niveles.
## Para agregar contenido nuevo alcanza con editar este archivo.

const PASS_SCORE := 60.0   # promedio mínimo para desbloquear el día siguiente
const ZONE := 1.0          # margen alrededor del punto ideal de cocción (en unidades de cocción)
const COOK_PENALTY := 14.0  # puntos que se pierden por cada unidad fuera del margen

# Lo que se pierde de la caja al tirar comida a la basura
const WASTE_COST := {"cook": 3, "chop": 1, "ready": 2, "condiment": 1, "assembled": 4}

const LEAVE_FACTOR := 2.3      # si esperan más que paciencia x esto, se van y abandonan el pedido
const COOK_SLOW := 1.35       # ritmo de cocción: todo se cocina un 35% más lento que los tiempos de las recetas
const SPRINKLE_TIME := 2.0   # segundos que hay que desparramar un topping sobre la comida

# Lavado: los utensilios se ensucian con el uso (uses = cuántas veces se usan antes de ir a lavar;
# el plato, una sola). Hay un stock limpio por día.
# Si se acaba, se usa uno sucio (la comida o el plato bajan de nota).
const TOOLS := {
	"plato": {"name": "Plato", "stock": 6, "uses": 1},
	"olla": {"name": "Olla", "stock": 4, "uses": 2},
	"espatula": {"name": "Espátula", "stock": 3, "uses": 3},
	"canasto": {"name": "Canasto", "stock": 3, "uses": 3},
	"bandeja": {"name": "Bandeja", "stock": 3, "uses": 2},
	"pala": {"name": "Pala", "stock": 2, "uses": 3},
	"tabla": {"name": "Tabla", "stock": 4, "uses": 3},
}
# Heladera de la cocina: los ingredientes van agrupados por tipo
const FRIDGE_GROUPS := [
	["Carnes", ["milanesa", "bife", "pollo", "hamburguesa", "carne_asada", "pastor"]],
	["Pastas, arroz y granos", ["spaghetti", "noquis", "ravioles", "fettuccine", "arroz", "frijoles"]],
	["Verduras", ["papas_fritas", "calabaza", "berenjena", "morron", "aros_cebolla", "champinones"]],
	["Dulces", ["panqueque", "churros", "malteada_choco", "malteada_frutilla", "malteada_vainilla", "croissant"]],
]
const TOOL_ORDER := ["plato", "olla", "espatula", "canasto", "bandeja", "pala", "tabla"]
const TOOL_FOR := {"olla": "olla", "plancha": "espatula", "freidora": "canasto", "horno": "bandeja", "horno_lena": "pala"}   # el comal se maneja con la mano: no ensucia utensilios
const DIRTY_FOOD := 0.8       # cocinar con un utensilio sucio: la comida vale 80%
const DIRTY_PLATE := 0.75     # servir en plato sucio: el plato vale 75%
const DIRTY_REPUTATION := 2.5 # al cerrar, cada cosa sin lavar baja la reputación del día (máximo 30)
const CLEANUP_TIME := 30.0  # al irse el último cliente, segundos para terminar de lavar antes de cerrar

# Salero: lo que va en la plancha o la olla (con "salt": true) se sala sacudiendo el salero encima.
# 1.0 = bien salado (≈1 segundo de sacudir). Entre SALT_OK.x y SALT_OK.y está perfecto.
const SALT_TIME := 1.0
const SALT_OK := Vector2(0.8, 2.2)

# Guía gastronómica: cada local puede ganar hasta 3 estrellas. Las da un crítico que viene de incógnito
# (sombrero, anteojos oscuros y libreta) en los días avanzados del local. Para ganar la estrella su plato
# tiene que llegar a CRITIC_NEEDS[estrellas que ya tiene] y el día tiene que aprobarse.
const GUIDE_NAME := "Guía del Buen Comer"
const CRITIC_NEEDS := [78.0, 85.0, 91.0]
const STAR_TIP := 2           # cada estrella del local suma $2 de propina por cliente


## Desde qué día (índice) puede venir el crítico a dar la estrella número stars+1
static func critic_min_day(n_days: int, stars: int) -> int:
	var days := [1, n_days / 2, n_days - 1]
	return clampi(days[clampi(stars, 0, 2)], 1, maxi(n_days - 1, 1))


## Cuánto afecta la sal a la calidad de algo cocinado (1 = perfecto)
static func salt_factor(id: String, salt: float) -> float:
	if ITEMS[id].get("salt", false):
		if salt < SALT_OK.x:
			return 0.55 + 0.45 * salt / SALT_OK.x     # le falta sal
		if salt > SALT_OK.y:
			return maxf(0.3, 1.0 - (salt - SALT_OK.y) * 0.5)   # muy salado
		return 1.0
	return 0.5 if salt > 0.3 else 1.0   # no llevaba sal (por ejemplo, el panqueque)

# Mejoras que se compran en la tienda con los ahorros. "for": clientes o cocina.
const UPGRADES := {
	"plantas": {"name": "Plantas colgantes", "price": 60, "for": "Clientes",
		"desc": "El salón se ve más lindo: los clientes tienen 15% más paciencia."},
	"ventilador": {"name": "Ventilador de techo", "price": 100, "for": "Clientes",
		"desc": "Salón fresquito: los clientes tienen 25% más paciencia."},
	"caramelera": {"name": "Caramelera", "price": 40, "for": "Clientes",
		"desc": "Caramelos en el mostrador: +$1 de propina por cliente."},
	"vajilla": {"name": "Vajilla con borde dorado", "price": 90, "for": "Clientes",
		"desc": "Los platos lucen mejor: +$3 de propina por cliente."},
	"timbre": {"name": "Timbre de cocina", "price": 70, "for": "Cocina",
		"desc": "Suena una campanita cuando algo llega a su punto."},
	"reloj": {"name": "Reloj con marcas", "price": 120, "for": "Cocina",
		"desc": "Las barras y el termómetro marcan el punto también en los días difíciles."},
	"hornalla": {"name": "Cuarta hornalla", "price": 110, "for": "Cocina",
		"desc": "Una olla más: podés hervir 4 cosas a la vez."},
	"procesadora": {"name": "Procesadora", "price": 80, "for": "Cocina",
		"desc": "Las verduras se cortan con la mitad de cortes."},
	"lavavajillas": {"name": "Lavavajillas", "price": 150, "for": "Cocina",
		"desc": "Lava solo una cosa sucia cada 8 segundos (más lento que a mano)."},
	"ayudante": {"name": "Ayudante de cocina", "price": 260, "for": "Cocina",
		"desc": "Saca la comida del fuego justo en su punto: nunca más se quema nada."},
}
const UPGRADE_ORDER := ["caramelera", "plantas", "vajilla", "ventilador", "timbre", "procesadora", "hornalla", "lavavajillas", "reloj", "ayudante"]


## Temperatura interna (°C) de una carne después de t segundos de cocción.
static func temp_at(id: String, t: float) -> float:
	var pts: Array = ITEMS[id].get("temps", [])
	if pts.is_empty():
		return 0.0
	for k in pts.size() - 1:
		var a: Array = pts[k]
		var b: Array = pts[k + 1]
		if t <= b[0]:
			return lerpf(a[1], b[1], (t - a[0]) / float(b[0] - a[0]))
	return float(pts[-1][1]) + (t - float(pts[-1][0])) * 2.0

# Aparatos de cocción: nombre visible y cantidad de lugares.
const APPLIANCES := {
	"olla": {"name": "Olla", "slots": 3},
	"plancha": {"name": "Plancha", "slots": 4},
	"freidora": {"name": "Freidora", "slots": 4},
	"horno": {"name": "Horno", "slots": 3},
	"horno_lena": {"name": "Horno de leña", "slots": 3},   # Italia: la pizza se gira con la pala
	"comal": {"name": "Comal", "slots": 4},             # México: las tortillas se dan vuelta a mano
	"licuadora": {"name": "Licuadora", "slots": 2},        # EE.UU.: malteadas (si se pasa, queda aguada)
	"crepera": {"name": "Crepera", "slots": 2},          # Francia: la crêpe se da vuelta a mano
}
const APPLIANCE_ORDER := ["comal", "crepera", "olla", "plancha", "freidora", "horno", "horno_lena", "licuadora"]

# kind: "cook" se cocina en un aparato (target = segundos ideales, burn = se quema)
#       "chop" se corta en la tabla (cuts = cantidad de cortes)
#       "ready" se saca de la despensa y va directo al plato
# doneness: puntos de cocción que puede pedir el cliente (reemplaza a target)
const ITEMS := {
	"spaghetti": {"name": "Spaghetti", "kind": "cook", "where": "olla", "salt": true, "target": 9.0, "burn": 16.0},
	"noquis": {"name": "Ñoquis", "kind": "cook", "where": "olla", "salt": true, "target": 5.0, "burn": 10.0},
	"ravioles": {"name": "Ravioles", "kind": "cook", "where": "olla", "salt": true, "target": 7.0, "burn": 13.0},
	"arroz": {"name": "Arroz", "kind": "cook", "where": "olla", "salt": true, "target": 12.0, "burn": 20.0},
	# Las carnes llevan termómetro: "temps" = curva [segundos, °C] y la temperatura de cada punto
	"milanesa": {"name": "Milanesa", "kind": "cook", "where": "freidora", "target": 8.0, "burn": 14.0,
		"temps": [[0, 5], [8, 72], [14, 95]], "target_temp": 72},
	"bife": {"name": "Bife", "kind": "cook", "where": "plancha", "salt": true, "target": 9.0, "burn": 16.0,
		"doneness": {"Jugoso": 6.0, "A punto": 9.0, "Bien cocido": 12.0},
		"temps": [[0, 5], [6, 52], [9, 60], [12, 71], [16, 90]],
		"doneness_temp": {"Jugoso": 52, "A punto": 60, "Bien cocido": 71}},
	"pollo": {"name": "Pollo", "kind": "cook", "where": "plancha", "salt": true, "target": 11.0, "burn": 17.0,
		"temps": [[0, 5], [11, 74], [17, 95]], "target_temp": 74},
	"hamburguesa": {"name": "Hamburguesa", "kind": "cook", "where": "plancha", "salt": true, "target": 7.0, "burn": 14.0,
		"doneness": {"A punto": 7.0, "Bien cocida": 10.0},
		"temps": [[0, 5], [7, 63], [10, 71], [14, 90]],
		"doneness_temp": {"A punto": 63, "Bien cocida": 71}},
	"panqueque": {"name": "Panqueque", "kind": "cook", "where": "plancha", "target": 4.0, "burn": 8.0},
	"papas_fritas": {"name": "Papas fritas", "kind": "cook", "where": "freidora", "target": 7.0, "burn": 12.0},
	"calabaza": {"name": "Calabaza", "kind": "cook", "where": "horno", "target": 12.0, "burn": 20.0},
	"berenjena": {"name": "Berenjena", "kind": "cook", "where": "horno", "target": 9.0, "burn": 16.0},
	"morron": {"name": "Morrón", "kind": "cook", "where": "horno", "target": 8.0, "burn": 14.0},
	"lechuga": {"name": "Lechuga", "kind": "chop", "cuts": 4},
	"tomate": {"name": "Tomate", "kind": "chop", "cuts": 5},
	"zanahoria": {"name": "Zanahoria", "kind": "chop", "cuts": 6},
	"cebolla": {"name": "Cebolla", "kind": "chop", "cuts": 5},
	"pure": {"name": "Puré", "kind": "ready"},
	"flan": {"name": "Flan", "kind": "ready"},
	# Italia. "built": se arma en la mesa de pizza (no sale de la heladera)
	"pizza": {"name": "Pizza", "kind": "cook", "where": "horno_lena", "target": 9.0, "burn": 15.0, "built": true},
	"fettuccine": {"name": "Fettuccine", "kind": "cook", "where": "olla", "salt": true, "target": 5.0, "burn": 10.0, "fresh": true},
	"tiramisu": {"name": "Tiramisú", "kind": "ready"},
	# México. La tortilla se aplana en la prensa ("built") y en el comal se cocina de los dos lados ("flip")
	"tortilla": {"name": "Tortilla", "kind": "cook", "where": "comal", "target": 3.0, "burn": 6.5, "built": true, "flip": true},
	"carne_asada": {"name": "Carne asada", "kind": "cook", "where": "plancha", "salt": true, "target": 8.0, "burn": 14.0,
		"temps": [[0, 5], [8, 68], [14, 92]], "target_temp": 68},
	"pastor": {"name": "Al pastor", "kind": "cook", "where": "plancha", "salt": true, "target": 7.0, "burn": 13.0},
	"frijoles": {"name": "Frijoles", "kind": "cook", "where": "olla", "salt": true, "target": 10.0, "burn": 18.0},
	"churros": {"name": "Churros", "kind": "cook", "where": "freidora", "target": 6.0, "burn": 11.0},
	"queso": {"name": "Queso Oaxaca", "kind": "ready"},
	# Estados Unidos. "assembled": se arma por capas en el Armado con un medallón ("patty") de la plancha
	"burger": {"name": "Burger", "kind": "assembled", "patty": "hamburguesa", "target": 7.0, "burn": 14.0,
		"doneness": {"A punto": 7.0, "Bien cocida": 10.0}},
	"aros_cebolla": {"name": "Aros de cebolla", "kind": "cook", "where": "freidora", "target": 5.0, "burn": 10.0},
	"malteada_choco": {"name": "Malteada de chocolate", "kind": "cook", "where": "licuadora", "target": 5.0, "burn": 10.0},
	"malteada_frutilla": {"name": "Malteada de frutilla", "kind": "cook", "where": "licuadora", "target": 5.0, "burn": 10.0},
	"malteada_vainilla": {"name": "Malteada de vainilla", "kind": "cook", "where": "licuadora", "target": 5.0, "burn": 10.0},
	# Francia. La crêpe se esparce en la Crêperie ("built") y en la crepera se da vuelta ("flip").
	# El éclair se decora con la manga ("piped"): vale según cuánto se siguió la guía.
	"crepe": {"name": "Crêpe", "kind": "cook", "where": "crepera", "target": 3.0, "burn": 6.0, "built": true, "flip": true},
	"champinones": {"name": "Champiñones", "kind": "cook", "where": "plancha", "salt": true, "target": 6.0, "burn": 11.0},
	"jamon": {"name": "Jamón", "kind": "ready"},
	"croissant": {"name": "Croissant", "kind": "cook", "where": "horno", "target": 9.0, "burn": 15.0},
	"eclair": {"name": "Éclair", "kind": "assembled"},
}

# parts: cada parte es una lista de opciones; el cliente elige una por parte.
# sauces: el cliente elige una ("Sin salsa" es una opción válida). Vacío = el plato no lleva salsa.
# toppings: el cliente elige algunos (cuántos depende del nivel y de min_toppings).
const RECIPES := {
	"spaghetti": {"name": "Spaghetti", "cat": "Pastas", "parts": [["spaghetti"]],
		"sauces": ["Fileto", "Bolognesa", "Crema", "Pesto"], "toppings": ["Queso rallado", "Albahaca"]},
	"noquis": {"name": "Ñoquis", "cat": "Pastas", "parts": [["noquis"]],
		"sauces": ["Fileto", "Bolognesa", "Cuatro quesos"], "toppings": ["Queso rallado"]},
	"ravioles": {"name": "Ravioles", "cat": "Pastas", "parts": [["ravioles"]],
		"sauces": ["Fileto", "Crema", "Mixta"], "toppings": ["Queso rallado", "Perejil"]},
	"milanesa": {"name": "Milanesa con fritas", "cat": "Carnes", "parts": [["milanesa"], ["papas_fritas"]],
		"sauces": [], "toppings": ["Limón", "Huevo frito"]},
	"bife": {"name": "Bife con guarnición", "cat": "Carnes", "parts": [["bife"], ["papas_fritas", "pure", "calabaza"]],
		"sauces": ["Chimichurri", "Criolla", "Sin salsa"], "toppings": []},
	"pollo": {"name": "Pollo grillado", "cat": "Carnes", "parts": [["pollo"], ["pure", "arroz", "calabaza"]],
		"sauces": ["Limón y hierbas", "Sin salsa"], "toppings": []},
	"hamburguesa": {"name": "Hamburguesa", "cat": "Carnes",
		"parts": [["hamburguesa"], ["lechuga", "tomate"], ["papas_fritas"]],
		"sauces": ["Ketchup", "Mayonesa", "Mostaza"], "toppings": ["Cheddar", "Panceta", "Pepinos"]},
	"ensalada": {"name": "Ensalada completa", "cat": "Vegetales",
		"parts": [["lechuga"], ["tomate"], ["zanahoria", "cebolla"]],
		"sauces": ["Oliva y limón", "Vinagreta"], "toppings": ["Huevo duro", "Queso", "Croutons"]},
	"asadas": {"name": "Verduras asadas", "cat": "Vegetales", "parts": [["calabaza"], ["berenjena", "morron"]],
		"sauces": ["Oliva", "Sin salsa"], "toppings": ["Queso de cabra", "Semillas"]},
	"wok": {"name": "Arroz con vegetales", "cat": "Vegetales",
		"parts": [["arroz"], ["zanahoria", "cebolla"], ["morron"]],
		"sauces": ["Salsa de soja", "Sin salsa"], "toppings": ["Semillas", "Verdeo"]},
	"flan": {"name": "Flan", "cat": "Postres", "parts": [["flan"]],
		"sauces": [], "toppings": ["Dulce de leche", "Crema"], "min_toppings": 1},
	"panqueques": {"name": "Panqueques", "cat": "Postres", "parts": [["panqueque"]],
		"sauces": [], "toppings": ["Dulce de leche", "Crema", "Azúcar"], "min_toppings": 1},
	# Italia. "prebuilt": la salsa y los ingredientes van en la mesa de pizza, antes del horno
	"pizza": {"name": "Pizza", "cat": "Pizzas", "parts": [["pizza"]], "prebuilt": true, "min_toppings": 1,
		"sauces": ["Tomate", "Blanca"], "toppings": ["Mozzarella", "Jamón", "Aceitunas", "Champiñones", "Pepperoni", "Albahaca"]},
	"fettuccine": {"name": "Fettuccine", "cat": "Pasta fresca", "parts": [["fettuccine"]],
		"sauces": ["Pomodoro", "Alfredo", "Pesto"], "toppings": ["Parmesano", "Albahaca"]},
	"tiramisu": {"name": "Tiramisú", "cat": "Dolci", "parts": [["tiramisu"]], "sauces": [], "toppings": ["Cacao"], "min_toppings": 1},
	# México. Las salsas "Salsa verde", "Salsa roja" y "Guacamole" se muelen en el molcajete (MOLCAJETE)
	"tacos": {"name": "Tacos", "cat": "Tacos", "parts": [["tortilla"], ["carne_asada", "pastor", "pollo"]],
		"sauces": ["Salsa verde", "Salsa roja", "Guacamole"], "toppings": ["Cebolla y cilantro", "Limón", "Piña"]},
	"quesadilla": {"name": "Quesadilla", "cat": "Antojitos", "parts": [["tortilla"], ["queso"]],
		"sauces": ["Salsa verde", "Salsa roja", "Guacamole"], "toppings": ["Cebolla y cilantro", "Jalapeños"]},
	"plato_mex": {"name": "Plato con arroz y frijoles", "cat": "Platos fuertes", "parts": [["carne_asada", "pollo"], ["arroz"], ["frijoles"]],
		"sauces": ["Salsa roja", "Salsa verde", "Sin salsa"], "toppings": ["Queso fresco", "Crema"]},
	"churros": {"name": "Churros", "cat": "Postres", "parts": [["churros"]], "sauces": [],
		"toppings": ["Azúcar y canela", "Chocolate"], "min_toppings": 1},
	# Estados Unidos. "layered": el cliente pide las capas en un orden exacto (de abajo hacia arriba)
	"cheeseburger": {"name": "Cheeseburger", "cat": "Burgers", "parts": [["burger"]], "uses": ["hamburguesa"],
		"prebuilt": true, "layered": true, "sauces": [], "min_toppings": 2,
		"toppings": ["Cheddar", "Lechuga", "Tomate", "Cebolla", "Panceta", "Pepinos", "Ketchup", "Mostaza"]},
	"combo": {"name": "Combo con papas", "cat": "Burgers", "parts": [["burger"], ["papas_fritas", "aros_cebolla"]], "uses": ["hamburguesa"],
		"prebuilt": true, "layered": true, "sauces": [], "min_toppings": 2,
		"toppings": ["Cheddar", "Lechuga", "Tomate", "Cebolla", "Panceta", "Pepinos", "Ketchup", "Mostaza"]},
	"pancakes": {"name": "Pancakes", "cat": "Desayunos", "parts": [["panqueque"]],
		"sauces": ["Miel de maple", "Sin salsa"], "toppings": ["Manteca", "Frutillas", "Arándanos"], "min_toppings": 1},
	"malteada": {"name": "Malteada", "cat": "Malteadas", "parts": [["malteada_choco", "malteada_frutilla", "malteada_vainilla"]],
		"sauces": [], "toppings": ["Crema", "Cereza"], "min_toppings": 1},
	# Francia
	"crepe_dulce": {"name": "Crêpe dulce", "cat": "Crêpes dulces", "parts": [["crepe"]],
		"sauces": ["Choco-avellanas", "Caramelo", "Limón y azúcar"], "toppings": ["Frutillas", "Banana", "Azúcar"]},
	"crepe_salada": {"name": "Crêpe salada", "cat": "Crêpes saladas", "parts": [["crepe"], ["jamon", "champinones"]],
		"sauces": ["Bechamel", "Sin salsa"], "toppings": ["Queso gruyère", "Ciboulette"]},
	"croissant": {"name": "Croissant", "cat": "Boulangerie", "parts": [["croissant"]], "sauces": [],
		"toppings": ["Manteca", "Mermelada"], "min_toppings": 1},
	"eclair": {"name": "Éclair", "cat": "Pâtisserie", "parts": [["eclair"]], "prebuilt": true, "piped": true,
		"sauces": ["Chocolate", "Café", "Frutilla"], "toppings": []},
}

# Cada día suma recetas nuevas al menú y sube la dificultad.
# interval: segundos entre clientes (mín, máx) · patience: segundos de espera sin penalización
# show_zone: la barra de cocción marca el punto ideal (en los días difíciles hay que medir el tiempo)
const LEVELS := [
	{"name": "Día 1 · Primeros pasos", "new": ["spaghetti", "milanesa"], "customers": 4,
		"interval": [24.0, 30.0], "patience": 100.0, "max_toppings": 1, "show_zone": true},
	{"name": "Día 2 · A la plancha", "new": ["bife", "noquis"], "customers": 5,
		"interval": [23.0, 29.0], "patience": 100.0, "max_toppings": 1, "show_zone": true},
	{"name": "Día 3 · De la huerta", "new": ["ensalada", "pollo"], "customers": 6,
		"interval": [22.0, 28.0], "patience": 105.0, "max_toppings": 2, "show_zone": true},
	{"name": "Día 4 · A ojo de cocinero", "new": ["hamburguesa", "asadas", "ravioles"], "customers": 7,
		"interval": [22.0, 28.0], "patience": 110.0, "max_toppings": 2, "show_zone": false},
	{"name": "Día 5 · Dulce final", "new": ["wok", "flan"], "customers": 8,
		"interval": [21.0, 27.0], "patience": 115.0, "max_toppings": 2, "show_zone": false},
	{"name": "Día 6 · Lleno total", "new": ["panqueques"], "customers": 10,
		"interval": [21.0, 27.0], "patience": 120.0, "max_toppings": 3, "show_zone": false},
	# Desde el Día 7 cada pedido viene con bebida: se sirve desde la heladera del emplatado
	{"name": "Día 7 · Con bebida", "new": [], "customers": 10, "drinks": true,
		"interval": [22.0, 28.0], "patience": 125.0, "max_toppings": 3, "show_zone": false},
]

# Días de la Trattoria del Forno (Roma)
const ITALY_LEVELS := [
	{"name": "Giorno 1 · La pizzería", "new": ["pizza"], "customers": 5,
		"interval": [28.0, 34.0], "patience": 110.0, "max_toppings": 2, "show_zone": true},
	{"name": "Giorno 2 · Pasta fresca", "new": ["fettuccine", "tiramisu"], "customers": 6, "tip": "El fettuccine es fresco: amasalo en la Mesa (tecla 3, botón Pasta fresca). Harina, huevos en el volcán, frotá para amasar, pasá el palote y cortá las tiras. Cada tanda rinde 3 porciones: conviene amasar antes de que se junten los pedidos.",
		"interval": [26.0, 32.0], "patience": 110.0, "max_toppings": 2, "show_zone": true},
	{"name": "Giorno 3 · Noche romana", "new": [], "customers": 8, "drinks": true,
		"interval": [25.0, 31.0], "patience": 115.0, "max_toppings": 3, "show_zone": false},
]

# Días de La Comalera (Ciudad de México)
const MEXICO_LEVELS := [
	{"name": "Día 1 · La taquería", "new": ["tacos"], "customers": 5,
		"interval": [28.0, 34.0], "patience": 110.0, "max_toppings": 2, "show_zone": true,
		"tip": "En la Tortillería (tecla 3): bolita de masa a la prensa, bajá la palanca y mandala al comal. En el comal tocá la tortilla para darla vuelta: se cocina el lado de abajo. Las salsas se muelen en el molcajete (botón Molcajete): cada molida rinde 4 porciones."},
	{"name": "Día 2 · Antojitos", "new": ["quesadilla", "churros"], "customers": 6,
		"interval": [26.0, 32.0], "patience": 110.0, "max_toppings": 2, "show_zone": true},
	{"name": "Día 3 · Comida corrida", "new": ["plato_mex"], "customers": 8, "drinks": true,
		"interval": [25.0, 31.0], "patience": 115.0, "max_toppings": 3, "show_zone": false},
]


# Días del Big Apple Diner (Nueva York)
const US_LEVELS := [
	{"name": "Day 1 · Hamburguesería", "new": ["cheeseburger"], "customers": 5,
		"interval": [28.0, 34.0], "patience": 110.0, "max_toppings": 2, "show_zone": true,
		"tip": "Las hamburguesas se arman en el Armado (tecla 3), capa por capa y en el orden EXACTO del ticket, de abajo hacia arriba. Primero cociná el medallón en la plancha: queda en la bandeja y desde el Armado lo agregás como la capa Carne."},
	{"name": "Day 2 · Desayuno y malteadas", "new": ["pancakes", "malteada"], "customers": 6,
		"interval": [26.0, 32.0], "patience": 110.0, "max_toppings": 2, "show_zone": true,
		"tip": "Malteadas: arrastrá el helado a la licuadora y sacala a tiempo (si se pasa, queda aguada). Pancakes en la plancha, ¡sin sal!"},
	{"name": "Day 3 · Combo neoyorquino", "new": ["combo"], "customers": 8, "drinks": true,
		"interval": [25.0, 31.0], "patience": 115.0, "max_toppings": 3, "show_zone": false},
]


# Días de Le Petit Crêpier (París)
const FRANCE_LEVELS := [
	{"name": "Jour 1 · La crêperie", "new": ["crepe_dulce"], "customers": 5,
		"interval": [28.0, 34.0], "patience": 110.0, "max_toppings": 2, "show_zone": true,
		"tip": "En la Crêperie (tecla 3): arrastrá el cucharón con masa a la crêpière y esparcila haciendo círculos con el rastrillo hasta cubrir todo. Después va a la crepera de la Cocina: tocala para darla vuelta cuando se dore."},
	{"name": "Jour 2 · Boulangerie", "new": ["croissant", "eclair"], "customers": 6,
		"interval": [26.0, 32.0], "patience": 110.0, "max_toppings": 2, "show_zone": true,
		"tip": "Los éclairs se decoran con la manga (botón Manga en la Crêperie): elegí el sabor que pidió y seguí la línea punteada manteniendo apretado. Cuanto mejor sigas la guía, más lindo queda."},
	{"name": "Jour 3 · Dîner à Paris", "new": ["crepe_salada"], "customers": 8, "drinks": true,
		"interval": [25.0, 31.0], "patience": 115.0, "max_toppings": 3, "show_zone": false},
]
const CREPE_SPREAD_TURNS := 3.0   # vueltas con el rastrillo para cubrir toda la crêpière
const PIPE_FLAVORS := {"Chocolate": Color("4a2412"), "Café": Color("a0703a"), "Frutilla": Color("f28aa8")}

# Molcajete (México): ingredientes de cada salsa y cuántas vueltas de mano hacen falta para molerla
const MOLCAJETE := {
	"Salsa verde": ["tomatillo", "chile", "cilantro"],
	"Salsa roja": ["tomate", "chile", "ajo"],
	"Guacamole": ["palta", "cebolla", "limon"],
}
const MOLCAJETE_TURNS := 5.0     # vueltas completas con el tejolote
const MOLCAJETE_YIELD := 4       # porciones por molida

# =====================================================================
# Modo historia: cada país es un "paquete" con su ciudad, su cocina, sus días y su forma de cocinar.
# Solo gana plata el local donde jugás; lo ganado va a los ahorros, que sirven para abrir países nuevos.
# lon/lat ubican la ciudad en el mapamundi. ready = false: la cocina de ese país todavía se está armando.
# flag: [tipo, colores]: "h" franjas horizontales, "v" verticales, "circulo" (Japón), "barras" (EE.UU.)
# =====================================================================
const COUNTRIES := {
	"argentina": {"name": "Argentina", "city": "Buenos Aires", "restaurant": "Viandas", "lon": -58.4, "lat": -34.6,
		"flag": ["h", [Color("74acdf"), Color("ffffff"), Color("74acdf")]],
		"cuisine": "Milanesas, bifes, pastas caseras y ensaladas",
		"cooking": "Plancha, olla, freidora y horno", "price": 0, "stars_needed": 0, "ready": true, "levels": LEVELS},
	"mexico": {"name": "México", "city": "Ciudad de México", "restaurant": "La Comalera", "lon": -99.1, "lat": 19.4,
		"flag": ["v", [Color("006847"), Color("ffffff"), Color("ce1126")]],
		"cuisine": "Tacos, quesadillas, churros y salsas molidas", "cooking": "Prensa y comal para las tortillas, molcajete para las salsas",
		"price": 6000, "stars_needed": 2, "ready": true, "levels": MEXICO_LEVELS, "prep": "tortilleria",
		"names": ["Lupita", "Chuy", "Doña Carmen", "Pepe", "Xóchitl", "Memo", "Rosa", "Toño", "Paco", "Mari", "Don Beto", "Itzel"],
		"drinks": ["Agua", "Cola", "Agua de jamaica", "Horchata", "Limonada"]},
	"eeuu": {"name": "Estados Unidos", "city": "Nueva York", "restaurant": "Big Apple Diner", "lon": -74.0, "lat": 40.7,
		"flag": ["barras", [Color("b22234"), Color("ffffff"), Color("3c3b6e")]],
		"cuisine": "Hamburguesas, pancakes y malteadas", "cooking": "Armado por capas en el orden exacto y licuadora",
		"price": 7000, "stars_needed": 3, "ready": true, "levels": US_LEVELS, "prep": "armado",
		"names": ["Mike", "Jenny", "Bob", "Ashley", "Tony", "Linda", "Kevin", "Brittany", "Joe", "Megan", "Big Al", "Stacy"],
		"drinks": ["Agua", "Cola", "Lima-limón", "Naranja", "Limonada"]},
	"italia": {"name": "Italia", "city": "Roma", "restaurant": "Trattoria del Forno", "lon": 12.5, "lat": 41.9,
		"flag": ["v", [Color("009246"), Color("ffffff"), Color("ce2b37")]],
		"cuisine": "Pizza al horno de leña, pasta fresca y tiramisú", "cooking": "Mesa de pizza y horno de leña con pala",
		"price": 5000, "stars_needed": 0, "ready": true, "levels": ITALY_LEVELS, "prep": "mesa",
		"names": ["Giulia", "Marco", "Nonna Pina", "Luca", "Francesca", "Gino", "Sofia", "Paolo", "Chiara", "Enzo", "Rosaria", "Matteo"]},
	"francia": {"name": "Francia", "city": "París", "restaurant": "Le Petit Crêpier", "lon": 2.35, "lat": 48.85, "label_left": true,
		"flag": ["v", [Color("0055a4"), Color("ffffff"), Color("ef4135")]],
		"cuisine": "Crêpes dulces y saladas, croissants y éclairs", "cooking": "Crêpière con rastrillo, crepera y decoración con manga",
		"price": 8000, "stars_needed": 4, "ready": true, "levels": FRANCE_LEVELS, "prep": "creperie",
		"names": ["Amélie", "Pierre", "Madame Colette", "Louis", "Chloé", "Jean", "Sophie", "Henri", "Camille", "Lucas", "Margaux", "Théo"],
		"drinks": ["Agua", "Vino tinto", "Limonada", "Naranja"]},
	"india": {"name": "India", "city": "Mumbai", "restaurant": "Masala Express", "lon": 72.8, "lat": 19.0,
		"flag": ["h", [Color("ff9933"), Color("ffffff"), Color("138808")]],
		"cuisine": "Curry, naan y lassi", "cooking": "Especias en orden y horno tandoor",
		"price": 9000, "stars_needed": 5, "ready": false, "levels": []},
	"japon": {"name": "Japón", "city": "Tokio", "restaurant": "Sakura Ramen", "lon": 139.7, "lat": 35.7,
		"flag": ["circulo", [Color("ffffff"), Color("bc002d")]],
		"cuisine": "Sushi, ramen y yakisoba", "cooking": "Esterilla de sushi y wok",
		"price": 10000, "stars_needed": 6, "ready": false, "levels": []},
}
const COUNTRY_ORDER := ["argentina", "italia", "mexico", "eeuu", "francia", "india", "japon"]

# Bebidas de la heladera del emplatado (desde el Día 7). kind: lata o botella.
# Copa de vino: el nivel 1 es hasta la parte más ancha. Entre WINE_OK.x y WINE_OK.y está perfecto.
const WINE_OK := Vector2(0.85, 1.15)
const WINE_POUR := 0.32       # cuánto sube por segundo con la botella bien volcada


## Puntaje de la copa (0-100): lo justo es hasta la parte más ancha; derramar arruina la presentación
static func wine_score(fill: float, spill: float) -> float:
	var sc := 100.0
	if fill < WINE_OK.x:
		sc = 100.0 - (WINE_OK.x - fill) * 160.0
	elif fill > WINE_OK.y:
		sc = 100.0 - (fill - WINE_OK.y) * 200.0
	if spill > 0.02:
		sc *= 0.5
	return clampf(sc, 0.0, 100.0)


## Cómo quedó la copa, en palabras
static func wine_desc(fill: float, spill: float) -> String:
	if spill > 0.02:
		return "derramada"
	if fill < 0.05:
		return "vacía"
	if fill < WINE_OK.x:
		return "poca"
	if fill > WINE_OK.y:
		return "muy llena"
	return "justa"

const DRINKS := {
	"Agua": {"color": Color("8fd3f4"), "label": Color("2f6f9f"), "kind": "botella"},
	"Cola": {"color": Color("4a1e10"), "label": Color("c8281e"), "kind": "lata"},
	"Lima-limón": {"color": Color("9fd36a"), "label": Color("2f8a3a"), "kind": "lata"},
	"Naranja": {"color": Color("f39a1e"), "label": Color("ffffff"), "kind": "botella"},
	"Pomelo": {"color": Color("f2a3a8"), "label": Color("d9475a"), "kind": "lata"},
	"Limonada": {"color": Color("f3e27a"), "label": Color("4f9a48"), "kind": "botella"},
	"Vino tinto": {"color": Color("6e0f22"), "label": Color("efe4c8"), "kind": "vino"},   # se sirve en copa: hay que llenarla con la botella
	"Agua de jamaica": {"color": Color("a3123f"), "label": Color("f6c6d6"), "kind": "botella"},
	"Horchata": {"color": Color("f1e8d6"), "label": Color("b07a3a"), "kind": "botella"},
}

# Pasta fresca (Italia): se amasa a mano en la Mesa. Lo que lleva "fresh" en ITEMS no está en la heladera
# hasta que se amasa: cada tanda rinde PASTA_YIELD porciones.
const PASTA_KNEAD_PX := 2200.0   # cuánto hay que frotar (en píxeles de movimiento) para que la masa quede lisa
const PASTA_ROLL_PX := 1700.0    # cuánto hay que pasar el palote
const PASTA_CUTS := 7            # cortes para sacar las tiras
const PASTA_YIELD := 3
