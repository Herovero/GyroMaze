extends TextureRect

# --- DRAG YOUR IMAGES HERE IN INSPECTOR ---
@export_group("Stamp Assets")
@export var tex_plot_armor: Texture2D   # Don't die at all
@export var tex_maidenless: Texture2D   # Die too many times
@export var tex_bankrupt: Texture2D     # Too few coins
@export var tex_stonks: Texture2D       # Too many coins
@export var tex_git_gud: Texture2D      # Beat too few levels
@export var tex_touch_grass: Texture2D  # Beat too many levels
@export var tex_mid: Texture2D          # Fallback (Average run)

# --- BALANCE SETTINGS (TWEAK THESE) ---
@export_group("Thresholds")
@export var limit_levels_high: int = 25
@export var limit_levels_low: int = 5
@export var limit_coins_high: int = 100
@export var limit_coins_low: int = 20
@export var limit_deaths_high: int = 20

@onready var stamp_sfx = $"../../../SFX & BGM/stamp"

func _ready():
	pass
	#visible = false

func apply_stamp(run_data: Dictionary):
	# Expected run_data format: { "deaths": 0, "level": 12, "coins": 150 }
	stamp_sfx.play()
	visible = true
	var chosen_texture = tex_mid # Default to "Mid" if nothing else matches
	
	# --- PRIORITY 1: LEGENDARY FEATS (Overrides everything) ---
	
	# "PLOT ARMOR" (Zero Deaths & reasonable progress)
	if run_data["deaths"] == 0 and run_data["level"] > limit_levels_low:
		chosen_texture = tex_plot_armor
		
	# "GO TOUCH GRASS" (Reached an insane level)
	elif run_data["level"] >= limit_levels_high:
		chosen_texture = tex_touch_grass

	# --- PRIORITY 2: ECONOMY (Specific playstyles) ---
	
	# "STONKS" (Got rich)
	elif run_data["coins"] >= limit_coins_high:
		chosen_texture = tex_stonks
		
	# "BANKRUPT" (Played for a while but barely got coins)
	elif run_data["coins"] < limit_coins_low and run_data["level"] > limit_levels_low:
		chosen_texture = tex_bankrupt

	# --- PRIORITY 3: FAILURES (If nothing else special happened) ---
	
	# "MAIDENLESS" (Died way too much)
	elif run_data["deaths"] >= limit_deaths_high:
		chosen_texture = tex_maidenless

	# "GIT GUD" (Barely made it past the start)
	elif run_data["level"] < limit_levels_low:
		chosen_texture = tex_git_gud
		
	# --- APPLY VISUALS ---
	texture = chosen_texture
	
	# Run the "Slam" animation
	animate_slam()

func animate_slam():
	# Reset scale to big
	scale = Vector2(2.5, 2.5)
	modulate.a = 0.0
	
	rotation_degrees = -15.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Slam down to normal size
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.4)
	# Fade in instantly
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
