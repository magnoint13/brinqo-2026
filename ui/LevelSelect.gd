extends Control

const TOTAL_LEVELS = GameManager.TOTAL_LEVELS
const THEME = preload("res://resources/Default.tres") as Theme
const THEME_HIGHLIGHT = preload("res://resources/Default2.tres") as Theme

@onready var grid_container = $GridContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	create_level_buttons()

func create_level_buttons():
	var last_level_unlocked = GameManager.unlocked_levels.max()
	for level_num in range(1, TOTAL_LEVELS + 1):
		var button = Button.new()
		button.text = tr("LEVEL_BUTTON_PREFIX") + " " + str(level_num)
		button.custom_minimum_size = Vector2(150, 60)
		
		if GameManager.is_level_unlocked(level_num):
			button.pressed.connect(func(): _on_level_pressed(level_num))
			if level_num == last_level_unlocked:
				button.theme = THEME_HIGHLIGHT
			else:
				button.theme = THEME
		else:
			button.disabled = true
			button.modulate = Color(0.3, 0.3, 0.3)
		
		grid_container.add_child(button)

func _on_level_pressed(level_number: int):
	GameManager.start_level(level_number)

func _on_back_pressed():
	GameManager.go_to_main_menu()
