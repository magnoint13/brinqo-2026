extends CanvasLayer

@onready var timer_label = $UI/TimerLabel
@onready var status_label = $UI/StatusLabel
@onready var menu_button = $UI/MenuButton
@onready var progress_bar = $UI/CollapseProgressBar
@onready var pause_menu = $UI/PauseMenu
@onready var rotate_button = $UI/RotateContainer/RotateButton
@onready var collapse_button = $UI/CollapseContainer/CollapseButton

var max_collapse_time: float = 15.0
var is_paused: bool = false
var can_pause: bool = true
var is_rotating: bool = false

var rotate_button_original_style: StyleBox = null
var collapse_button_original_style: StyleBox = null

func _ready():
	menu_button.pressed.connect(_on_menu_pressed)
	pause_menu.hide_pause_menu()
	progress_bar.modulate = Color(1, 0.42, 0.42, 1)
	
	# Store original styles for buttons
	if rotate_button:
		rotate_button_original_style = rotate_button.get_theme_stylebox("normal")
	if collapse_button:
		collapse_button_original_style = collapse_button.get_theme_stylebox("normal")
	
	# Setup action buttons
	collapse_button.pressed.connect(_on_collapse_pressed)
	rotate_button.button_down.connect(_on_rotate_down)
	rotate_button.button_up.connect(_on_rotate_up)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if can_pause:
			toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	if is_paused:
		pause_menu.show_pause_menu()
	else:
		pause_menu.hide_pause_menu()
	get_tree().paused = is_paused

func _on_menu_pressed():
	toggle_pause()

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

func set_game_over(disabled: bool = true):
	can_pause = not disabled

# Setup connections between buttons and game logic
func setup_action_buttons(main_node: Node):
	# Collapse button triggers collapse in main
	collapse_button.pressed.connect(main_node.trigger_collapse_manual)
	# Rotation state is read directly from button in main.handle_input()

func _on_collapse_pressed():
	# Visual state is handled by button's own pressed state
	# Action is handled by connection to main.trigger_collapse_manual
	pass

func _on_rotate_down():
	# Mouse/touch press on rotate button
	is_rotating = true
	rotate_button.button_pressed = true
	_set_button_pressed_style(rotate_button, true)

func _on_rotate_up():
	# Mouse/touch release on rotate button
	is_rotating = false
	rotate_button.button_pressed = false
	_set_button_pressed_style(rotate_button, false)

# Set visual pressed/unpressed state for buttons
func _set_button_pressed_style(button: Button, pressed: bool):
	var original_style = null
	if button == rotate_button:
		original_style = rotate_button_original_style
	elif button == collapse_button:
		original_style = collapse_button_original_style
	
	if button and original_style:
		if pressed:
			var pressed_style = button.get_theme_stylebox("pressed")
			if pressed_style:
				button.add_theme_stylebox_override("normal", pressed_style)
		else:
			button.add_theme_stylebox_override("normal", original_style)

# Public methods to set visual state from keyboard input
func set_collapse_button_visual_pressed(pressed: bool):
	_set_button_pressed_style(collapse_button, pressed)

func set_rotate_button_visual_pressed(pressed: bool):
	_set_button_pressed_style(rotate_button, pressed)
