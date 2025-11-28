extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var tilt_strength: float = 5000.0

var should_reset = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input_direction = Vector2.ZERO
	
	if OS.has_feature("mobile"):
		var sensor_data = Input.get_gravity()
		input_direction = Vector2(sensor_data.x, -sensor_data.y)
		input_direction = input_direction / 4.9
	else:
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") / 4
	
	var force = input_direction * tilt_strength
	apply_central_force(force)

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		reset_position()
	elif event.is_action_pressed("ui_accept"):
		reset_position()

# 1. Trigger the flag
func reset_position():
	should_reset = true

# 2. Handle the actual movement safely inside the physics loop
func _integrate_forces(state):
	if should_reset:
		# Teleport the body
		state.transform.origin = Vector2(0, 0)
		
		# Kill all momentum (stop it from flying)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		
		# Turn the flag off so we don't get stuck at (0,0)
		should_reset = false
