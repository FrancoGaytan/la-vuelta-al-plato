extends Control
## Control que se dibuja con una función. Se usa para fondos y decorados.
## fn recibe (ci: CanvasItem, time: float).
## animate: se redibuja solo. fps > 0 limita cuántas veces por segundo (los fondos grandes con
## detalles lentos, como lámparas o vapor, no necesitan 60: así el juego anda liviano en el celu).

var fn := Callable()
var animate := false
var fps := 0.0
var _acc := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not animate:
		return
	if fps <= 0.0:
		queue_redraw()
		return
	_acc += delta
	if _acc >= 1.0 / fps:
		_acc = fmod(_acc, 1.0 / fps)
		queue_redraw()


func _draw() -> void:
	if fn.is_valid():
		fn.call(self, Time.get_ticks_msec() / 1000.0)
