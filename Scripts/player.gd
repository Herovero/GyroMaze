extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var tilt_strength: float = 2000.0 
@export var spin_speed: float = 0.02 # Controls how fast the visual spin is


var input_enabled: bool = false
var should_reset: bool = false

# Keeps track of the total distance traveled
var rolled_accumulator = Vector2.ZERO

var shader_material: ShaderMaterial

# Remember where the player should reset position to 
var current_start_pos = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	shader_material = sprite_2d.material as ShaderMaterial

func set_start_position(pos: Vector2):
	current_start_pos = pos
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var input_direction = Vector2.ZERO
	
	if OS.has_feature("mobile"):
		if input_enabled == true:
			var sensor_data = Input.get_gravity()
			input_direction = Vector2(sensor_data.x, -sensor_data.y)
			input_direction = input_direction / 5
	else:
		if input_enabled == true:
			input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") / 4
	
	var force = input_direction * tilt_strength
	apply_central_force(force)
	
	# The easy way
	rotate_marble_visuals(delta)
	
	# The hard way
	#update_rolling_shader(delta)

func update_rolling_shader(delta):
	# 1. Add the distance moved this frame to our total counter.
	# (Velocity = pixels per second. * delta = pixels moved this frame).
	rolled_accumulator += linear_velocity * delta
	
	# 2. Send this total distance to the shader
	if shader_material:
		shader_material.set_shader_parameter("roll_offset", rolled_accumulator)
		
func rotate_marble_visuals(delta):
	# 1. Get horizontal movement (Right = Clockwise, Left = Counter-Clockwise)
	var x_spin = linear_velocity.x
	
	# 2. Get vertical movement
	# Up (-Y) -> Right Spin (+Rot)
	# Down (+Y) -> Left Spin (-Rot)
	var y_spin = -linear_velocity.y
	
	# 3. Combine them
	# If moving diagonally, these might cancel out slightly, but that actually
	# looks okay (it implies sliding).
	var total_spin = (x_spin + y_spin) * spin_speed * delta
	
	sprite_2d.rotation += total_spin

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Reset player position
		#reset_position()
		
		# Reset the maze
		Global.current_level += 1
		get_tree().reload_current_scene()

# 1. Trigger the flag
func reset_position():
	should_reset = true

# 2. Handle the actual movement safely inside the physics loop
func _integrate_forces(state):
	if should_reset:
		# Teleport the body
		state.transform.origin = current_start_pos
		
		# Kill all momentum (stop it from flying)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		
		# Reset the visual rolling counter
		rolled_accumulator = Vector2.ZERO
		
		# Turn the flag off so we don't get stuck at (0,0)
		should_reset = false

func _on_timer_timeout():
	input_enabled = true
