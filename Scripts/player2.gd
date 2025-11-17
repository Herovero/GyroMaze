extends CharacterBody2D

@onready var player: CharacterBody2D = $"."

var speed = 100.0

func _physics_process(delta):
	if Input.is_action_just_pressed("restart"):
		print("wdqq")
		
	var accelerationRate = Input.get_accelerometer()
	
	# 1. Set the built-in 'velocity' property
	velocity = Vector2(accelerationRate.x, accelerationRate.y) * speed
	
	# 2. Call move_and_slide() with NO arguments
	move_and_slide()

func reset_position():
	print("wdq")
	global_position = Vector2(0, 0)
