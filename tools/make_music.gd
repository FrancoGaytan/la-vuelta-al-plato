extends SceneTree
## Genera la música de fondo (bossa nova tranquila) y la guarda en assets/music/lounge.wav.
## Uso: godot --headless --path . -s res://tools/make_music.gd
## Todo es síntesis: piano eléctrico (FM), bajo, vibráfono, flauta, escobillas y clave.

const SR := 22050
const BPM := 96.0
const BEAT := 60.0 / BPM
const BAR := BEAT * 4.0
const BARS := 32
const OUT := "res://assets/music/lounge.wav"

var buf := PackedFloat32Array()
var n := 0

# Acordes (voicing en MIDI) y bajo (fundamental, quinta)
const CH := {
	"Fmaj7": [[53, 57, 60, 64], 41, 48], "Dm7": [[50, 53, 57, 60], 38, 45], "Gm7": [[55, 58, 62, 65], 43, 50],
	"C7": [[52, 55, 58, 62], 36, 43], "Am7": [[55, 60, 64, 67], 45, 52], "D7": [[54, 57, 60, 64], 38, 45],
	"Bbmaj7": [[57, 62, 65, 69], 46, 41], "Bbm7": [[56, 61, 65, 68], 46, 41],
}
const A_SEC := ["Fmaj7", "Dm7", "Gm7", "C7", "Am7", "D7", "Gm7", "C7"]
const B_SEC := ["Bbmaj7", "Bbm7", "Am7", "D7", "Gm7", "C7", "Fmaj7", "C7"]

# Melodía: [compás dentro de la sección, tiempo, nota, duración]
const MEL_A := [
	[0, 0, 72, 1.5], [0, 1.5, 74, 0.5], [0, 2, 76, 1], [0, 3, 74, 0.5], [0, 3.5, 72, 0.5],
	[1, 0, 69, 2], [1, 2.5, 72, 0.5], [1, 3, 74, 1],
	[2, 0, 77, 1.5], [2, 1.5, 74, 0.5], [2, 2, 70, 1.5], [2, 3.5, 72, 0.5],
	[3, 0, 74, 1], [3, 1, 72, 1], [3, 2, 70, 1], [3, 3, 67, 1],
	[4, 0, 76, 1.5], [4, 1.5, 74, 0.5], [4, 2, 72, 1], [4, 3, 69, 1],
	[5, 0, 78, 1.5], [5, 1.5, 76, 0.5], [5, 2, 74, 2],
	[6, 0, 74, 1], [6, 1, 77, 1], [6, 2, 74, 1], [6, 3, 70, 1],
	[7, 0, 72, 3], [7, 3.5, 67, 0.5],
]
const MEL_B := [
	[0, 0, 81, 2], [0, 2, 77, 1], [0, 3, 74, 1],
	[1, 0, 80, 2], [1, 2, 77, 1], [1, 3, 73, 1],
	[2, 0, 76, 1.5], [2, 1.5, 72, 0.5], [2, 2, 79, 2],
	[3, 0, 78, 1], [3, 1, 74, 1], [3, 2, 72, 1], [3, 3, 69, 1],
	[4, 0, 70, 1.5], [4, 1.5, 74, 0.5], [4, 2, 77, 1.5], [4, 3.5, 79, 0.5],
	[5, 0, 76, 2], [5, 2, 74, 1], [5, 3, 72, 1],
	[6, 0, 69, 3],
	[7, 0, 67, 1], [7, 1, 70, 1], [7, 2, 72, 1], [7, 3, 76, 1],
]


func _initialize() -> void:
	n = int(BAR * BARS * SR)
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Forma: A A' B A''
	var form := [["A", 0], ["A", 1], ["B", 0], ["A", 2]]
	for s in form.size():
		var sec: String = form[s][0]
		var variant: int = form[s][1]
		var chords: Array = A_SEC if sec == "A" else B_SEC
		for b in 8:
			var bar_i := s * 8 + b
			var t0 := bar_i * BAR
			var ch: Array = CH[chords[b]]
			# Piano eléctrico: comping de bossa
			for hit in [[0.0, 1.1, 1.0], [1.5, 0.8, 0.8], [2.5, 0.9, 0.9], [3.5, 0.4, 0.6]]:
				for note in ch[0]:
					_rhodes(t0 + hit[0] * BEAT + rng.randf() * 0.012, hit[1] * BEAT, note, 0.055 * hit[2])
			# Bajo
			var root: int = ch[1]
			var fifth: int = ch[2]
			for bn in [[0.0, 1.4, root], [1.5, 0.45, fifth], [2.0, 1.4, root], [3.5, 0.45, fifth]]:
				_bass(t0 + bn[0] * BEAT, bn[1] * BEAT, bn[2], 0.30)
			# Escobillas (shaker) en corcheas, acentos a contratiempo
			for e in 8:
				var acc := 1.0 if e % 2 == 1 else 0.6
				_shaker(t0 + e * 0.5 * BEAT, 0.028 * acc, rng)
			# Bombo suave en 1 y 3
			_kick(t0, 0.13)
			_kick(t0 + 2.0 * BEAT, 0.10)
			# Clave de bossa (patrón de 2 compases)
			var clave := [0.0, 1.5, 3.0] if bar_i % 2 == 0 else [1.0, 2.5]
			for c in clave:
				_rim(t0 + c * BEAT, 0.035)
		# Melodía de la sección
		var mel: Array = MEL_A if sec == "A" else MEL_B
		for m in mel:
			var start: float = (s * 8 + m[0]) * BAR + m[1] * BEAT
			var dur: float = m[3] * BEAT
			# en A' la melodía la toca la flauta una octava abajo para variar
			if sec == "B" or variant == 1:
				_flute(start, dur, m[2] - (12 if variant == 1 else 0), 0.085)
			else:
				_vibes(start, dur, m[2], 0.11)
	_reverb()
	_save()
	quit()


func _hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


func _add(i: int, v: float) -> void:
	buf[i % n] += v     # el final se pega al principio: loop sin cortes


func _rhodes(t: float, dur: float, note: int, vol: float) -> void:
	var f := _hz(note)
	var s0 := int(t * SR)
	var len := int((dur + 0.25) * SR)
	for k in len:
		var x := float(k) / SR
		var env := (1.0 - exp(-x * 200.0)) * exp(-x / 1.1)
		if x > dur:
			env *= exp(-(x - dur) * 18.0)
		var idx := 1.6 * exp(-x * 3.0) + 0.15
		var v := sin(TAU * f * x + idx * sin(TAU * f * x))
		_add(s0 + k, v * env * vol)


func _bass(t: float, dur: float, note: int, vol: float) -> void:
	var f := _hz(note)
	var s0 := int(t * SR)
	var len := int((dur + 0.12) * SR)
	for k in len:
		var x := float(k) / SR
		var env := (1.0 - exp(-x * 150.0)) * exp(-x / 0.9)
		if x > dur:
			env *= exp(-(x - dur) * 30.0)
		var v := sin(TAU * f * x) + 0.25 * sin(TAU * 2.0 * f * x) + 0.08 * sin(TAU * 3.0 * f * x)
		_add(s0 + k, v * env * vol)


func _vibes(t: float, dur: float, note: int, vol: float) -> void:
	var f := _hz(note)
	var s0 := int(t * SR)
	var len := int((dur + 0.9) * SR)
	for k in len:
		var x := float(k) / SR
		var env := (1.0 - exp(-x * 400.0)) * exp(-x / 1.3)
		if x > dur:
			env *= exp(-(x - dur) * 5.0)
		var trem := 1.0 - 0.25 * (0.5 + 0.5 * sin(TAU * 5.0 * x))
		var v := sin(TAU * f * x) + 0.2 * exp(-x * 12.0) * sin(TAU * 4.0 * f * x)
		_add(s0 + k, v * env * trem * vol)


func _flute(t: float, dur: float, note: int, vol: float) -> void:
	var f := _hz(note)
	var s0 := int(t * SR)
	var len := int((dur + 0.15) * SR)
	var ph := 0.0
	for k in len:
		var x := float(k) / SR
		var env := minf(x / 0.07, 1.0) * (0.85 + 0.15 * exp(-x * 3.0))
		if x > dur:
			env *= exp(-(x - dur) * 25.0)
		var vib := 1.0 + 0.004 * sin(TAU * 5.2 * x) * minf(x / 0.3, 1.0)
		ph += TAU * f * vib / SR
		var v := sin(ph) + 0.12 * sin(2.0 * ph)
		_add(s0 + k, v * env * vol)


func _shaker(t: float, vol: float, rng: RandomNumberGenerator) -> void:
	var s0 := int(t * SR)
	var len := int(0.06 * SR)
	var prev := 0.0
	for k in len:
		var x := float(k) / SR
		var nz := rng.randf_range(-1.0, 1.0)
		var hp := nz - prev
		prev = nz
		var env := (1.0 - exp(-x * 600.0)) * exp(-x * 55.0)
		_add(s0 + k, hp * env * vol)


func _kick(t: float, vol: float) -> void:
	var s0 := int(t * SR)
	var len := int(0.22 * SR)
	var ph := 0.0
	for k in len:
		var x := float(k) / SR
		var f := 45.0 + 35.0 * exp(-x * 30.0)
		ph += TAU * f / SR
		_add(s0 + k, sin(ph) * exp(-x * 14.0) * vol)


func _rim(t: float, vol: float) -> void:
	var s0 := int(t * SR)
	var len := int(0.05 * SR)
	for k in len:
		var x := float(k) / SR
		_add(s0 + k, (sin(TAU * 1700.0 * x) + 0.5 * sin(TAU * 820.0 * x)) * exp(-x * 90.0) * vol)


func _reverb() -> void:
	# Reverb simple (4 combs en paralelo). Se procesa el loop dos veces para que la cola empalme.
	var delays := [557, 593, 641, 677]
	var wet := PackedFloat32Array()
	wet.resize(n)
	for d in delays:
		var line := PackedFloat32Array()
		line.resize(d)
		var pos := 0
		var lp := 0.0
		for pass_i in 2:
			for i in n:
				var y := line[pos]
				lp = y * 0.6 + lp * 0.4
				line[pos] = buf[i] + lp * 0.8
				pos = (pos + 1) % d
				if pass_i == 1:
					wet[i] += y * 0.25
	var peak := 0.0
	for i in n:
		buf[i] = buf[i] * 0.85 + wet[i] * 0.35
		peak = maxf(peak, absf(buf[i]))
	var g := 0.85 / maxf(peak, 0.001)
	for i in n:
		buf[i] *= g


func _save() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/music"))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo = false
	wav.data = bytes
	wav.save_to_wav(OUT)
	print("Música guardada: %s (%.1f s)" % [OUT, n / float(SR)])
