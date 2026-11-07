extends Control
## Tabla de cortar: muestra la verdura separándose en rodajas con cada corte.

signal chop_clicked
signal ingredient_dropped(item_id: String)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "raw"


func _drop_data(_at: Vector2, data: Variant) -> void:
	ingredient_dropped.emit(data["item"])

const Art = preload("res://art.gd")

var item_id := ""
var cuts := 0
var need := 1
var _knife := 0.0     # animación del cuchillo (1 = abajo)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func hit() -> void:
	_knife = 1.0


func _process(delta: float) -> void:
	_knife = maxf(_knife - delta * 6.0, 0.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and item_id != "":
		accept_event()
		chop_clicked.emit()


func _draw() -> void:
	var board := Art.fit_rect(Art.tex("kitchen/board"), Rect2(Vector2.ZERO, size))
	Art.draw_tex(self, Art.tex("kitchen/board"), board)
	if item_id == "":
		return
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var t := Art.food(item_id)
	var area := Rect2(board.position + Vector2(board.size.x * 0.18, board.size.y * 0.12), Vector2(board.size.x * 0.55, board.size.y * 0.76))
	var dst := Art.fit_rect(t, area)
	var ts := t.get_size()
	var n := cuts + 1
	var gap := 10.0
	for i in n:
		var src := Rect2(ts.x * i / n, 0, ts.x / n, ts.y)
		var off := (i - (n - 1) / 2.0) * gap
		var d := Rect2(dst.position.x + dst.size.x * i / n + off, dst.position.y, dst.size.x / n, dst.size.y)
		draw_texture_rect_region(t, d, src)
	# Cuchillo: se ubica donde va el próximo corte
	var next_x := dst.position.x + dst.size.x * (cuts + 1) / float(need + 1) + (cuts + 1 - n / 2.0) * gap * 0.5
	var knife_y := dst.position.y - 70 + _knife * 70
	var kt := Art.tex("kitchen/knife")
	var ksz := Vector2(240, 60) * 0.9
	Art.draw_tex_rot(self, kt, Vector2(next_x + 8, knife_y), ksz, -PI / 2.0 + 0.15)
