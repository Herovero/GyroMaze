extends Sprite2D

var maze_pos = Vector2i(0, 0)
var dir_history = []
var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var tile_n = Vector2i(0, 0)
var tile_v = Vector2i(0, 1)
var tile_s = Vector2i(1, 1)

signal done

@onready var Maze = $"../maze"

func _ready() -> void:
	Maze.set_cell(maze_pos, 0, tile_v)
	generate_maze()
	position = 16 * maze_pos + Vector2i(1, 1)

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
