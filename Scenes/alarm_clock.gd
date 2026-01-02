extends AnimatedSprite2D

@onready var times_up = $"../../SFX/times_up"
@onready var player = $"../../Player"
@onready var panel = $"../Panel"
@onready var powerup_slot_1 = $"../powerup_slot1"
@onready var powerup_slot_2 = $"../powerup_slot2"
@onready var powerup_slot_3 = $"../powerup_slot3"
@onready var pause_button = $"../PauseButton"
@onready var resume_button = $"../ResumeButton"
@onready var reset_button = $"../ResetButton"
@onready var zoom_out_button = $"../ZoomOutButton"
@onready var coin_hud = $"../coin_HUD"
@onready var time_remaining_hud = $"../time_remaining_hud"
@onready var time_remaining = $"../time_remaining"
@onready var level_count = $"../level_count"
@onready var coin_count = $"../coin_count"

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
	SignalBus.connect("times_up", _on_times_up)
	
	visible = false

func _on_times_up():
	player.input_enabled = false
	player.visible = false
	panel.visible = false
	powerup_slot_1.visible = false
	powerup_slot_2.visible = false
	powerup_slot_3.visible = false
	pause_button.visible = false
	resume_button.visible = false
	reset_button.visible = false
	zoom_out_button.visible = false
	coin_hud.visible = false
	time_remaining_hud.visible = false
	time_remaining.visible = false
	level_count.visible = false
	coin_count.visible = false
	visible = true
	play()
	times_up.play()
