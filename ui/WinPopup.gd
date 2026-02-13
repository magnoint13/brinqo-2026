extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var level_label: Label = $CenterContainer/VBoxContainer/LevelLabel
@onready var main_menu_button: Button = $CenterContainer/VBoxContainer/MainMenuButton
@onready var next_level_button: Button = $CenterContainer/VBoxContainer/NextLevelButton
@onready var restart_level_button: Button = $CenterContainer/VBoxContainer/RestartLevelButton
@onready var confetti1 = $GPUParticles2D
@onready var confetti2 = $GPUParticles2D2

var current_level: int = 1

func _ready():
	confetti1.emitting = false
	confetti2.emitting = true
	visible = false
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	restart_level_button.pressed.connect(_on_restart_level_pressed)

func show_win_popup(level_number: int):
	modulate.a = 0
	visible = true
	current_level = level_number
		
	# Update level text
	level_label.text = tr("LEVEL_BUTTON_PREFIX") + " " + str(current_level)
	
	# Check if this is the last level
	var next_level = current_level + 1
	if next_level > GameManager.TOTAL_LEVELS:
		# This is the final level
		next_level_button.text = tr("GAME_COMPLETE")
		next_level_button.disabled = true
		title_label.text = tr("GAME_COMPLETE_TITLE")
	else:
		next_level_button.text = tr("NEXT_LEVEL")
		next_level_button.disabled = false
		title_label.text = tr("LEVEL_COMPLETE")
	
	# Pause the game
	get_tree().paused = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.6)
	tween.tween_callback(func():
		confetti1.emitting = true
		confetti2.emitting = true
	)

func hide_win_popup():
	visible = false

func _on_main_menu_pressed():
	hide_win_popup()
	get_tree().paused = false
	GameManager.go_to_main_menu()

func _on_next_level_pressed():
	hide_win_popup()
	get_tree().paused = false
	var next_level = current_level + 1
	if next_level <= GameManager.TOTAL_LEVELS:
		GameManager.start_level(next_level)
		
func _on_restart_level_pressed():
	hide_win_popup()
	get_tree().paused = false
	GameManager.restart_current_level()
