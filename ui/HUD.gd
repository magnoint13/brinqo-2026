extends CanvasLayer

@onready var timer_label = $UI/TimerLabel
@onready var status_label = $UI/StatusLabel
@onready var restart_button = $UI/RestartButton
@onready var menu_button = $UI/MenuButton
@onready var progress_bar = $UI/CollapseProgressBar

var max_collapse_time: float = 15.0

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	# Style the progress bar
	progress_bar.modulate = Color(1, 0.42, 0.42, 1)  # Reddish color matching timer

func _on_restart_pressed():
	GameManager.restart_current_level()

func _on_menu_pressed():
	GameManager.go_to_level_select()

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
