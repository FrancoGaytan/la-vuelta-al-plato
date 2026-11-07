extends SceneTree
## Genera ilustraciones de comida con mucho detalle (muchos fideos, granos, papas...).
## Uso: godot --headless --path . -s res://tools/gen_food.gd

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_write("res://assets/food/spaghetti.svg", _spaghetti())
	_write("res://assets/food/arroz.svg", _rice())
	_write("res://assets/food/papas_fritas.svg", _fries(true))
	_write("res://assets/food/raw/papas_fritas.svg", _fries(false))
	_write("res://assets/food/pure.svg", _mash())
	quit()


func _write(path: String, body: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">\n' + body + '</svg>\n')
	f.close()
	print("ok ", path)


func _v(p: Vector2) -> String:
	return "%.1f %.1f" % [p.x, p.y]


## Nido de spaghetti: muchos fideos que se enroscan, cada uno con sombra y brillo
func _spaghetti() -> String:
	rng.seed = 5
	var s := '<defs><radialGradient id="g" cx="50%" cy="45%" r="55%"><stop offset="0" stop-color="#f3d58a"/><stop offset="1" stop-color="#d9ad55"/></radialGradient></defs>\n'
	s += '<ellipse cx="66" cy="70" rx="52" ry="44" fill="#000" opacity="0.15"/>\n'
	s += '<ellipse cx="64" cy="66" rx="50" ry="42" fill="url(#g)"/>\n'
	var strands := ""
	var shines := ""
	for k in 30:
		var c := Vector2(64, 66)
		var a0 := rng.randf() * TAU
		var r0 := rng.randf_range(8, 40)
		var d := "M" + _v(c + Vector2(cos(a0) * r0 * 1.15, sin(a0) * r0 * 0.95))
		var a := a0
		var r := r0
		for seg in 4:
			a += rng.randf_range(0.6, 1.3)
			r = clampf(r + rng.randf_range(-10, 10), 6, 46)
			var ctrl := c + Vector2(cos(a - 0.4) * (r + 8) * 1.15, sin(a - 0.4) * (r + 8) * 0.95)
			var end := c + Vector2(cos(a) * r * 1.15, sin(a) * r * 0.95)
			d += " Q" + _v(ctrl) + " " + _v(end)
		strands += '<path d="%s" stroke="#c89640" stroke-width="3.6"/>' % d
		strands += '<path d="%s" stroke="#f6dc94" stroke-width="2.2"/>' % d
		if k % 3 == 0:
			shines += '<path d="%s" stroke="#fff5d0" stroke-width="0.8" opacity="0.8"/>' % d
	s += '<g fill="none" stroke-linecap="round">' + strands + shines + '</g>\n'
	return s


## Arroz: muchos granos sueltos con su sombrita
func _rice() -> String:
	rng.seed = 9
	var s := '<ellipse cx="66" cy="72" rx="50" ry="40" fill="#000" opacity="0.14"/>\n'
	s += '<ellipse cx="64" cy="68" rx="48" ry="38" fill="#ede7d6"/>\n<g>'
	for k in 180:
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf())
		var p := Vector2(64 + cos(a) * rr * 46, 68 + sin(a) * rr * 36 - (1.0 - rr) * 8)
		var rot := rng.randi() % 180
		var tone: String = ["#ffffff", "#fbf8ef", "#f4efe2"][rng.randi() % 3]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="4.2" ry="1.9" fill="#cfc6ae" transform="rotate(%d %.1f %.1f) translate(0.6 0.8)"/>' % [p.x, p.y, rot, p.x, p.y]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="4.0" ry="1.7" fill="%s" transform="rotate(%d %.1f %.1f)"/>' % [p.x, p.y, tone, rot, p.x, p.y]
	s += '</g>\n'
	return s


## Papas fritas (o crudas): bastones de largos distintos, puntas más tostadas y brillo de aceite
func _fries(cooked: bool) -> String:
	rng.seed = 3
	var body := "#f2b744" if cooked else "#f3e8c4"
	var edge := "#c47a1a" if cooked else "#d8c690"
	var tip := "#a85a12" if cooked else "#e2d4a2"
	var s := '<ellipse cx="66" cy="76" rx="48" ry="30" fill="#000" opacity="0.13"/>\n'
	s += '<defs><linearGradient id="f" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="%s"/><stop offset="0.45" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>\n' % [edge, body, edge]
	for k in 16:
		var p := Vector2(rng.randf_range(30, 98), rng.randf_range(42, 86))
		var rot := rng.randf_range(-80, 80)
		var length := rng.randf_range(44, 78)
		var w := rng.randf_range(8.5, 11.0)
		var g := '<g transform="translate(%.1f %.1f) rotate(%.1f)">' % [p.x, p.y, rot]
		g += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="2.5" fill="url(#f)" stroke="%s" stroke-width="1"/>' % [-w / 2, -length / 2, w, length, edge]
		if cooked:
			g += '<rect x="%.1f" y="%.1f" width="%.1f" height="6" rx="2" fill="%s" opacity="0.8"/>' % [-w / 2, -length / 2, w, tip]
			g += '<rect x="%.1f" y="%.1f" width="%.1f" height="5" rx="2" fill="%s" opacity="0.6"/>' % [-w / 2, length / 2 - 5, w, tip]
			g += '<rect x="%.1f" y="%.1f" width="1.6" height="%.1f" rx="0.8" fill="#fff4c8" opacity="0.75"/>' % [-w / 2 + 2, -length / 2 + 6, length - 12]
		else:
			g += '<rect x="%.1f" y="%.1f" width="1.6" height="%.1f" rx="0.8" fill="#ffffff" opacity="0.6"/>' % [-w / 2 + 2, -length / 2 + 4, length - 8]
		g += '</g>'
		s += g + "\n"
	return s


## Puré: montaña cremosa con surcos de tenedor, manteca derritiéndose y pimienta
func _mash() -> String:
	rng.seed = 21
	var s := '<defs><radialGradient id="p" cx="42%" cy="36%" r="64%"><stop offset="0" stop-color="#fff8dc"/><stop offset="0.7" stop-color="#f1dc9c"/><stop offset="1" stop-color="#ddc07a"/></radialGradient></defs>\n'
	s += '<ellipse cx="66" cy="82" rx="54" ry="30" fill="#000" opacity="0.15"/>\n'
	s += '<path d="M12 80 C8 52 34 28 64 26 C96 28 120 52 116 80 C112 102 90 110 64 110 C38 110 16 102 12 80 Z" fill="url(#p)"/>\n'
	s += '<g fill="none" stroke-linecap="round">'
	for k in 9:
		var y := 44.0 + k * 7.0
		var w := 46.0 - absf(k - 4) * 6.0
		var d := "M%.1f %.1f Q64 %.1f %.1f %.1f" % [64 - w, y + 4, y - 8, 64 + w, y + 4]
		s += '<path d="%s" stroke="#d9bd76" stroke-width="2.6"/>' % d
		s += '<path d="%s" stroke="#fffbe8" stroke-width="1.2" transform="translate(0 -2)"/>' % d
	s += '</g>\n'
	# Manteca derritiéndose
	s += '<path d="M50 50 C52 44 74 42 78 48 C82 56 72 62 62 60 C56 66 48 58 50 50 Z" fill="#ffe36b" opacity="0.85"/>\n'
	s += '<rect x="55" y="44" width="18" height="12" rx="3" fill="#ffd84a" transform="rotate(-8 64 50)"/>\n'
	s += '<rect x="57" y="46" width="7" height="4" rx="1.5" fill="#fff4b0" transform="rotate(-8 64 50)"/>\n'
	for k in 14:
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#4a3a2a" opacity="0.7"/>' % [rng.randf_range(30, 98), rng.randf_range(44, 96), rng.randf_range(0.6, 1.2)]
	s += '\n'
	return s
