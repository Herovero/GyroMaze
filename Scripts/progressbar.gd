extends TextureProgressBar
# ProgressBar.gd (Node2D / Sprite2D)
func _process(_delta):
	# rotation = -get_parent().global_rotation
	global_position = get_parent().global_position - Vector2(96, 96)

	
func _ready():
	set_as_top_level(true)
