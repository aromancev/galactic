# Represents a galaxy map with a number of _cells. Players can navigate from one cell to the
# neighbpor cell. The _cells are arranged in a hexagon pattern so each cell has no more than six
# neighbors. The size of _cells is calculated automatically based on `draw_radius` and `cell_count`.
class_name Galaxy
extends Node2D

const _CELL_SCENE := preload("galaxy_cell.tscn")

# Determines how far from the center a node inside a cell can "wiggle". Should be from 0 to 1.
const _CELL_JITTER_MIN := 0.4
const _CELL_JITTER_MAX := 0.7

# Radius in which the galaxy will be drawn.
@export_range(100, 1000) var draw_radius := 300

# Galaxy radius in number of _cells.
@export_range(1, 100) var radius := 3

var _cell_radius := float(draw_radius) / radius / 2
var _cells: Dictionary = {}
var _destination_cell: GalaxyCell
var _rand_state: int
var _current_axial: Vector2i


func generate() -> void:
	_rand_state = RandomNumberGenerator.new().state
	_set_model.rpc(_get_model())


func _ready() -> void:
	add_to_group(Replicator.GROUP)


func _get_model() -> PackedByteArray:
	var p := BinaryPayload.new()
	p.set_var(1, _rand_state)
	p.set_var(2, _current_axial)
	return p.encode()


@rpc("authority", "call_local", "reliable")
func _set_model(model: PackedByteArray) -> void:
	var p := BinaryPayload.decoded(model)

	_rand_state = p.get_var(1)
	_current_axial = p.get_var(2)

	var rand := RandomNumberGenerator.new()
	rand.state = _rand_state
	_generate_cells(rand)
	_set_current_cell(_current_axial)


func _draw() -> void:
	var current := _cells.get(_current_axial) as GalaxyCell
	if !current:
		return

	for n in current.neighbors:
		draw_dashed_line(current.node_position, n.node_position, Color.WHITE)


@rpc("any_peer", "call_local", "reliable")
func _move_to_cell(axial: Vector2i) -> void:
	var current := _cells.get(_current_axial) as GalaxyCell
	var target := _cells.get(axial) as GalaxyCell
	if !current or !target:
		return

	if target not in current.neighbors:
		return

	_set_current_cell(axial)


func _set_current_cell(axial: Vector2i) -> void:
	var target := _cells.get(axial, null) as GalaxyCell
	if !target:
		return

	var current := _cells.get(_current_axial) as GalaxyCell
	if current:
		current.is_selected = false

	target.is_selected = true
	_current_axial = axial
	queue_redraw()

	if target == _destination_cell:
		generate()


func _generate_cells(rand: RandomNumberGenerator) -> void:
	_clear_cells()

	_generate_cell(rand, Vector2i())
	var size := _cells.size()
	var key: Vector2i = _cells.keys()[rand.randi_range(0, _cells.size() - 1)]
	_destination_cell = _cells[key]
	_destination_cell.is_destination = true


func _on_cell_selected(cell: GalaxyCell, axial: Vector2i) -> void:
	var current := _cells.get(_current_axial) as GalaxyCell
	if not current or cell not in current.neighbors:
		return

	_move_to_cell.rpc(axial)


# Recursive.
# https://www.redblobgames.com/grids/hexagons/#coordinates-axial
# q -> x, r -> y
func _generate_cell(rand: RandomNumberGenerator, axial: Vector2i) -> GalaxyCell:
	if axial in _cells:
		return _cells[axial]

	# Too far from the center.
	if _axial_distance(Vector2i(), axial) > radius:
		return null

	# Magic formula to calculate pixel coordinates from Axial.
	# https://www.redblobgames.com/grids/hexagons/#hex-to-pixel-axial
	var pixel := Vector2(
		_cell_radius * (sqrt(3) / 2 * axial.x + sqrt(3) * axial.y),
		_cell_radius * (3. / 2 * axial.x),
	)

	var cell: GalaxyCell = _CELL_SCENE.instantiate()
	cell.position = pixel
	(
		cell
		. jitter(
			rand,
			_cell_radius * _CELL_JITTER_MIN,
			_cell_radius * _CELL_JITTER_MAX,
		)
	)
	cell.selected.connect(_on_cell_selected.bind(cell, axial))
	add_child(cell)
	_cells[axial] = cell

	# Starting from 0 degress (to the right) clockwise.
	var n: GalaxyCell = null
	n = _generate_cell(rand, axial + Vector2i(1, 0))
	if n:
		cell.neighbors.append(n)
	n = _generate_cell(rand, axial + Vector2i(0, 1))
	if n:
		cell.neighbors.append(n)
	n = _generate_cell(rand, axial + Vector2i(-1, 1))
	if n:
		cell.neighbors.append(n)
	n = _generate_cell(rand, axial + Vector2i(-1, 0))
	if n:
		cell.neighbors.append(n)
	n = _generate_cell(rand, axial + Vector2i(0, -1))
	if n:
		cell.neighbors.append(n)
	n = _generate_cell(rand, axial + Vector2i(1, -1))
	if n:
		cell.neighbors.append(n)

	return cell


func _clear_cells() -> void:
	for c: GalaxyCell in _cells.values():
		remove_child(c)
		c.queue_free()

	_cells.clear()


func _axial_distance(a: Vector2i, b: Vector2i) -> int:
	# Magic formula to calculate axial distance.
	# https://www.redblobgames.com/grids/hexagons/#distances
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2
