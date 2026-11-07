extends RefCounted
## Datos del juego: aparatos, ingredientes, recetas y niveles.
## Para agregar contenido nuevo alcanza con editar este archivo.

const PASS_SCORE := 60.0   # promedio mínimo para desbloquear el día siguiente
const ZONE := 0.75         # margen (segundos) alrededor del punto ideal de cocción

# Lo que se pierde de la caja al tirar comida a la basura
const WASTE_COST := {"cook": 3, "chop": 1, "ready": 2, "condiment": 1}

const LEAVE_FACTOR := 2.3      # si esperan más que paciencia x esto, se van y abandonan el pedido
const COOK_SLOW := 1.35       # ritmo de cocción: todo se cocina un 35% más lento que los tiempos de las recetas
const SPRINKLE_TIME := 2.0   # segundos que hay que desparramar un topping sobre la comida

# Salero: lo que va en la plancha o la olla (con "salt": true) se sala sacudiendo el salero encima.
# 1.0 = bien salado (≈1 segundo de sacudir). Entre SALT_OK.x y SALT_OK.y está perfecto.
const SALT_TIME := 1.0
const SALT_OK := Vector2(0.8, 2.2)


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
	"ayudante": {"name": "Ayudante de cocina", "price": 260, "for": "Cocina",
		"desc": "Saca la comida del fuego justo en su punto: nunca más se quema nada."},
}
const UPGRADE_ORDER := ["caramelera", "plantas", "vajilla", "ventilador", "timbre", "procesadora", "hornalla", "reloj", "ayudante"]


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
}
const APPLIANCE_ORDER := ["olla", "plancha", "freidora", "horno", "horno_lena"]

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
	"fettuccine": {"name": "Fettuccine", "kind": "cook", "where": "olla", "salt": true, "target": 5.0, "burn": 10.0},
	"tiramisu": {"name": "Tiramisú", "kind": "ready"},
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
}

# Cada día suma recetas nuevas al menú y sube la dificultad.
# interval: segundos entre clientes (mín, máx) · patience: segundos de espera sin penalización
# show_zone: la barra de cocción marca el punto ideal (en los días difíciles hay que medir el tiempo)
const LEVELS := [
	{"name": "Día 1 · Primeros pasos", "new": ["spaghetti", "milanesa"], "customers": 4,
		"interval": [16.0, 22.0], "patience": 100.0, "max_toppings": 1, "show_zone": true},
	{"name": "Día 2 · A la plancha", "new": ["bife", "noquis"], "customers": 5,
		"interval": [14.0, 20.0], "patience": 100.0, "max_toppings": 1, "show_zone": true},
	{"name": "Día 3 · De la huerta", "new": ["ensalada", "pollo"], "customers": 6,
		"interval": [13.0, 18.0], "patience": 105.0, "max_toppings": 2, "show_zone": true},
	{"name": "Día 4 · A ojo de cocinero", "new": ["hamburguesa", "asadas", "ravioles"], "customers": 7,
		"interval": [13.0, 18.0], "patience": 110.0, "max_toppings": 2, "show_zone": false},
	{"name": "Día 5 · Dulce final", "new": ["wok", "flan"], "customers": 8,
		"interval": [12.0, 17.0], "patience": 115.0, "max_toppings": 2, "show_zone": false},
	{"name": "Día 6 · Lleno total", "new": ["panqueques"], "customers": 10,
		"interval": [12.0, 17.0], "patience": 120.0, "max_toppings": 3, "show_zone": false},
	# Desde el Día 7 cada pedido viene con bebida: se sirve desde la heladera del emplatado
	{"name": "Día 7 · Con bebida", "new": [], "customers": 10, "drinks": true,
		"interval": [12.0, 17.0], "patience": 125.0, "max_toppings": 3, "show_zone": false},
]

# Días de la Trattoria del Forno (Roma)
const ITALY_LEVELS := [
	{"name": "Giorno 1 · La pizzería", "new": ["pizza"], "customers": 5,
		"interval": [18.0, 24.0], "patience": 110.0, "max_toppings": 2, "show_zone": true},
	{"name": "Giorno 2 · Pasta fresca", "new": ["fettuccine", "tiramisu"], "customers": 6,
		"interval": [15.0, 21.0], "patience": 110.0, "max_toppings": 2, "show_zone": true},
	{"name": "Giorno 3 · Noche romana", "new": [], "customers": 8, "drinks": true,
		"interval": [14.0, 19.0], "patience": 115.0, "max_toppings": 3, "show_zone": false},
]

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
		"cuisine": "Tacos, quesadillas y salsas", "cooking": "Comal para tortillas y molcajete para moler",
		"price": 900, "stars_needed": 2, "ready": false, "levels": []},
	"eeuu": {"name": "Estados Unidos", "city": "Nueva York", "restaurant": "Big Apple Diner", "lon": -74.0, "lat": 40.7,
		"flag": ["barras", [Color("b22234"), Color("ffffff"), Color("3c3b6e")]],
		"cuisine": "Hamburguesas, hot dogs y malteadas", "cooking": "Armado por capas a contrarreloj",
		"price": 1200, "stars_needed": 3, "ready": false, "levels": []},
	"italia": {"name": "Italia", "city": "Roma", "restaurant": "Trattoria del Forno", "lon": 12.5, "lat": 41.9,
		"flag": ["v", [Color("009246"), Color("ffffff"), Color("ce2b37")]],
		"cuisine": "Pizza al horno de leña, pasta fresca y tiramisú", "cooking": "Mesa de pizza y horno de leña con pala",
		"price": 600, "stars_needed": 0, "ready": true, "levels": ITALY_LEVELS, "prep": "mesa"},
	"francia": {"name": "Francia", "city": "París", "restaurant": "Le Petit Crêpier", "lon": 2.35, "lat": 48.85, "label_left": true,
		"flag": ["v", [Color("0055a4"), Color("ffffff"), Color("ef4135")]],
		"cuisine": "Crêpes, croissants y pastelería", "cooking": "Sartén de crêpes y decoración con manga",
		"price": 1500, "stars_needed": 4, "ready": false, "levels": []},
	"india": {"name": "India", "city": "Mumbai", "restaurant": "Masala Express", "lon": 72.8, "lat": 19.0,
		"flag": ["h", [Color("ff9933"), Color("ffffff"), Color("138808")]],
		"cuisine": "Curry, naan y lassi", "cooking": "Especias en orden y horno tandoor",
		"price": 1800, "stars_needed": 5, "ready": false, "levels": []},
	"japon": {"name": "Japón", "city": "Tokio", "restaurant": "Sakura Ramen", "lon": 139.7, "lat": 35.7,
		"flag": ["circulo", [Color("ffffff"), Color("bc002d")]],
		"cuisine": "Sushi, ramen y yakisoba", "cooking": "Esterilla de sushi y wok",
		"price": 2200, "stars_needed": 6, "ready": false, "levels": []},
}
const COUNTRY_ORDER := ["argentina", "italia", "mexico", "eeuu", "francia", "india", "japon"]

# Bebidas de la heladera del emplatado (desde el Día 7). kind: lata o botella.
const DRINKS := {
	"Agua": {"color": Color("8fd3f4"), "label": Color("2f6f9f"), "kind": "botella"},
	"Cola": {"color": Color("4a1e10"), "label": Color("c8281e"), "kind": "lata"},
	"Lima-limón": {"color": Color("9fd36a"), "label": Color("2f8a3a"), "kind": "lata"},
	"Naranja": {"color": Color("f39a1e"), "label": Color("ffffff"), "kind": "botella"},
	"Pomelo": {"color": Color("f2a3a8"), "label": Color("d9475a"), "kind": "lata"},
	"Limonada": {"color": Color("f3e27a"), "label": Color("4f9a48"), "kind": "botella"},
}
