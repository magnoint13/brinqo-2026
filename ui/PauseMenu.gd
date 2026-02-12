extends Control

@onready var resume_button: Button = $ResumeButton
@onready var restart_button: Button = $RestartButton
@onready var level_select_button: Button = $LevelSelectButton
@onready var settings_button: Button = $SettingsButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var settings_menu: Control = $SettingsMenu

func _ready():
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func show_pause_menu():
	visible = true
	settings_menu.visible = false

func hide_pause_menu():
	visible = false

func _on_resume_pressed():
	hide_pause_menu()
	get_tree().paused = false

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_level_select_pressed():
	get_tree().paused = false
	GameManager.go_to_level_select()

func _on_settings_pressed():
	settings_menu.open("pause_menu", true)

func _on_main_menu_pressed():
	get_tree().paused = false
	GameManager.go_to_main_menu()
