# Represents a galaxy map with a number of cells. Players can navigate from one cell to the neighbpor cell.
# The cells are arranged in a hexagon pattern so each cell has no more than 6 neighbors.
# The size of cells is calculated automatically based on `draw_radius` and `cell_count`.
class_name Galaxy
extends Node2D

const cell_scene := preload("galaxy_cell.tscn")

# Radius in which the galaxy will be drawn.
@export_range(100, 1000)
var draw_radius := 300

# Galaxy radius in number of cells.
@export_range(1, 100)
var radius := 3

# Determines how far from the center a node inside a cell can "wiggle". Should be from 0 to 1.
const cell_jitter_min := 0.4
const cell_jitter_max := 0.6

var cell_radius := float(draw_radius) / radius / 2
var cells: Dictionary = {}
var current_cell: GalaxyCell
var destination_cell: GalaxyCell
var seed_base: int = 0
var model := Model.new()

class Model:
    var rand_state: int

func generate():
    model = Model.new()
    model.rand_state = RandomNumberGenerator.new().state
    _update.rpc(inst_to_dict(model))

func _ready():
    Session.player_connected.connect(_on_player_connected)

func _draw():
    if not current_cell:
        return
    
    for n in current_cell.neighbors:
        draw_dashed_line(current_cell.node_position, n.node_position, Color.WHITE)

func _on_player_connected(peer_id, _player):
    if multiplayer.is_server():
        _update.rpc_id(peer_id, inst_to_dict(model))

# Idempotent, so can be called multiple time to re-generate.
@rpc("authority", "call_local", "reliable")
func _update(p_model: Dictionary):
    model = dict_to_inst(p_model) as Model

    var rand := RandomNumberGenerator.new()
    rand.state = model.rand_state

    _generate_cells(rand)
    _set_current_cell(Vector2i())

@rpc("any_peer", "call_local", "reliable")
func _set_current_cell(axial: Vector2i):
    var cell := cells[axial] as GalaxyCell
    if not cell:
        return

    if current_cell:
        current_cell.is_selected = false
    cell.is_selected = true
    current_cell = cell
    queue_redraw()

    if multiplayer.is_server() and cell == destination_cell:
        generate()

func _generate_cells(rand: RandomNumberGenerator):
    _clear_cells()

    _generate_cell(rand, Vector2i())
    var size = cells.size()
    var key: Vector2i = cells.keys()[rand.randi_range(0, cells.size()-1)]
    destination_cell = cells[key]
    destination_cell.is_destination = true
    
func _on_cell_selected(cell: GalaxyCell, axial: Vector2i):
    if not current_cell or cell not in current_cell.neighbors:
        return

    _set_current_cell.rpc(axial)

# Recursive.
# https://www.redblobgames.com/grids/hexagons/#coordinates-axial
# q -> x, r -> y
func _generate_cell(rand: RandomNumberGenerator, axial: Vector2i) -> GalaxyCell:
    if axial in cells:
        return cells[axial]
    
    # Too far from the center.
    if _axial_distance(Vector2i(), axial) > radius:
        return null

    # Magic formula to calculate pixel coordinates from Axial.
    # https://www.redblobgames.com/grids/hexagons/#hex-to-pixel-axial
    var pixel := Vector2(
        cell_radius * (sqrt(3) / 2 * axial.x  +  sqrt(3) * axial.y),
        cell_radius * (3./2 * axial.x),
    )

    var cell := cell_scene.instantiate()
    cell.position = pixel
    cell.jitter(
        rand, 
        cell_radius * cell_jitter_min, 
        cell_radius * cell_jitter_max,
    )
    cell.selected.connect(_on_cell_selected.bind(cell, axial))
    add_child(cell)
    cells[axial] = cell
    
    # Starting from 0 degress (to the right) clockwise.
    var n: GalaxyCell = null
    n = _generate_cell(rand, axial + Vector2i(1, 0))
    if n: cell.neighbors.append(n)
    n = _generate_cell(rand, axial + Vector2i(0, 1))
    if n: cell.neighbors.append(n)
    n = _generate_cell(rand, axial + Vector2i(-1, 1))
    if n: cell.neighbors.append(n)
    n = _generate_cell(rand, axial + Vector2i(-1, 0))
    if n: cell.neighbors.append(n)
    n = _generate_cell(rand, axial + Vector2i(0, -1))
    if n: cell.neighbors.append(n)
    n = _generate_cell(rand, axial + Vector2i(1, -1))
    if n: cell.neighbors.append(n)

    return cell

func _clear_cells():
    for c in cells.values():
        remove_child(c)
        c.queue_free()
    
    cells.clear()
    current_cell = null

func _axial_distance(a: Vector2i, b: Vector2i) -> int:
    # Magic formula to calculate axial distance.
    # https://www.redblobgames.com/grids/hexagons/#distances
    return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2
