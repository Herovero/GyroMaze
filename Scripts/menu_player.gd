extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var wing_sprite: AnimatedSprite2D = $wing_sprite

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

var inventory = ["none", "none", "none"]
@onready var slots = [$"../InGameUIs/powerup_slot1", 
					  $"../InGameUIs/powerup_slot2", 
					  $"../InGameUIs/powerup_slot3",
					 ]

@onready var maze: TileMapLayer = $"../maze"
@onready var hazard_tiles: TileMapLayer = $"../hazard_tiles"

# Power up activations
var was_inside_wall: bool = false
var wing_timer = 0.0
var is_flying: bool = false

# hazard
var hazard_fiery = Vector2i(1, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_rotation = false
	shader_material = sprite_2d.material as ShaderMaterial
	
	update_inventory_ui()

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

	var force = input_direction * tilt_strength
	apply_central_force(force)
	
	rotate_marble_visuals(delta)
	
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
	pass

func collect_powerup(powerup_type: String):
	# Logic: Find the first empty slot. If full, replace the last one.
	
	var slot_found = -1
	
	# Check Slot 0, then 1, then 2
	for i in range(3):
		if inventory[i] == "none":
			slot_found = i
			break
	
	if slot_found != -1:
		# Found an empty spot! Fill it.
		inventory[slot_found] = powerup_type
		print("Picked up: ", powerup_type)
		print("Inventory: ", inventory)
		update_inventory_ui()
		
		return true
	else:
		# return false ensures power up stay on ground 
		print("Inventory full!")
		return false

func use_item_at_index(index: int):
	var type = inventory[index]
	
	if type == "none":
		return # Empty slot, do nothing
	
	# Activate the effect
	if type == "ghost":
		activate_ghost(3)
	elif type == "wing":
		activate_wing(5.0)
		
	# Clear JUST this slot
	inventory[index] = "none"
	
	# Optional: Shift items? (e.g. Item 2 moves to Item 1?)
	# For now, let's keep it simple: Just clear the slot.
	
	update_inventory_ui()

func update_inventory_ui():
	for i in range(3):
		var type = inventory[i]
		var button_node = slots[i]
		
		if button_node.has_method("update_visuals"):
			button_node.update_visuals(type)

func activate_ghost(charges: int):
	pass

func activate_wing(duration):
	pass

func deactivate_wing():
	pass

func _on_powerup_slot_1_released():
	use_item_at_index(0)

func _on_powerup_slot_2_released():
	use_item_at_index(1)

func _on_powerup_slot_3_released():
	use_item_at_index(2)

func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
