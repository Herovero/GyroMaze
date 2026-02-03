extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
# @onready var progressbar: TextureProgressBar = $TextureProgressBar

@export var limit_camera: Camera2D

@export var tilt_strength: float = 3000.0
@export var spin_speed: float = 0.02 # Controls how fast the visual spin is

@onready var game_logo = $"../InGameUIs/GameLogo"
var logo_start_pos: Vector2 = Vector2.ZERO
@export var logo_offset_amount: float = 100.0 # How many pixels it moves
@export var logo_smooth_speed: float = 5.0   # How fast it floats back

# @onready var base_scale = sprite_2d.scale * 10

var input_enabled: bool = true
var should_reset: bool = false
var force_rotation_lock: bool = false

# Keeps track of the total distance traveled
var rolled_accumulator = Vector2.ZERO

var shader_material: ShaderMaterial

# Remember where the player should reset position to 
var current_start_pos = Vector2.ZERO

# Screen Boundary Variable
var player_radius: float = 32.0

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_rotation = false
	shader_material = sprite_2d.material as ShaderMaterial
	
	if game_logo:
		logo_start_pos = game_logo.position

func set_start_position(pos: Vector2):
	current_start_pos = pos
	
	should_reset = true
	# Kill any existing movement immediately
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
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
		linear_damp = 1.0

	var force = input_direction * tilt_strength * Global.input_sensitivity
	apply_central_force(force)
	
	rotate_marble_visuals(delta)
	
	# --- 2. ANIMATE THE LOGO ---
	if game_logo:
		# Calculate where the logo WANTS to be based on tilt
		# We multiply input_direction by our offset amount
		var target_pos = logo_start_pos + (input_direction * logo_offset_amount)
		
		# Smoothly move the logo to that position (Linear Interpolation)
		# This ensures it slides back gently when you stop tilting
		game_logo.position = game_logo.position.lerp(target_pos, delta * logo_smooth_speed)

func _integrate_forces(state):
	# 1. Guard: If no camera is assigned, do nothing (or fallback)
	if limit_camera == null:
		return

	# 2. Calculate the World Size visible to the camera
	# We take the window size (pixels) and divide by zoom to get "World Units"
	var viewport_size = get_viewport_rect().size
	var world_visible_size = viewport_size / limit_camera.zoom
	
	# 3. Get Camera Center
	# get_screen_center_position() is safer than global_position because it accounts for anchors
	var cam_center = limit_camera.get_screen_center_position()
	
	# 4. Calculate Boundaries (Left, Right, Top, Bottom)
	var min_x = cam_center.x - (world_visible_size.x / 2.0) + player_radius
	var max_x = cam_center.x + (world_visible_size.x / 2.0) - player_radius
	var min_y = cam_center.y - (world_visible_size.y / 2.0) + player_radius
	var max_y = cam_center.y + (world_visible_size.y / 2.0) - player_radius
	
	# 5. Clamp Position
	var xform = state.transform
	var pos = xform.origin
	
	var clamped_x = clamp(pos.x, min_x, max_x)
	var clamped_y = clamp(pos.y, min_y, max_y)
	
	# 6. Apply Correction
	if pos.x != clamped_x:
		xform.origin.x = clamped_x
		state.linear_velocity.x = 0 # Kill momentum into the wall
		
	if pos.y != clamped_y:
		xform.origin.y = clamped_y
		state.linear_velocity.y = 0 # Kill momentum into the wall
		
	state.transform = xform
	
	# Reset Logic
	if should_reset:
		state.transform.origin = current_start_pos
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		should_reset = false

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

func _input(_event):
	pass

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.

func _on_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
