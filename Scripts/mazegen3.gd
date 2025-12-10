extends Sprite2D

# --- CONFIGURATION ---
var map_width = 45 
var map_height = 25
#var map_width = randi_range(10, 30)
#var map_height = randi_range(10, 30)

# How wide (in tiles) should the path be?
# 1 = Standard (Same size as wall)
# 2 = Wide path (2x2 tiles)
# 3 = Very wide path (3x3 tiles)
var path_thickness = 2

# --- TILE DEFINITIONS ---
var tile_n = Vector2i(0, 0) # Wall (Dark Blue)
var tile_v = Vector2i(0, 1) # Floor (Light Blue)
var tile_b = Vector2i(1, 0) # Border (Dark Brown)
var tile_s = Vector2i(1, 1) # Solved Path (Optional)

# --- INTERNAL VARIABLES ---
var maze_pos = Vector2i(0, 0)
var dir_history = []
var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
signal done

@onready var Maze = $"../maze"
@onready var movement_tiles = $"../movement_tiles"

var effective_tile_size = 16 * 9.0 

@export var hole_scene: PackedScene  # Drag your Hole.tscn here in Inspector
@export var hole_count: int = 10     # How many holes do you want?
var hole_positions: Array[Vector2i] = []

@export var ghost_scene: PackedScene
@export var wing_scene: PackedScene

@export var timer_scene: PackedScene

@export var finish_scene: PackedScene
var finish_grid_pos = Vector2i.ZERO

func _ready() -> void:
	start_new_level()
	
	SignalBus.connect("switch_level", start_new_level)

func start_new_level():
	clear_current_level()
	
	# --- 1. RANDOMIZE PATH THICKNESS ---
	# Randomly choose between 1 (Standard), 2 (Wide), or 3 (Very Wide)
	path_thickness = randi_range(2, 5)
	
	# Define constraints
	var max_w_limit = 45
	var max_h_limit = 25
	
	# --- 2. CALCULATE MAX ROOMS THAT FIT ---
	# Step size = Path + 1 Wall
	var step_size = path_thickness + 1
	
	# How many steps fit inside 45? 
	# Formula: (Limit - 1 Wall) / Step
	var max_rooms_x = (max_w_limit - 1) / step_size
	var max_rooms_y = (max_h_limit - 1) / step_size
	
	# --- 3. PICK RANDOM ROOM COUNT (WITHIN LIMITS) ---
	# We ensure we have at least 2 rooms, and no more than the max that fits.
	var rooms_x = randi_range(2, max_rooms_x)
	var rooms_y = randi_range(2, max_rooms_y)
	
	# --- 4. RECALCULATE EXACT MAP SIZE ---
	# This ensures the map is exactly the right size for the grid.
	# No remainders = No extra wide walls.
	map_width = (rooms_x * step_size) + 1
	map_height = (rooms_y * step_size) + 1
	
	# --- DEBUG PRINTS ---
	print("Path Thickness: ", path_thickness)
	print("Map Size: ", map_width, "x", map_height)
	
	# --- CONTINUE GENERATION ---
	fill_map_with_walls()
	
	# Recalculate possible rooms for the generator (should match rooms_x/y)
	var possible_rooms_x = (map_width - 1) / step_size
	var possible_rooms_y = (map_height - 1) / step_size
	
	# Pick random start
	var random_x = (randi() % possible_rooms_x) * step_size + 1
	var random_y = (randi() % possible_rooms_y) * step_size + 1
	maze_pos = Vector2i(random_x, random_y)
	
	# Dig Start
	dig_room(maze_pos, tile_v)
	
	generate_maze()
	move_player_to_start()
	spawn_movement_tiles()
	spawn_finish()
	spawn_holes()
	spawn_powerups()
	spawn_timers()

func clear_current_level():
	# 1. Clear the TileMap
	Maze.clear()
	
	# 2. Delete all spawned items (Holes, Powerups, Finish)
	# We use a group name "LevelTrash" to identify them
	get_tree().call_group("LevelTrash", "queue_free")
	
	# 3. Clear arrays
	hole_positions.clear()
	# Clear powerup_positions if you added that global array too

func fill_map_with_walls() -> void:
	for x in range(map_width):
		for y in range(map_height):
			# Check if we are on the edge
			if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
				# Paint Border
				Maze.set_cell(Vector2i(x, y), 0, tile_b)
			else:
				# Paint Inner Wall
				Maze.set_cell(Vector2i(x, y), 0, tile_n)

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
		
		if player.has_method("set_start_position"):
			player.set_start_position(start_pixel_pos)

func spawn_movement_tiles() -> void:
	var rand_x = randi() % map_width
	var rand_y = randi() % map_height
	if Maze.get_cell_atlas_coords(Vector2(rand_x, rand_y)) == tile_v:
		pass
	for x in range(map_width):
		for y in range(map_height):
			if Maze.get_cell_atlas_coords(Vector2(x, y)) == tile_v:
				var chance = randi() % 19
				if chance < 1:
					movement_tiles.set_cell(Vector2(x, y), 0, tile_v)
				else:
					movement_tiles.set_cell(Vector2(x, y), 0, tile_n)
					#movement_tiles.set_cell(Vector2(x, y), 0, tile_v)

func spawn_finish() -> void:
	if not finish_scene: return
	
	var attempts = 0
	var spawned = false
	
	while not spawned and attempts < 2000:
		attempts += 1
		
		# 1. Pick random spot
		var rand_x = randi() % map_width
		var rand_y = randi() % map_height
		var check_pos = Vector2i(rand_x, rand_y)
		
		# 2. Check if Floor
		if Maze.get_cell_atlas_coords(check_pos) == tile_v:
			
			# 3. DISTANCE CHECK (The Important Part)
			# Calculate distance from Player Start (maze_pos)
			# We want it to be at least 50% across the map
			var dist = Vector2(check_pos).distance_to(Vector2(maze_pos))
			
			# Minimum distance required (e.g., half the map width)
			var min_dist = map_width / 2
			
			if dist > min_dist:
				# --- VALID SPOT FOUND ---
				var new_finish = finish_scene.instantiate()
				
				new_finish.add_to_group("LevelTrash")
				
				# Position it
				var center_offset = Vector2(effective_tile_size / 2, effective_tile_size / 2)
				new_finish.position = (Vector2(check_pos) * effective_tile_size) + center_offset
				
				# Randomize Size (Optional)
				# new_finish.scale = Vector2(path_thickness, path_thickness) * 0.8
				
				get_parent().call_deferred("add_child", new_finish)
				
				# Save position so holes avoid it
				finish_grid_pos = check_pos
				spawned = true

	if not spawned:
		print("Warning: Could not find a far enough spot for Finish line!")

func spawn_holes() -> void:
	if not hole_scene:
		print("Error: No Hole Scene assigned!")
		return

	var holes_spawned = 0
	var step_size = path_thickness + 1
	var attempts = 0
	
	# Clear old datas
	hole_positions.clear()
	
	# Calculate how many "Rooms" exist
	var rooms_x = (map_width - 1) / step_size
	var rooms_y = (map_height - 1) / step_size

	while holes_spawned < hole_count and attempts < 2000:
		attempts += 1
		
		# 1. Pick a Random ROOM (Grid Cell), not a random pixel
		var rx = randi() % rooms_x
		var ry = randi() % rooms_y
		
		# 2. Convert Room Coordinate to Tile Coordinate
		# This gives us the top-left corner of that "room"
		var tile_x = (rx * step_size) + 1
		var tile_y = (ry * step_size) + 1
		
		# 3. Check the Center of that room
		# We add roughly half the path thickness to find the center
		var center_offset = int(path_thickness / 2)
		var check_pos = Vector2i(tile_x + center_offset, tile_y + center_offset)

		# 4. Check if it's Floor (It should be, but good to verify)
		if Maze.get_cell_atlas_coords(check_pos) != tile_v:
			continue
			
		# Avoid spawning too close to player start
		if Vector2(check_pos).distance_to(Vector2(maze_pos)) < 3:
			continue
			
		if Vector2(check_pos).distance_to(Vector2(finish_grid_pos)) < 3:
			continue
		
		# 7. Distance Check: Avoid OTHER Holes (Prevent Stacking)
		var too_close = false
		for existing in hole_positions:
			if existing == check_pos: # If a hole is already exactly here
				too_close = true
				break
		
		if too_close:
			continue

		var new_hole = hole_scene.instantiate()
		
		new_hole.add_to_group("LevelTrash")

		# Save position to array so we don't spawn here again
		hole_positions.append(check_pos)

		# Calculate pixel position for the hole
		# We use the specific check_pos which is now CENTERED in the path
		var pixel_offset = Vector2(effective_tile_size / 2, effective_tile_size / 2)
		new_hole.position = (Vector2(check_pos) * effective_tile_size) + pixel_offset
		
		# Calculate the Base Center Position (As before)
		var base_pixel_pos = (Vector2(check_pos) * effective_tile_size) + Vector2(effective_tile_size / 2, effective_tile_size / 2)
		
		# Randomize size (keep it slightly smaller than path_thickness to avoid clipping)
		var max_safe_scale = path_thickness * 0.8 # 80% of the path width
		var random_scale = randf_range(0.5, max_safe_scale)
		new_hole.scale = Vector2(random_scale, random_scale)
		
		# --- 3. Calculate "Wiggle Room" ---
		# How wide is the path in pixels?
		var path_width_px = effective_tile_size * path_thickness
		
		# How wide is the hole we just made?
		var hole_width_px = effective_tile_size * random_scale
		
		# The spare space is the difference. Divide by 2 for the radius.
		# Multiply by 0.8 to leave a small safety margin from the wall.
		var max_offset = ((path_width_px - hole_width_px) / 2) * 0.8
		
		# --- 4. Apply Random Jitter ---
		var jitter_x = randf_range(-max_offset, max_offset)
		var jitter_y = randf_range(-max_offset, max_offset)
		
		new_hole.position = base_pixel_pos + Vector2(jitter_x, jitter_y)
		
		get_parent().call_deferred("add_child", new_hole)
		holes_spawned += 1
			
	if attempts >= 2000:
		print("Warning: Could not fit all holes! Spawned ", holes_spawned, " of ", hole_count)

func spawn_powerups() -> void:
	# We will try to spawn a few powerups total (e.g. 2 or 3)
	var powerups_to_spawn = 2
	var spawned_count = 0
	var attempts = 0
	
	var powerup_positions: Array[Vector2i] = []
	
	while spawned_count < powerups_to_spawn and attempts < 2000:
		attempts += 1
		
		# 1. Pick Random Spot (Same logic as holes)
		var rand_x = randi() % map_width
		var rand_y = randi() % map_height
		var check_pos = Vector2i(rand_x, rand_y)
		
		if Maze.get_cell_atlas_coords(check_pos) == tile_v:
			# Distance check with player and finish point
			if Vector2(check_pos).distance_to(Vector2(maze_pos)) < 5: continue
			if Vector2(check_pos).distance_to(Vector2(finish_grid_pos)) < 5: continue
			
			# Distance check with holes
			var too_close_to_hole = false
			for hole_pos in hole_positions:
				# Use a safe distance (e.g. 2 or 3 tiles)
				if Vector2(check_pos).distance_to(Vector2(hole_pos)) < 1:
					too_close_to_hole = true
					break
			
			if too_close_to_hole:
				continue
			
			# Distance check with other power ups
			var too_close_to_powerup = false
			for existing_pos in powerup_positions:
				# Keep them at least 10 tiles apart (spread them out!)
				if Vector2(check_pos).distance_to(Vector2(existing_pos)) < 10:
					too_close_to_powerup = true
					break
			if too_close_to_powerup: continue
			
			# Pick Random Powerup Type
			var item_scene
			if randf() > 0.5:
				item_scene = ghost_scene # Ghost
			else:
				item_scene = wing_scene    # Wing (Make sure you assigned it!)
			
			if item_scene:
				var new_item = item_scene.instantiate()
				new_item.add_to_group("LevelTrash")
				var center_offset = Vector2(effective_tile_size / 2, effective_tile_size / 2)
				new_item.position = (Vector2(check_pos) * effective_tile_size) + center_offset
				get_parent().call_deferred("add_child", new_item)
				
				spawned_count += 1

func spawn_timers() -> void:
	if not timer_scene: return
	
	var timers_to_spawn = 2
	var spawned_count = 0
	var attempts = 0
	var timer_positions: Array[Vector2i] = [] # Local tracker to spread them out
	
	while spawned_count < timers_to_spawn and attempts < 2000:
		attempts += 1
		
		var rand_x = randi() % map_width
		var rand_y = randi() % map_height
		var check_pos = Vector2i(rand_x, rand_y)
		
		if Maze.get_cell_atlas_coords(check_pos) == tile_v:
			# 1. Distance Checks
			if Vector2(check_pos).distance_to(Vector2(maze_pos)) < 5: continue
			if Vector2(check_pos).distance_to(Vector2(finish_grid_pos)) < 5: continue
			
			# 2. Avoid Holes (Global Array)
			var too_close_to_hole = false
			for hole_pos in hole_positions:
				if Vector2(check_pos).distance_to(Vector2(hole_pos)) < 2:
					too_close_to_hole = true
					break
			if too_close_to_hole: continue
			
			# 3. Avoid Other Timers
			var too_close_to_timer = false
			for t_pos in timer_positions:
				if Vector2(check_pos).distance_to(Vector2(t_pos)) < 10:
					too_close_to_timer = true
					break
			if too_close_to_timer: continue

			# --- SPAWN ---
			var new_timer = timer_scene.instantiate()
			
			# IMPORTANT: Tag for cleanup so it deletes on level switch
			new_timer.add_to_group("LevelTrash")
			
			var center_offset = Vector2(effective_tile_size / 2, effective_tile_size / 2)
			new_timer.position = (Vector2(check_pos) * effective_tile_size) + center_offset
			
			get_parent().call_deferred("add_child", new_timer)
			
			timer_positions.append(check_pos)
			spawned_count += 1
