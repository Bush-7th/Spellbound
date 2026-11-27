extends CanvasLayer

@onready var btn_up: Button = %Up_Button
@onready var btn_down: Button = %Down_Button
@onready var btn_left: Button = %Left_Button
@onready var btn_right: Button = %Right_Button
@onready var btn_jump: Button = %Jump_Button
@onready var btn_dash: Button = %Dash_Button
@onready var btn_dodge: Button = %Dodge_Button
@onready var btn_save: Button = %Apply_Button
@onready var btn_back: Button = %Back_Button
@onready var background_color_rect: ColorRect = %ColorRect

var waiting_button: Button = null
var is_over_pause: bool = false
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if background_color_rect:
		if is_over_pause:
			# Полупрозрачный фон для игры (виден геймплей)
			background_color_rect.color = Color(0, 0, 0, 0.7)
		else:
			# Почти черный фон для Главного Меню (стиль и читаемость)
			background_color_rect.color = Color(0, 0, 0, 0.95)
	_refresh_buttons_text()
	
	btn_up.pressed.connect(_on_bind_click.bind(btn_up, "up"))
	btn_down.pressed.connect(_on_bind_click.bind(btn_down, "down"))
	btn_left.pressed.connect(_on_bind_click.bind(btn_left, "left"))
	btn_right.pressed.connect(_on_bind_click.bind(btn_right, "right"))
	btn_jump.pressed.connect(_on_bind_click.bind(btn_jump, "jump"))
	btn_dash.pressed.connect(_on_bind_click.bind(btn_dash, "dash"))
	btn_dodge.pressed.connect(_on_bind_click.bind(btn_dodge, "dodge"))
	
	if btn_save: btn_save.pressed.connect(_on_save_clicked)
	if btn_back: btn_back.pressed.connect(_on_back_pressed)

func _input(event: InputEvent):
	if waiting_button != null:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				_cancel_waiting(); get_viewport().set_input_as_handled(); return
			if not event.echo:
				_set_key_for_button(waiting_button, event.keycode)
				waiting_button.text = SettingsManager.get_key_name(event.keycode)
				waiting_button.disabled = false; waiting_button = null
				get_viewport().set_input_as_handled()
	else:
		if event.is_action_pressed("ui_cancel"):
			_on_back_pressed(); get_viewport().set_input_as_handled()

func _refresh_buttons_text():
	btn_up.text = SettingsManager.get_key_name(SettingsManager.key_look_up)
	btn_down.text = SettingsManager.get_key_name(SettingsManager.key_look_down)
	btn_left.text = SettingsManager.get_key_name(SettingsManager.key_move_left)
	btn_right.text = SettingsManager.get_key_name(SettingsManager.key_move_right)
	btn_jump.text = SettingsManager.get_key_name(SettingsManager.key_jump)
	btn_dash.text = SettingsManager.get_key_name(SettingsManager.key_dash)
	btn_dodge.text = SettingsManager.get_key_name(SettingsManager.key_dodge)

func _on_bind_click(button: Button, action_name: String):
	if waiting_button != null and waiting_button != button: _cancel_waiting()
	waiting_button = button
	button.text = "...нажмите клавишу..." if SettingsManager.current_language == "ru" else "...press key..."
	button.disabled = true

func _get_current_key_for_button(button: Button) -> int:
	if button == btn_up: return SettingsManager.key_look_up
	if button == btn_down: return SettingsManager.key_look_down
	if button == btn_left: return SettingsManager.key_move_left
	if button == btn_right: return SettingsManager.key_move_right
	if button == btn_jump: return SettingsManager.key_jump
	if button == btn_dash: return SettingsManager.key_dash
	if button == btn_dodge: return SettingsManager.key_dodge
	return KEY_NONE

func _set_key_for_button(button: Button, key_code: int):
	if button == btn_up: SettingsManager.key_look_up = key_code
	elif button == btn_down: SettingsManager.key_look_down = key_code
	elif button == btn_left: SettingsManager.key_move_left = key_code
	elif button == btn_right: SettingsManager.key_move_right = key_code
	elif button == btn_jump: SettingsManager.key_jump = key_code
	elif button == btn_dash: SettingsManager.key_dash = key_code
	elif button == btn_dodge: SettingsManager.key_dodge = key_code

func _cancel_waiting():
	if waiting_button != null:
		waiting_button.text = SettingsManager.get_key_name(_get_current_key_for_button(waiting_button))
		waiting_button.disabled = false; waiting_button = null

func _on_save_clicked():
	_cancel_waiting(); SettingsManager.save_controls(); SettingsManager.load_controls(); queue_free()

func _on_back_pressed():
	_cancel_waiting(); queue_free()
