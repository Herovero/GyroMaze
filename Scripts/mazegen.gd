extends Node2D

const WALL_N = 1 << 3  # 1000
const WALL_S = 1 << 2  # 0100
const WALL_W = 1 << 1  # 0010
const WALL_E = 1 << 0  # 0001

var maze_pos = Vector2i(0, 0)
var dir_history = []
var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var maze_size = Vector2i(21, 21)  # must be odd numbers
var maze_data = []

signal done

func _ready() -> void:
	init_maze()
	set_process(true)

func init_maze() -> void:
	# initialize all cells with all walls
	maze_data.resize(maze_size.x)
	for x in maze_size.x:
		maze_data[x] = []
		for y in maze_size.y:
			maze_data[x].append(WALL_N | WALL_S | WALL_W | WALL_E)

func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < maze_size.x and pos.y >= 0 and pos.y < maze_size.y

func get_neighbors() -> Array:
	var dlist = []
	for dir in directions:
		var next_pos = maze_pos + dir * 2
		if is_inside(next_pos) and maze_data[next_pos.x][next_pos.y] == (WALL_N | WALL_S | WALL_W | WALL_E):
			dlist.append(dir)
	return dlist

func carve(dir: Vector2i) -> void:
	var next_pos = maze_pos + dir * 2
	var wall_pos = maze_pos + dir  # intermediate cell between current and next

	match dir:
		Vector2i.UP:
			maze_data[maze_pos.x][maze_pos.y] &= ~WALL_N
			maze_data[next_pos.x][next_pos.y] &= ~WALL_S
		Vector2i.DOWN:
			maze_data[maze_pos.x][maze_pos.y] &= ~WALL_S
			maze_data[next_pos.x][next_pos.y] &= ~WALL_N
		Vector2i.LEFT:
			maze_data[maze_pos.x][maze_pos.y] &= ~WALL_W
			maze_data[next_pos.x][next_pos.y] &= ~WALL_E
		Vector2i.RIGHT:
			maze_data[maze_pos.x][maze_pos.y] &= ~WALL_E
			maze_data[next_pos.x][next_pos.y] &= ~WALL_W

	# optional: remove wall cell between (intermediate)
	maze_data[wall_pos.x][wall_pos.y] = 0

	maze_pos = next_pos

func _process(delta: float) -> void:
	var dlist = get_neighbors()
	if dlist.is_empty():
		if dir_history.is_empty():
			print("Maze generation completed")
			done.emit()
			set_process(false)
			return
		# backtrack
		var removed_dir = dir_history.pop_back()
		maze_pos -= removed_dir * 2
	else:
		var dir = dlist.pick_random()
		carve(dir)
		dir_history.append(dir)
