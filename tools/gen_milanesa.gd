extends SceneTree
## Genera las ilustraciones de la milanesa (cruda y frita) con textura de pan rallado.
## Uso: godot --headless --path . -s res://tools/gen_milanesa.gd

const C := Vector2(64, 66)


func _initialize() -> void:
	_write("res://assets/food/milanesa.svg", true)
	_write("res://assets/food/raw/milanesa.svg", false)
	quit()


func _outline(rng: RandomNumberGenerator) -> Array:
	var pts := []
	var n := 26
	for k in n:
		var a := TAU * k / n
		var r := 50.0 + rng.randf_range(-5.0, 5.0) + 4.0 * sin(a * 3.0 + 0.7)
		pts.append(C + Vector2(cos(a) * r * 1.12, sin(a) * r * 0.86))
	return pts


func _path(pts: Array) -> String:
	# Curva suave pasando por los puntos medios
	var n := pts.size()
	var m0: Vector2 = (pts[n - 1] + pts[0]) / 2.0
	var d := "M%.1f %.1f " % [m0.x, m0.y]
	for k in n:
		var p: Vector2 = pts[k]
		var m: Vector2 = (pts[k] + pts[(k + 1) % n]) / 2.0
		d += "Q%.1f %.1f %.1f %.1f " % [p.x, p.y, m.x, m.y]
	return d + "Z"


func _write(path: String, fried: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var pts := _outline(rng)
	var shape := _path(pts)
	var base := ["#f3c062", "#d48f38", "#a8621f"] if fried else ["#f4ead0", "#e3d3a8", "#c9b27e"]
	var edge := "#7a4214" if fried else "#b59c68"
	var specks := ["#e2a145", "#b8732a", "#f8d48c", "#8e4c18", "#fbe6b0", "#c98536"] if fried \
		else ["#fffaf0", "#d8c08c", "#cbb07a", "#f3e7c8", "#e9dcb6"]

	var s := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">\n'
	s += '<defs><radialGradient id="g" cx="42%" cy="38%" r="65%"><stop offset="0" stop-color="' + base[0] + \
		'"/><stop offset="0.7" stop-color="' + base[1] + '"/><stop offset="1" stop-color="' + base[2] + '"/></radialGradient>'
	s += '<clipPath id="c"><path d="' + shape + '"/></clipPath></defs>\n'
	# Sombra
	s += '<path d="' + shape + '" fill="#000000" opacity="0.18" transform="translate(2 4)"/>\n'
	# Relieve del rebozado en el borde
	for k in pts.size() * 2:
		var a := TAU * k / (pts.size() * 2.0)
		var p: Vector2 = _edge_point(pts, a)
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [p.x, p.y, rng.randf_range(2.5, 4.2), base[2]]
	s += '\n<path d="' + shape + '" fill="url(#g)" stroke="' + edge + '" stroke-width="2"/>\n'
	# Pan rallado: muchas miguitas de distintos tonos
	s += '<g clip-path="url(#c)">'
	for k in 220:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 52.0
		var p := C + Vector2(cos(a) * r * 1.12, sin(a) * r * 0.86)
		var col: String = specks[rng.randi() % specks.size()]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s" opacity="%.2f" transform="rotate(%d %.1f %.1f)"/>' % [
			p.x, p.y, rng.randf_range(0.7, 2.4), rng.randf_range(0.5, 1.6), col, rng.randf_range(0.55, 1.0),
			rng.randi() % 180, p.x, p.y]
	if fried:
		# Bordes más tostados y brillo de aceite
		s += '<path d="' + shape + '" fill="none" stroke="#8e4c18" stroke-width="7" opacity="0.35"/>'
		s += '<ellipse cx="46" cy="44" rx="16" ry="5" fill="#fff6d8" opacity="0.28" transform="rotate(-22 46 44)"/>'
		s += '<ellipse cx="82" cy="84" rx="9" ry="3" fill="#fff6d8" opacity="0.2" transform="rotate(-22 82 84)"/>'
	else:
		s += '<ellipse cx="48" cy="46" rx="16" ry="5" fill="#ffffff" opacity="0.25" transform="rotate(-22 48 46)"/>'
	s += '</g>\n</svg>\n'
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("ok ", path)


func _edge_point(pts: Array, a: float) -> Vector2:
	var n := pts.size()
	var f := a / TAU * n
	var k := int(f) % n
	return (pts[k] as Vector2).lerp(pts[(k + 1) % n], f - int(f))
