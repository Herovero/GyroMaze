extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var wing_sprite: AnimatedSprite2D = $wing_sprite


@export var tilt_strength: float = 2000.0 
@export var spin_speed: float = 0.02 # Controls how fast the visual spin is

@onready var base_scale = sprite_2d.scale

var input_enabled: bool = false
var should_reset: bool = false
var force_rotation_lock: bool = false

# Keeps track of the total distance traveled
var rolled_accumulator = Vector2.ZERO

var shader_material: ShaderMaterial

# Remember where the player should reset position to 
var current_start_pos = Vector2.ZERO

# Power up activations
@onready var maze: TileMapLayer = $"../maze"
var ghost_charges = 0
var was_inside_wall: bool = false

var wing_timer = 0.0
var is_flying: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_rotation = false
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
	
	if ghost_charges > 0:
		handle_ghost_logic()
	
	if is_flying:
		wing_timer -= delta
		if wing_timer <= 0:
			deactivate_wing()

func update_rolling_shader(delta):
	# 1. Add the distance moved this frame to our total counter.
	# (Velocity = pixels per second. * delta = pixels moved this frame).
	rolled_accumulator += linear_velocity * delta
	
	# 2. Send this total distance to the shader
	if shader_material:
		shader_material.set_shader_parameter("roll_offset", rolled_accumulator)
		
func rotate_marble_visuals(delta):
	if is_flying:
		return
		
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
	if is_flying:
		return
		
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
	
	if force_rotation_lock:
		# 1. Kill any spinning momentum instantly
		state.angular_velocity = 0
		
		# 2. Force the rotation angle to 0 (Upright)
		# This overrides any collision that tried to tilt you this frame
		var new_transform = state.transform
		new_transform.x = Vector2(1, 0) # X axis points Right
		new_transform.y = Vector2(0, 1) # Y axis points Down
		state.transform = new_transform

func _on_timer_timeout():
	input_enabled = true

func activate_ghost(charges: int):
	ghost_charges = charges
	was_inside_wall = false
	
	# Disable collision with walls
	collision_mask = 0 
	
	# Visual Cue: Make player semi-transparent
	modulate.a = 0.5
	print("Ghost Mode Activated! Charges: ", ghost_charges)

func handle_ghost_logic():
	# Convert global position to local since maze scale is 9.0
	var local_pos = maze.to_local(global_position)
	
	# Get the tile coordinate under the player
	var tile_pos = maze.local_to_map(local_pos)
	#print(tile_pos)
	
	# 2. Check what kind of tile is there (Layer 0)
	var tile_atlas_coords = maze.get_cell_atlas_coords(tile_pos)
	#print(tile_atlas_coords)
	
	# Based on your mazegen script: Wall is (0,0), Floor is (0,1)
	var is_wall = (tile_atlas_coords == Vector2i(0, 0))
	
	if is_wall:
		# We are currently inside a wall
		was_inside_wall = true
	else:
		# We are currently on the floor
		if was_inside_wall:
			# We JUST exited a wall! Consumed 1 charge.
			ghost_charges -= 1
			was_inside_wall = false
			print("Passed through wall! Charges left: ", ghost_charges)
			
			# If we ran out of charges, turn solid again
			if ghost_charges <= 0:
				ghost_charges = 0
				collision_mask = 1 # Reset to default (Collide with Walls/Layer 1)
				modulate.a = 1.0 # Fully opaque
				print("Ghost Mode Deactivated")

func activate_wing(duration):
	is_flying = true
	wing_timer = duration
	wing_sprite.show()
	
	force_rotation_lock = true
	sprite_2d.rotation = 0
	
	print("Wing Activated! Flying for ", duration, "s")

func deactivate_wing():
	is_flying = false
	wing_sprite.hide()
	
	force_rotation_lock = false
	
	print("Wing Deactivated")
