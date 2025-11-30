extends Sprite2D

# Add these variables to control size
var maze_pos = Vector2i(0, 0)
var dir_history = []
var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var map_width = 25  # Must be odd numbers usually work best for this algo
var map_height = 15

var tile_n = Vector2i(0, 0)
var tile_v = Vector2i(0, 1)
var tile_s = Vector2i(1, 1)

signal done

@onready var Maze = $"../maze"

# Calculate the REAL size (16 * 9 = 144)
var effective_tile_size = 16 * 9.0

func _ready() -> void:
	# 1. FILL THE RECTANGLE WITH WALLS FIRST
	fill_map_with_walls()
	
	# 2. Calculate how many "walkable rooms" fit in the width/height
	# We subtract 1 for the border, then divide by 2 for the grid step
	var possible_rooms_x = (map_width - 1) / 2
	var possible_rooms_y = (map_height - 1) / 2
	
	# 3. Pick a random room index and convert to Odd Coordinate
	# Formula: (RandomIndex * 2) + 1
	var random_x = (randi() % possible_rooms_x) * 2 + 1
	var random_y = (randi() % possible_rooms_y) * 2 + 1
	
	# 4. Set the random start position
	maze_pos = Vector2i(random_x, random_y)
	
	# 5. Mark start as visited and begin
	Maze.set_cell(maze_pos, 0, tile_v)
	generate_maze()
	
	# Update sprite position
	#position = 16 * maze_pos + Vector2i(1, 1)
	
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# 2. Calculate the center pixel of the tile
		# Grid * 16 = Top-Left corner of the tile
		# + Vector2(8, 8) = Moves to the CENTER of the 16x16 tile
		var center_offset = Vector2(effective_tile_size / 2, effective_tile_size / 2)
		var start_pixel_pos = (Vector2(maze_pos) * effective_tile_size) + center_offset
		
		# 3. Teleport the RigidBody safely
		# Since this is running in _ready (at the very start), direct setting works fine.
		player.global_position = start_pixel_pos
		
		# Optional: Kill any accidental momentum
		player.linear_velocity = Vector2.ZERO

func fill_map_with_walls() -> void:
	# Loop through every X and Y coordinate
	for x in range(map_width):
		for y in range(map_height):
			# Place a "New Wall" (tile_n) at every spot
			Maze.set_cell(Vector2i(x, y), 0, tile_n)

func get_neighbors() -> Array:
	var dlist = []
	for dir in directions:
		var next_pos = maze_pos + dir * 2
		if Maze.get_cell_atlas_coords(next_pos) == tile_n:
			dlist.append(dir)
	return dlist

func generate_maze() -> void:
	while true:
		var dlist = get_neighbors()
		if dlist.is_empty():
			if dir_history.is_empty():
				done.emit()
				break
			var removed_item = dir_history.pop_back()
			Maze.set_cell(maze_pos - removed_item, 0, tile_s)
			Maze.set_cell(maze_pos, 0, tile_s)
			maze_pos -= removed_item * 2
		else:
			var dir = dlist.pick_random()
			Maze.set_cell(maze_pos + dir, 0, tile_v)
			dir_history.append(dir)
			maze_pos += dir * 2
			Maze.set_cell(maze_pos, 0, tile_v)
