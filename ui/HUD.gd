extends CanvasLayer

@onready var timer_label = $UI/TimerLabel
@onready var status_label = $UI/StatusLabel
@onready var restart_button = $UI/RestartButton
@onready var menu_button = $UI/MenuButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_restart_pressed():
	GameManager.restart_current_level()

func _on_menu_pressed():
	GameManager.go_to_level_select()

func set_timer_text(text: String):
	timer_label.text = text

func set_status_text(text: String, color: Color = Color.WHITE):
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

func clear_status():
	status_label.text = ""
