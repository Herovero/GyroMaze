extends TouchScreenButton

@onready var animation: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_visuals(type: String):
	if type == "none":
		pass
		#animation.play("RESET")
		
	elif type == "ghost":
		visible = true
		animation.play("ghost")
		
	elif type == "wing":
		visible = true
		animation.play("wing")
