extends Control
## Pileta de la Bacha: se arrastra algo sucio, se frota con la esponja, se enjuaga con el grifo
## y, ya limpio, se arrastra al escurridor.

signal faucet_pressed
signal dropped(data: Dictionary)

const Art = preload("res://art.gd")

var item = null      # null o {kind, dirt, foam, seed}
var water := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _basin() -> Rect2:
	return Rect2(Vector2(0, size.y * 0.25), Vector2(size.x, size.y * 0.75))


func item_rect() -> Rect2:
	var c := _basin().get_center() + Vector2(0, -6)
	return Rect2(c - Vector2(90, 80), Vector2(180, 160))


func faucet_rect() -> Rect2:
	var base := Vector2(size.x / 2.0, _basin().position.y + 6)
	return Rect2(base + Vector2(-58, -36), Vector2(36, 36))


func is_over_item(local: Vector2) -> bool:
	return item != null and item_rect().grow(20).has_point(local)


func is_clean() -> bool:
	return item != null and item["dirt"] <= 0.0 and item["foam"] <= 0.0


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if faucet_rect().grow(8).has_point(mb.position):
			accept_event()
			faucet_pressed.emit()
	var mm := event as InputEventMouseMotion
	if mm != null:
		var hand := faucet_rect().grow(8).has_point(mm.position) or (is_clean() and item_rect().has_point(mm.position))
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hand else Control.CURSOR_ARROW


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "dirty" and item == null


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


func _get_drag_data(at: Vector2) -> Variant:
	if not is_clean() or not item_rect().has_point(at):
		return null
	var ghost := Control.new()
	var k: String = item["kind"]
	var p = load("res://views/painter.gd").new()
	p.size = Vector2(110, 100)
	p.position = Vector2(-55, -50)
	p.fn = func(ci, _t): Art.draw_tool(ci, Rect2(0, 0, 110, 100), k, 0.0, 0.0, true)
	ghost.add_child(p)
	set_drag_preview(ghost)
	return {"kind": "clean", "tool": k}


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	Art.draw_sink(self, Rect2(Vector2.ZERO, size), water, t)
	var hint := "Arrastrá algo sucio a la pileta"
	if item != null:
		Art.draw_tool(self, item_rect(), item["kind"], item["dirt"], item["foam"], is_clean(), item["seed"])
		if water:
			for k in 8:
				var ph := fmod(t * 2.5 + k / 8.0, 1.0)
				draw_circle(item_rect().get_center() + Vector2(sin(k * 2.7) * 50, -40 + ph * 90), 2.0, Color(0.75, 0.9, 1.0, 0.8 * (1.0 - ph)))
		if item["dirt"] > 0.0:
			hint = "Frotá con la esponja haciendo círculos"
		elif item["foam"] > 0.0:
			hint = "Enjuagando..." if water else "Abrí el grifo (manija) para enjuagar"
		else:
			hint = "¡Limpio! Arrastralo al escurridor"
		# Barrita de mugre
		var bar := Rect2(item_rect().position.x + 20, item_rect().end.y + 8, item_rect().size.x - 40, 8)
		Art.rrect(self, bar.grow(2), Color(0, 0, 0, 0.5), 4)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * (1.0 - item["dirt"]), bar.size.y)), Color("5ec8e0"))
	Art.text(self, Vector2(0, size.y - 8), hint, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 5)
