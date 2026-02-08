extends Control

const TOTAL_LEVELS: int = 5

@onready var grid_container = $GridContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	create_level_buttons()

func create_level_buttons():
	for level_num in range(1, TOTAL_LEVELS + 1):
		var button = Button.new()
		button.text = "Level " + str(level_num)
		button.custom_minimum_size = Vector2(150, 60)
		
		if GameManager.is_level_unlocked(level_num):
			button.pressed.connect(func(): _on_level_pressed(level_num))
		else:
			button.disabled = true
			button.modulate = Color(0.3, 0.3, 0.3)
		
		grid_container.add_child(button)

func _on_level_pressed(level_number: int):
	GameManager.start_level(level_number)

func _on_back_pressed():
	GameManager.go_to_main_menu()
