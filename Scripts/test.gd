extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var tilt_strength: float = 5000.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input_direction = Vector2.ZERO
	
	if OS.has_feature("mobile"):
		var sensor_data = Input.get_gravity()
		input_direction = Vector2(sensor_data.x, -sensor_data.y)
		input_direction = input_direction / 9.8
	else:
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var force = input_direction * tilt_strength
	apply_central_force(force)
