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

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if name == ("Settings"):
			#print("Settings")
			if tween:
				tween.kill()
			
			tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUART)
			tween.tween_property(hand, "rotation", deg_to_rad(-20), 2.0)
			
		if name == ("Play"):
			rotating = true
			hold_timer.start(3.0)

func _on_hold_timeout():
	get_tree().change_scene_to_file(next_scene)
			
func _on_body_exited(body):
	if body.is_in_group("Player"):
			if name == ("Settings"):
				if tween:
					tween.kill()
				tween = create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_QUART)
				tween.tween_property(hand, "rotation", 0.0, 2.0)
			if name == ("Play"):
				rotating = false
				hold_timer.stop()
