extends SceneTree
## Genera los sonidos del juego en assets/sfx/.
## Uso: godot --headless --path . -s res://tools/make_sfx.gd
## Loops de cocción (22 kHz): hervor, chisporroteo, freidora, horno
## Sonidos sueltos (44 kHz, más nítidos): caja, campanita, puerta, enojo, enojo2, timbre, birome

const SR := 22050          # loops de cocción
const SR_HI := 44100       # sonidos sueltos
const LEN := 4.0

var rng := RandomNumberGenerator.new()
var rate := SR


func _initialize() -> void:
	rng.seed = 11
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sfx"))
	rate = SR
	_save(_boil(), "res://assets/sfx/hervor.wav")
	_save(_sizzle(0.0), "res://assets/sfx/chisporroteo.wav")
	_save(_fryer(), "res://assets/sfx/freidora.wav")
	_save(_oven(), "res://assets/sfx/horno.wav")
	rate = SR_HI
	rng.seed = 23
	_save(_cash(), "res://assets/sfx/caja.wav", 0.7)
	_save(_door_bells(1.0), "res://assets/sfx/campanita.wav", 0.7)
	_save(_door_close(), "res://assets/sfx/puerta.wav", 0.55)
	_save(_grumble(150.0, 112.0, 0.5), "res://assets/sfx/enojo.wav", 0.7)
	_save(_grumble(128.0, 96.0, 0.42), "res://assets/sfx/enojo2.wav", 0.7)
	_save(_kitchen_ding(), "res://assets/sfx/timbre.wav", 0.6)
	_save(_pen(), "res://assets/sfx/birome.wav", 0.5)
	for v in 3:
		_save(_chop(v), "res://assets/sfx/corte%d.wav" % (v + 1), 0.6)
	quit()


## Cuchillo contra la tabla: un "toc" de madera y el crujido corto de la verdura
func _chop(variant: int) -> PackedFloat32Array:
	var buf := _one_shot(0.2)
	var f: float = [210.0, 240.0, 190.0][variant]
	for k in int(0.09 * rate):
		var x := float(k) / rate
		_put(buf, k, (sin(TAU * f * x) * 0.7 + sin(TAU * f * 2.3 * x) * 0.25) * exp(-x * 55.0))
	_noise_burst(buf, 0.0, 0.012, 0.6, 0.5)
	# Crujido: chasquidos chiquitos de la verdura que se parte
	for c in 5:
		_noise_burst(buf, 0.004 + c * 0.006 + rng.randf() * 0.004, 0.004, 0.25, 0.7, true)
	return buf


# =====================================================================
# Utilidades
# =====================================================================

func _n() -> int:
	return int(LEN * rate)


func _noise() -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(_n())
	for i in a.size():
		a[i] = rng.randf_range(-1.0, 1.0)
	return a


## Pasa-bajos de un polo. Se recorre dos veces para que el loop empalme sin clic.
func _lowpass(x: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var y := PackedFloat32Array()
	y.resize(x.size())
	var s := 0.0
	for p in 2:
		for i in x.size():
			s += k * (x[i] - s)
			y[i] = s
	return y


func _highpass(x: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var lp := _lowpass(x, k)
	var y := PackedFloat32Array()
	y.resize(x.size())
	for i in x.size():
		y[i] = x[i] - lp[i]
	return y


func _add(buf: PackedFloat32Array, i: int, v: float) -> void:
	buf[i % buf.size()] += v     # para loops: lo que sobra al final vuelve al principio


func _put(buf: PackedFloat32Array, i: int, v: float) -> void:
	if i >= 0 and i < buf.size():
		buf[i] += v


func _one_shot(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	return b


# =====================================================================
# Loops de cocción
# =====================================================================

## Burbujas: tonos cortos que suben de frecuencia (el "blop" del agua)
func _bubbles(buf: PackedFloat32Array, count: int, fmin: float, fmax: float, amp: float) -> void:
	for b in count:
		var start := rng.randi() % buf.size()
		var f0 := rng.randf_range(fmin, fmax)
		var dur := rng.randf_range(0.025, 0.08)
		var a := amp * rng.randf_range(0.3, 1.0)
		var len := int(dur * rate)
		var ph := 0.0
		for k in len:
			var x := float(k) / len
			ph += TAU * f0 * (1.0 + 2.5 * x) / rate
			var env := sin(PI * x)
			_add(buf, start + k, sin(ph) * env * env * a)


## Chasquidos: pequeños estallidos de ruido (la grasa que salta)
func _crackles(buf: PackedFloat32Array, count: int, amp: float) -> void:
	for c in count:
		var start := rng.randi() % buf.size()
		var a := amp * pow(rng.randf(), 2.0)
		var len := int(rng.randf_range(0.001, 0.004) * rate)
		for k in len:
			_add(buf, start + k, rng.randf_range(-1.0, 1.0) * a * (1.0 - float(k) / len))


func _boil() -> PackedFloat32Array:
	var rumble := _lowpass(_noise(), 0.02)
	var mid := _lowpass(_noise(), 0.12)
	var buf := PackedFloat32Array()
	buf.resize(_n())
	for i in buf.size():
		var t := float(i) / rate
		var swell := 0.75 + 0.25 * sin(TAU * t / LEN * 2.0)
		buf[i] = rumble[i] * 2.2 + mid[i] * 0.5 * swell
	_bubbles(buf, 260, 250.0, 900.0, 0.22)
	return buf


func _sizzle(extra_low: float) -> PackedFloat32Array:
	var hiss := _highpass(_noise(), 0.35)
	var flutter := _lowpass(_noise(), 0.0008)
	var buf := PackedFloat32Array()
	buf.resize(_n())
	for i in buf.size():
		buf[i] = hiss[i] * (0.28 + 2.5 * absf(flutter[i]))
	_crackles(buf, 900, 0.9)
	if extra_low > 0.0:
		var low := _lowpass(_noise(), 0.05)
		for i in buf.size():
			buf[i] += low[i] * extra_low
	return buf


func _fryer() -> PackedFloat32Array:
	var buf := _sizzle(1.6)
	var body := _lowpass(_highpass(_noise(), 0.02), 0.2)
	for i in buf.size():
		buf[i] = buf[i] * 0.8 + body[i] * 0.6
	_bubbles(buf, 420, 160.0, 480.0, 0.18)
	_crackles(buf, 600, 0.6)
	return buf


func _oven() -> PackedFloat32Array:
	var fan := _lowpass(_noise(), 0.06)
	var buf := PackedFloat32Array()
	buf.resize(_n())
	for i in buf.size():
		var t := float(i) / rate
		# 100 Hz exacto: entran 400 ciclos justos en 4 s, así el loop no tiene salto
		var hum := sin(TAU * 100.0 * t) * 0.18 + sin(TAU * 200.0 * t) * 0.08 + sin(TAU * 300.0 * t) * 0.03
		buf[i] = hum + fan[i] * 1.4
	for tick in [0.7, 2.9]:
		var s := int(tick * rate)
		for k in int(0.03 * rate):
			_add(buf, s + k, sin(TAU * 2400.0 * k / rate) * exp(-k / (0.004 * rate)) * 0.25)
	return buf


# =====================================================================
# Sonidos sueltos
# =====================================================================

## Campana: parciales inarmónicos que se apagan (los agudos más rápido)
func _bell(buf: PackedFloat32Array, t0: float, f: float, amp: float, ratios := [1.0, 2.76, 5.4], decays := [0.9, 0.35, 0.15]) -> void:
	var s0 := int(t0 * rate)
	var len := int(decays[0] * 5.0 * rate)
	for k in len:
		var x := float(k) / rate
		var v := 0.0
		for p in ratios.size():
			v += sin(TAU * f * ratios[p] * x) * exp(-x / decays[p]) / pow(p + 1.0, 0.8)
		_put(buf, s0 + k, v * amp * minf(x * 2000.0, 1.0))


func _noise_burst(buf: PackedFloat32Array, t0: float, dur: float, amp: float, k_lp: float, hp := false) -> void:
	var s0 := int(t0 * rate)
	var lp := 0.0
	var prev := 0.0
	var len := int(dur * rate)
	for k in len:
		var nz := rng.randf_range(-1.0, 1.0)
		lp += k_lp * (nz - lp)
		var v := lp
		if hp:
			v = lp - prev
			prev = lp
		var x := float(k) / len
		_put(buf, s0 + k, v * amp * exp(-x * 4.0) * minf(x * 40.0, 1.0))


## Una moneda que cae sobre el mostrador y rebota: mismo timbre metálico, golpes cada vez más seguidos y suaves
func _coin(buf: PackedFloat32Array, t0: float, amp: float) -> void:
	var f0 := rng.randf_range(2300.0, 3500.0)
	var ratios := [1.0, 1.59, 2.37, 3.14, 4.29]
	var decays := [0.28, 0.16, 0.1, 0.07, 0.045]
	var t := t0
	var gap := rng.randf_range(0.07, 0.1)
	var a := amp
	for bounce in 4:
		_noise_burst(buf, t, 0.004, a * 0.9, 0.9, true)
		_bell(buf, t, f0, a * 0.6, ratios, decays)
		t += gap
		gap *= 0.62
		a *= 0.5


func _cash() -> PackedFloat32Array:
	var buf := _one_shot(1.6)
	# Tecla: golpe mecánico seco
	_noise_burst(buf, 0.0, 0.03, 0.5, 0.35)
	for k in int(0.05 * rate):
		_put(buf, k, sin(TAU * 180.0 * k / rate) * exp(-k / (0.012 * rate)) * 0.4)
	# "Ching": campanita brillante de la caja registradora
	_bell(buf, 0.03, 2637.0, 0.5, [1.0, 2.0, 3.0, 4.2], [1.0, 0.45, 0.25, 0.12])
	# Cajón que sale rodando y frena contra el tope
	var s0 := int(0.08 * rate)
	var len := int(0.22 * rate)
	var lp := 0.0
	for k in len:
		lp += 0.06 * (rng.randf_range(-1.0, 1.0) - lp)
		var rattle := 0.6 + 0.4 * sin(TAU * 45.0 * k / rate)
		_put(buf, s0 + k, lp * 0.9 * rattle * sin(PI * float(k) / len))
	for k in int(0.06 * rate):
		_put(buf, int(0.3 * rate) + k, sin(TAU * 120.0 * k / rate) * exp(-k / (0.015 * rate)) * 0.35)
	# Monedas que caen al cajón y rebotan
	for c in 5:
		_coin(buf, 0.36 + c * 0.09 + rng.randf_range(-0.03, 0.03), 0.22 * (1.0 - c * 0.12))
	return buf


func _door_bells(vol: float) -> PackedFloat32Array:
	var buf := _one_shot(2.0)
	var freqs := [1760.0, 2093.0, 2349.0, 2637.0]
	for b in freqs.size():
		var hits := 2 + rng.randi() % 2
		for h in hits:
			var t := rng.randf_range(0.0, 0.45) + h * 0.12
			_bell(buf, t, freqs[b] * rng.randf_range(0.99, 1.01), vol * 0.22 / (h + 1.0))
	return buf


func _door_close() -> PackedFloat32Array:
	var buf := _one_shot(1.6)
	# Chirrido suave de la bisagra
	var ph := 0.0
	var creak := int(0.32 * rate)
	for k in creak:
		var x := float(k) / creak
		var f := 170.0 - 40.0 * x + 25.0 * sin(x * 40.0)
		ph += TAU * f / rate
		var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
		_put(buf, k, saw * 0.07 * sin(PI * x) * (0.6 + 0.4 * sin(x * 90.0)))
	# Golpe amortiguado de la puerta
	var hit := int(0.36 * rate)
	for k in int(0.3 * rate):
		var x := float(k) / rate
		_put(buf, hit + k, (sin(TAU * 70.0 * x) * 0.5 + sin(TAU * 110.0 * x) * 0.2) * exp(-x * 18.0))
	_noise_burst(buf, 0.36, 0.08, 0.35, 0.08)
	# Pestillo
	_bell(buf, 0.44, 2900.0, 0.08, [1.0, 1.7], [0.04, 0.025])
	# Las campanitas de la puerta, suaves
	var bells := _door_bells(0.4)
	for i in bells.size():
		_put(buf, int(0.37 * rate) + i, bells[i])
	return buf


## "Mmmh" de fastidio: un soplido corto y un murmullo grave que baja
func _grumble(f_start: float, f_end: float, dur: float) -> PackedFloat32Array:
	var buf := _one_shot(dur + 0.15)
	_noise_burst(buf, 0.0, 0.09, 0.2, 0.15)
	var ph := 0.0
	var s0 := int(0.05 * rate)
	var len := int(dur * rate)
	var lp1 := 0.0
	var lp2 := 0.0
	for k in len:
		var x := float(k) / len
		var f := lerpf(f_start, f_end, x) * (1.0 + 0.01 * sin(TAU * 6.0 * k / rate))
		ph += TAU * f / rate
		var v := 0.0
		for h in range(1, 9):
			v += sin(ph * h) / pow(h, 1.4)
		lp1 += 0.06 * (v - lp1)
		lp2 += 0.06 * (lp1 - lp2)
		var env := minf(x * 12.0, 1.0) * pow(1.0 - x, 1.5)
		_put(buf, s0 + k, lp2 * env * 0.6)
	return buf


## Timbre de cocina: un "ding" claro y corto
func _kitchen_ding() -> PackedFloat32Array:
	var buf := _one_shot(1.4)
	_bell(buf, 0.0, 1975.0, 0.6, [1.0, 2.76, 4.1], [0.7, 0.25, 0.1])
	return buf


## Birome escribiendo en papel: trazos cortos de raspado
func _pen() -> PackedFloat32Array:
	var buf := _one_shot(1.35)
	var t := 0.02
	while t < 1.25:
		var dur := rng.randf_range(0.05, 0.13)
		var s0 := int(t * rate)
		var len := int(dur * rate)
		var lp := 0.0
		var prev := 0.0
		for k in len:
			var nz := rng.randf_range(-1.0, 1.0)
			lp += 0.35 * (nz - lp)
			var hp := lp - prev
			prev = lp
			var x := float(k) / len
			var friction := 0.6 + 0.4 * sin(TAU * rng.randf_range(20.0, 40.0) * k / rate)
			_put(buf, s0 + k, hp * sin(PI * x) * friction * 0.8)
		t += dur + rng.randf_range(0.02, 0.07)
	return buf


func _save(buf: PackedFloat32Array, path: String, level := 0.8) -> void:
	var peak := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
	var g := level / maxf(peak, 0.0001)
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] * g, -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = bytes
	wav.save_to_wav(path)
	print("ok ", path)
