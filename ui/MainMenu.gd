extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var level_select_button = $VBoxContainer/LevelSelectButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	GameManager.start_level(1)

func _on_level_select_pressed():
	GameManager.go_to_level_select()

func _on_quit_pressed():
	get_tree().quit()
