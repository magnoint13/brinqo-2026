extends CanvasLayer

@onready var timer_label = $UI/TimerLabel
@onready var status_label = $UI/StatusLabel
@onready var restart_button = $UI/RestartButton
@onready var menu_button = $UI/MenuButton
@onready var progress_bar = $UI/CollapseProgressBar
@onready var pause_menu = $UI/PauseMenu
@onready var resume_button = $UI/PauseMenu/CenterContainer/VBoxContainer/ResumeButton
@onready var pause_restart_button = $UI/PauseMenu/CenterContainer/VBoxContainer/RestartButton2
@onready var level_select_button = $UI/PauseMenu/CenterContainer/VBoxContainer/LevelSelectButton
@onready var main_menu_button = $UI/PauseMenu/CenterContainer/VBoxContainer/MainMenuButton

var max_collapse_time: float = 15.0
var is_paused: bool = false

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_restart_button.pressed.connect(_on_pause_restart_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	# Style the progress bar
	progress_bar.modulate = Color(1, 0.42, 0.42, 1)  # Reddish color matching timer

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

func _on_restart_pressed():
	GameManager.restart_current_level()

func _on_menu_pressed():
	toggle_pause()

func _on_resume_pressed():
	toggle_pause()

func _on_pause_restart_pressed():
	get_tree().paused = false
	GameManager.restart_current_level()

func _on_level_select_pressed():
	get_tree().paused = false
	GameManager.go_to_level_select()

func _on_main_menu_pressed():
	get_tree().paused = false
	GameManager.go_to_main_menu()

func set_timer_text(text: String):
	timer_label.text = text

func set_collapse_progress(time_left: float, max_time: float):
	# Update progress bar (1.0 = full, 0.0 = empty)
	var progress = time_left / max_time
	progress_bar.value = progress
	
	# Change color based on urgency
	if progress > 0.5:
		progress_bar.modulate = Color(0.3, 1, 0.3, 1)  # Green when plenty of time
	elif progress > 0.25:
		progress_bar.modulate = Color(1, 1, 0.3, 1)   # Yellow when getting close
	else:
		progress_bar.modulate = Color(1, 0.3, 0.3, 1)  # Red when urgent

func reset_progress_bar():
	progress_bar.value = 1.0
	progress_bar.modulate = Color(0.3, 1, 0.3, 1)

func hide_progress_bar():
	progress_bar.visible = false

func show_progress_bar():
	progress_bar.visible = true

func set_status_text(text: String, color: Color = Color.WHITE):
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

func clear_status():
	status_label.text = ""
