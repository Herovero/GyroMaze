extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
# @onready var progressbar: TextureProgressBar = $TextureProgressBar

@export var tilt_strength: float = 3000.0
@export var spin_speed: float = 0.02 # Controls how fast the visual spin is

# @onready var base_scale = sprite_2d.scale * 10

var input_enabled: bool = true
var should_reset: bool = false
var force_rotation_lock: bool = false

# Keeps track of the total distance traveled
var rolled_accumulator = Vector2.ZERO

var shader_material: ShaderMaterial

# Remember where the player should reset position to 
var current_start_pos = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_rotation = false
	shader_material = sprite_2d.material as ShaderMaterial

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
