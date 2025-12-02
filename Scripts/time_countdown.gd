extends Label

@onready var timer: Timer = $"../Timer"
@onready var time_countdown: Label = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_countdown.text = str(int(timer.time_left + 1))
	await get_tree().create_timer(3).timeout
	time_countdown.hide()
