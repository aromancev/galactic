# Represents a galaxy map with a number of cells. Players can navigate from one cell to the neighbpor cell.
# The cells are arranged in a hexagon pattern so each cell has no more than 6 neighbors.
# THe size of cells is calculated automatically based on `radius` and `cell_count`.
extends Node2D

const cell_scene := preload("galaxy_cell.tscn")

# The radius of the generation area.
@export_range(100, 700)
var radius := 300

# Number of cells in the galaxy. 
# Note: the actual number of cells will not be exactly the same to preserve the hexagon pattern.
# To get the actual cell count use `cells.size()`.
@export_range(2, 100)
var cell_count := 30

# Determines how far from the center a node inside a cell can "wiggle". Should be from 0 to 1.
const cell_jitter := 0.6

var galaxy_area := pow(radius, 2) * PI
var cell_area := galaxy_area / cell_count
var cell_radius := sqrt(cell_area / PI)
var cells: Dictionary = {}
var current_cell: GalaxyCell
var destination_cell: GalaxyCell

func _ready():
	generate_cells()

func _draw():
	if not current_cell:
		return
	
	for n in current_cell.neighbors:
		draw_dashed_line(current_cell.node_position, n.node_position, Color.WHITE)

func _on_cell_selected(cell: GalaxyCell):
	if not current_cell or cell not in current_cell.neighbors:
		return

	if cell == destination_cell:
		generate_cells()
		return

	set_current_cell(cell)

# Idempotent, so can be called multiple time to re-generate.
func generate_cells():
	clear_cells()

	set_current_cell(
		generate_cell(Vector2())
	)
	var size = cells.size()
	var key: Vector2 = cells.keys()[randi_range(0, cells.size()-1)]
	destination_cell = cells[key]
	destination_cell.is_destination = true

# Recursive.
# https://www.redblobgames.com/grids/hexagons/#coordinates-axial
func generate_cell(c: Vector2) -> GalaxyCell:
	if c in cells:
		return cells[c]

	# Pre-defined magic formula to calculate pixel coordinates from Axial.
	# https://www.redblobgames.com/grids/hexagons/#hex-to-pixel-axial
	var pos := Vector2(
		cell_radius * (sqrt(3) / 2 * c.x  +  sqrt(3) * c.y),
		cell_radius * (3./2 * c.x),
	)

	# The resulting position is beyond the generation area.
	var dist := pos.length()
	if abs(dist) > radius:
		return null
	
	var cell := cell_scene.instantiate()
	cell.radius = cell_radius
	cell.jitter = cell_radius * cell_jitter
	cell.position = pos
	cell.selected.connect(_on_cell_selected.bind(cell))
	add_child(cell)
	cells[c] = cell
	
	# Starting from 0 degress (to the right) clockwise.
	var n: GalaxyCell = null
	n = generate_cell(c + Vector2(1, 0))
	if n: cell.neighbors.append(n)
	n = generate_cell(c + Vector2(0, 1))
	if n: cell.neighbors.append(n)
	n = generate_cell(c + Vector2(-1, 1))
	if n: cell.neighbors.append(n)
	n = generate_cell(c + Vector2(-1, 0))
	if n: cell.neighbors.append(n)
	n = generate_cell(c + Vector2(0, -1))
	if n: cell.neighbors.append(n)
	n = generate_cell(c + Vector2(1, -1))
	if n: cell.neighbors.append(n)

	return cell

func set_current_cell(cell: GalaxyCell):
	if not cell:
		return

	if current_cell:
		current_cell.is_selected = false
	cell.is_selected = true
	current_cell = cell
	queue_redraw()

func clear_cells():
	cells.clear()
	current_cell = null
	for c in get_children():
		remove_child(c)
		c.queue_free()
