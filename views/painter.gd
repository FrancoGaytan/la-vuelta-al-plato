extends Control
## Control que se dibuja con una función. Se usa para fondos y decorados.
## fn recibe (ci: CanvasItem, time: float).

var fn := Callable()
var animate := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if animate:
		queue_redraw()


func _draw() -> void:
	if fn.is_valid():
		fn.call(self, Time.get_ticks_msec() / 1000.0)
