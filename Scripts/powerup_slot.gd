extends TouchScreenButton

@onready var animation: AnimationPlayer = $AnimationPlayer

var current_type: String = "none"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#animation.play("RESET")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_visuals(type: String):
	#if not animation:
		#print("Error: AnimationPlayer not found on ", name)
		#return
		
	# If the new type is the same as what we already have, DO NOTHING.
	if type == current_type:
		return
		
	current_type = type
	
	if type == "none":
		animation.play("RESET")
		
	elif type == "ghost":
		animation.play("ghost")
		
	elif type == "wing":
		animation.play("wing")
