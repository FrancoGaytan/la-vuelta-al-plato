extends Control
## Escurridor: recibe lo que se lavó (y vuelve al stock limpio).

signal dropped(data: Dictionary)

const Art = preload("res://art.gd")

var recent: Array = []     # lo último que se puso a secar (para dibujarlo)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "clean"


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var vp := get_viewport()
	if vp != null and vp.gui_is_dragging():
		var dd = vp.gui_get_drag_data()
		if dd is Dictionary and dd.get("kind", "") == "clean":
			Art.rrect(self, Rect2(Vector2(-6, -6), size + Vector2(12, 12)), Color(0.4, 1, 0.4, 0.12), 12, Color("5ee06a"), 3)
	# Lo que está secando, parado entre los alambres, con gotitas
	for k in recent.size():
		var r := Rect2(Vector2(12 + k * (size.x - 24) / 4.0, 8), Vector2((size.x - 24) / 4.0, size.y - 34))
		Art.draw_tool(self, r, recent[k], 0.0, 0.0, false)
		var ph := fmod(t * 1.2 + k * 0.3, 1.0)
		draw_circle(Vector2(r.get_center().x, r.end.y - 10 + ph * 18), 2, Color(0.7, 0.88, 1.0, 1.0 - ph))
	Art.draw_rack(self, Rect2(Vector2.ZERO, size))
	Art.text(self, Vector2(0, size.y + 22), "Escurridor", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
