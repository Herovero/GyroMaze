# HapticsManager.gd (Autoload or attached to a node)
extends Node

func vibrate_light():
	# 15-20ms feels like a crisp "tick" or "taptic" feedback
	Input.vibrate_handheld(15)

func vibrate_heavy():
	# 100ms+ feels like a heavy thud or notification
	Input.vibrate_handheld(150)

func vibrate_pattern():
	# You can fake a complex pattern by calling them in sequence using a Timer or Tweens
	vibrate_light()
	await get_tree().create_timer(0.1).timeout
	vibrate_heavy()
