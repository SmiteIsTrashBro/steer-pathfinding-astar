@tool
extends Node2D

# Grid settings
@export var cell_size := Vector2(32, 32)  # Size of each cell
@export var grid_size := Vector2i(20, 20)  # Number of cells horizontally
@export var allow_diagonal := false

# Pathfinding
var astar := AStar2D.new()
var obstacles := []  # Array to store obstacle positions

func _ready():
	# Initialize the grid for pathfinding
	_create_pathfinding_grid()
	add_obstacle(Vector2(250, 250))
	
func _create_pathfinding_grid():
	# Clear any existing data
	astar.clear()
	
	# Add all grid points
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var point_id = _get_id_from_point(Vector2(x, y))
			astar.add_point(point_id, Vector2(x, y))
	
	# Connect the points (with 4-way connectivity)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var current_point = Vector2(x, y)
			var current_id = _get_id_from_point(current_point)
			
			# Check in all four directions
			var directions = [
				Vector2(1, 0),   # Right
				Vector2(-1, 0),  # Left
				Vector2(0, 1),   # Down
				Vector2(0, -1),  # Up
			]
			
			if allow_diagonal:
				directions.append_array([
					Vector2(1, 1),    # Down-Right
					Vector2(-1, 1),   # Down-Left
					Vector2(1, -1),   # Up-Right
					Vector2(-1, -1),  # Up-Left
				])
			
			for direction in directions:
				var next_point = current_point + direction
				
				# Skip if outside grid
				if next_point.x < 0 or next_point.x >= grid_size.x or next_point.y < 0 or next_point.y >= grid_size.y:
					continue
				
				var next_id = _get_id_from_point(next_point)
				
				# Connect points if not already connected
				if not astar.are_points_connected(current_id, next_id):
					astar.connect_points(current_id, next_id)

# Function to update obstacles
func update_obstacles(new_obstacles: Array):
	# First, reconnect all points (clear old obstacles)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var current_id = _get_id_from_point(Vector2(x, y))
			astar.set_point_disabled(current_id, false)
	
	# Now, disable points for new obstacles
	obstacles = new_obstacles
	for obstacle in obstacles:
		var point_id = _get_id_from_point(obstacle)
		astar.set_point_disabled(point_id, true)

# Add a single obstacle at grid position
func add_obstacle(position: Vector2):
	var grid_pos = world_to_grid(position)
	if not obstacles.has(grid_pos):
		obstacles.append(grid_pos)
		var point_id = _get_id_from_point(grid_pos)
		astar.set_point_disabled(point_id, true)

# Remove a single obstacle
func remove_obstacle(position: Vector2):
	var grid_pos = world_to_grid(position)
	if obstacles.has(grid_pos):
		obstacles.erase(grid_pos)
		var point_id = _get_id_from_point(grid_pos)
		astar.set_point_disabled(point_id, false)

# Get a path from start to end position
func find_path(start_pos: Vector2, end_pos: Vector2) -> PackedVector2Array:
	var start_grid = world_to_grid(start_pos)
	var end_grid = world_to_grid(end_pos)
	
	var start_id = _get_id_from_point(start_grid)
	var end_id = _get_id_from_point(end_grid)
	
	if astar.has_point(start_id) and astar.has_point(end_id):
		var path_grid = astar.get_point_path(start_id, end_id)
		var path_world = PackedVector2Array()
		
		# Convert grid positions to world positions
		for point in path_grid:
			path_world.append(grid_to_world(point))
		
		return path_world
	
	return PackedVector2Array()

# Helper function to get a unique ID for a grid position
func _get_id_from_point(point: Vector2) -> int:
	return int(point.y * grid_size.x + point.x)

# Convert world position to grid position
func world_to_grid(world_pos: Vector2) -> Vector2:
	var grid_x = int(world_pos.x / cell_size.x)
	var grid_y = int(world_pos.y / cell_size.y)
	return Vector2(grid_x, grid_y)

# Convert grid position to world position (center of the cell)
func grid_to_world(grid_pos: Vector2) -> Vector2:
	var world_x = grid_pos.x * cell_size.x + cell_size.x / 2
	var world_y = grid_pos.y * cell_size.y + cell_size.y / 2
	return Vector2(world_x, world_y)

# For debugging - draw the grid and path
func _draw():
	# Draw grid
	for x in range(grid_size.x + 1):
		draw_line(
			Vector2(x * cell_size.x, 0),
			Vector2(x * cell_size.x, grid_size.y * cell_size.y),
			Color.GRAY,
			1.0
		)
	
	for y in range(grid_size.y + 1):
		draw_line(
			Vector2(0, y * cell_size.y),
			Vector2(grid_size.x * cell_size.x, y * cell_size.y),
			Color.GRAY,
			1.0
		)
	
	# Draw obstacles
	for obstacle in obstacles:
		var rect = Rect2(
			obstacle.x * cell_size.x,
			obstacle.y * cell_size.y,
			cell_size.x,
			cell_size.y
		)
		draw_rect(rect, Color.RED)

# Call this to update the visualization
func update_visualization():
	queue_redraw()
