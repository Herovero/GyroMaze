extends Area2D

@export var next_scene: String = "res://Scenes/main.tscn"
@onready var sprite = $Sprite2D
@onready var hand = $Hand
@onready var hold_timer: Timer = $Timer
var rpm := 1.0
var rotating = false
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hold_timer.timeout.connect(_on_hold_timeout)
	if name == ("Play"):
		sprite.rotation = deg_to_rad(-45)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	rpm = 6.5 if rotating else 1.0 # play button
	if name == ("Play"):
		sprite.rotation += (2.0 * PI * rpm) / 60.0 * _delta
	if name == ("Settings"):
		hand.rotation = deg_to_rad(30)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if name == ("Settings"):
			print("Settings")
		if name == ("Play"):
			rotating = true
			print("Play")
			hold_timer.start(3.0)

func _on_hold_timeout():
	get_tree().change_scene_to_file(next_scene)
			
func _on_body_exited(body):
	if body.is_in_group("Player"):
		rotating = false
	hold_timer.stop()
