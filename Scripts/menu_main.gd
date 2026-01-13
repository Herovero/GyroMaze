extends CanvasLayer

@onready var info_button := $InfoButton
@onready var info_popup := $InfoPopup
@onready var close_button := $InfoPopup/PopupPanel/CloseButton
@onready var menu_bgm = $"../BGM/menu_bgm"

func _ready():
	
	info_popup.visible = false
	info_button.pressed.connect(_on_info_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_info_pressed():
	info_popup.visible = !info_popup.visible

func _on_close_pressed():
	info_popup.visible = false
