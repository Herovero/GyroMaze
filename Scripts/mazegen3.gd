extends Sprite2D

# --- CONFIGURATION ---
var map_width = 46  # Make this larger now since we are using more tiles per room!
var map_height = 25

# How wide (in tiles) should the path be?
# 1 = Standard (Same size as wall)
# 2 = Wide path (2x2 tiles)
# 3 = Very wide path (3x3 tiles)
var path_thickness = 3

# --- TILE DEFINITIONS ---
var tile_n = Vector2i(0, 0) # Wall (Dark Blue)
var tile_v = Vector2i(0, 1) # Floor (Light Blue)
var tile_s = Vector2i(1, 1) # Solved Path (Optional)

# --- INTERNAL VARIABLES ---
var maze_pos = Vector2i(0, 0)
var dir_history = []
var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
signal done

@onready var Maze = $"../maze"
# IMPORTANT: Reset this to 16 * Scale. Don't multiply by path_thickness here.
var effective_tile_size = 16 * 9.0 

func _ready() -> void:
	fill_map_with_walls()
	
	# Step 1: Calculate "Grid Step"
	# The step is: Path Thickness + 1 Wall Unit
	var step_size = path_thickness + 1
	
	var possible_rooms_x = (map_width - 1) / step_size
	var possible_rooms_y = (map_height - 1) / step_size
	
	# Step 2: Pick Random Start
	var random_x = (randi() % possible_rooms_x) * step_size + 1
	var random_y = (randi() % possible_rooms_y) * step_size + 1
	maze_pos = Vector2i(random_x, random_y)
	
	# Step 3: Dig the STARTING Room (It needs to be a block now!)
	dig_room(maze_pos, tile_v)
	
	generate_maze()
	
	# Step 4: Move Player
	move_player_to_start()

func fill_map_with_walls() -> void:
	for x in range(map_width):
		for y in range(map_height):
			Maze.set_cell(Vector2i(x, y), 0, tile_n)

# --- HELPER: DIGS A SQUARE ROOM INSTEAD OF 1 TILE ---
func dig_room(center_pos: Vector2i, tile_type: Vector2i):
	# We dig a square starting from the top-left of the current "cell"
	for x in range(path_thickness):
		for y in range(path_thickness):
			var dig_pos = center_pos + Vector2i(x, y)
			Maze.set_cell(dig_pos, 0, tile_type)

func get_neighbors() -> Array:
	var dlist = []
	var step_size = path_thickness + 1
	
	for dir in directions:
		# Jump by (Path + Wall) distance
		var next_pos = maze_pos + (dir * step_size)
		
		# Check if it's within bounds (Optional safety)
		if next_pos.x <= 0 or next_pos.x >= map_width - path_thickness or next_pos.y <= 0 or next_pos.y >= map_height - path_thickness:
			continue
			
		# Check if the target area is a Wall (Unvisited)
		# We just check the top-left corner of the target room
		if Maze.get_cell_atlas_coords(next_pos) == tile_n:
			dlist.append(dir)
	return dlist

func generate_maze() -> void:
	var step_size = path_thickness + 1
	
	while true:
		var dlist = get_neighbors()
		if dlist.is_empty():
			if dir_history.is_empty():
				done.emit()
				break
			var removed_dir = dir_history.pop_back()
			maze_pos -= removed_dir * step_size
		else:
			var dir = dlist.pick_random()
			
			# --- THE FIX: Dig a Bridge ---
			# We are moving from 'maze_pos' to 'maze_pos + (dir * step_size)'
			# We need to clear everything in between.
			
			# 1. Determine the top-left corner of the "Bridge" area
			# If moving Right/Down, we start at current pos.
			# If moving Left/Up, we start at the new destination.
			var bridge_start = maze_pos
			if dir == Vector2i.LEFT or dir == Vector2i.UP:
				bridge_start = maze_pos + (dir * step_size)
				
			# 2. Determine the size of the bridge
			# Ideally, it covers the two rooms AND the wall between them.
			var bridge_size = Vector2i(path_thickness, path_thickness)
			
			if dir.x != 0: # Horizontal Move
				# Stretch width to cover current room + wall + next room
				bridge_size.x = (path_thickness * 2) + 1 
			else: # Vertical Move
				# Stretch height
				bridge_size.y = (path_thickness * 2) + 1
			
			# 3. Dig the entire bridge area
			for x in range(bridge_size.x):
				for y in range(bridge_size.y):
					var dig_pos = bridge_start + Vector2i(x, y)
					Maze.set_cell(dig_pos, 0, tile_v)

			# --- End Fix ---

			# Move to new position
			maze_pos += dir * step_size
			dir_history.append(dir)

func move_player_to_start():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Calculate the PIXEL center of the large room
		# Start Pos (Top-Left) + Half the thickness of the room
		var room_pixel_size = effective_tile_size * path_thickness
		var center_offset = Vector2(room_pixel_size / 2, room_pixel_size / 2)
		
		var start_pixel_pos = (Vector2(maze_pos) * effective_tile_size) + center_offset
		
		player.global_position = start_pixel_pos
		player.linear_velocity = Vector2.ZERO
