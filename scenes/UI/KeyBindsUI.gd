extends Control

# --- Ссылки на кнопки (уникальные имена через %) ---
@onready var btn_up: Button = %Up_Button
@onready var btn_left: Button = %Left_Button
@onready var btn_down: Button = %Down_Button
@onready var btn_right: Button = %Right_Button
@onready var btn_jump: Button = %Jump_Button
@onready var btn_dash: Button = %Dash_Button
@onready var btn_save: Button = %Apply_Button
@onready var btn_dodge: Button = %Dodge_Button

# Состояние: какую кнопку мы сейчас ждём от пользователя
var waiting_button: Button = null


func _ready():
	# 1. Показываем текущие клавиши на кнопках
	_refresh_buttons_text()
	
	# 2. Подключаем кнопки привязки через Callable.bind()
	btn_up.pressed.connect(_on_bind_click.bind(btn_up, "up"))
	btn_down.pressed.connect(_on_bind_click.bind(btn_down, "down"))
	btn_left.pressed.connect(_on_bind_click.bind(btn_left, "left"))
	btn_right.pressed.connect(_on_bind_click.bind(btn_right, "right"))
	btn_jump.pressed.connect(_on_bind_click.bind(btn_jump, "jump"))
	btn_dash.pressed.connect(_on_bind_click.bind(btn_dash, "dash"))
	btn_dodge.pressed.connect(_on_bind_click.bind(btn_dodge, "dodge"))
	
	# 3. Подключаем кнопку сохранения
	btn_save.pressed.connect(_on_save_clicked)


# Виртуальная функция Godot для глобального перехвата ввода
func _input(event: InputEvent):
	if waiting_button == null:
		return
	
	# Нажат ESC — отменяем ожидание
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_waiting()
		get_viewport().set_input_as_handled()
		return
	
	# Нас интересуют только нажатия клавиш (не отпускания, не автоповтор)
	if event is InputEventKey and event.pressed and not event.echo:
		var new_key = event.keycode
		
		# Записываем новую клавишу в менеджер
		_set_key_for_button(waiting_button, new_key)
		
		# Обновляем текст кнопки
		waiting_button.text = SettingsManager.get_key_name(new_key)
		
		# Сбрасываем состояние ожидания
		waiting_button.disabled = false
		waiting_button = null
		
		# Помечаем событие как обработанное
		get_viewport().set_input_as_handled()


# Обновляет текст на всех кнопках привязки
func _refresh_buttons_text():
	btn_up.text = SettingsManager.get_key_name(SettingsManager.key_look_up)
	btn_down.text = SettingsManager.get_key_name(SettingsManager.key_look_down)
	btn_left.text = SettingsManager.get_key_name(SettingsManager.key_move_left)
	btn_right.text = SettingsManager.get_key_name(SettingsManager.key_move_right)
	btn_jump.text = SettingsManager.get_key_name(SettingsManager.key_jump)
	btn_dash.text = SettingsManager.get_key_name(SettingsManager.key_dash)
	btn_dodge.text = SettingsManager.get_key_name(SettingsManager.key_dodge)


# Вызывается при клике на кнопку привязки
func _on_bind_click(button: Button, action_name: String):
	# Если уже ждём ввод на другой кнопке — отменяем предыдущее ожидание
	if waiting_button != null and waiting_button != button:
		waiting_button.text = SettingsManager.get_key_name(
			_get_current_key_for_button(waiting_button)
		)
		waiting_button.disabled = false
	
	# Начинаем ждать ввод на этой кнопке
	waiting_button = button
	if SettingsManager.current_language == "en":
		button.text = "...press the button..."
	else:
		button.text = "...нажмите клавишу..."
		
	button.disabled = true


# Возвращает текущий код клавиши для конкретной кнопки
func _get_current_key_for_button(button: Button) -> int:
	if button == btn_up: return SettingsManager.key_look_up
	if button == btn_down: return SettingsManager.key_look_down
	if button == btn_left: return SettingsManager.key_move_left
	if button == btn_right: return SettingsManager.key_move_right
	if button == btn_jump: return SettingsManager.key_jump
	if button == btn_dash: return SettingsManager.key_dash
	if button == btn_dodge: return SettingsManager.key_dodge
	return KEY_NONE


# Записывает новую клавишу в менеджер для конкретной кнопки
func _set_key_for_button(button: Button, key_code: int):
	if button == btn_up: SettingsManager.key_look_up = key_code
	elif button == btn_down: SettingsManager.key_look_down = key_code
	elif button == btn_left: SettingsManager.key_move_left = key_code
	elif button == btn_right: SettingsManager.key_move_right = key_code
	elif button == btn_jump: SettingsManager.key_jump = key_code
	elif button == btn_dash: SettingsManager.key_dash = key_code
	elif button == btn_dodge: SettingsManager.key_dodge = key_code

# Отмена ожидания ввода (например, по ESC)
func _cancel_waiting():
	if waiting_button != null:
		waiting_button.text = SettingsManager.get_key_name(
			_get_current_key_for_button(waiting_button)
		)
		waiting_button.disabled = false
		waiting_button = null


# Кнопка "Применить" — сохраняем и выходим
func _on_save_clicked():
	_cancel_waiting()
	SettingsManager.save_controls()
	get_tree().change_scene_to_file("res://scenes/UI/settings.tscn")
