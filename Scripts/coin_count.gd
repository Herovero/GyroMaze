extends Label

var coin: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	text = "0"
	SignalBus.connect("collect_coin", _on_coin_collected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_coin_collected():
	coin += 1
	text = str(coin)
