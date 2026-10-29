extends Control

# Ссылки на элементы UI (назначьте их в инспекторе или через @onready)
@onready var volume_slider: HSlider = %Volume_HSlider
@onready var vsync_checkbox: CheckBox = %VSync_CheckBox
@onready var fullscreen_checkbox: CheckBox = %FullScreen_CheckBox
@onready var Apply_button: Button = %Apply_Button
@onready var en_button: Button = %EN_Button
@onready var ru_button: Button = %RU_Button

# Временные переменные для хранения изменений (до нажатия "Сохранить")
var temp_volume: float
var temp_vsync: int
var temp_fullscreen: bool
var temp_language: String = "ru"

func _ready():
	# Загружаем текущие настройки во временные переменные
	_load_temp_settings()
	
	# Обновляем UI из временных переменных
	_refresh_ui()
	
	# Подключаем сигналы
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	vsync_checkbox.toggled.connect(_on_vsync_checkbox_toggled)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_checkbox_toggled)
	Apply_button.pressed.connect(_on_save_pressed)
	en_button.pressed.connect(_on_en_button_pressed)
	ru_button.pressed.connect(_on_ru_button_pressed)


# Загружаем текущие настройки из SettingsManager во временные переменные
func _load_temp_settings():
	temp_volume = SettingsManager.master_volume
	temp_vsync = SettingsManager.vsync_mode
	temp_fullscreen = SettingsManager.fullscreen_mode
	temp_language = SettingsManager.current_language

# Обновляем UI из временных переменных
func _refresh_ui():
	volume_slider.value = temp_volume
	vsync_checkbox.button_pressed = (temp_vsync != DisplayServer.VSYNC_DISABLED)
	fullscreen_checkbox.button_pressed = temp_fullscreen
	_update_language_buttons()

# Обработчики изменений в UI (обновляем только временные переменные)
func _on_volume_slider_value_changed(value: float):
	temp_volume = value


func _on_vsync_checkbox_toggled(toggled_on: bool):
	if toggled_on:
		temp_vsync = DisplayServer.VSYNC_ENABLED
	else:
		temp_vsync = DisplayServer.VSYNC_DISABLED


func _on_fullscreen_checkbox_toggled(toggled_on: bool):
	temp_fullscreen = toggled_on


# Кнопка "Сохранить" - применяем и сохраняем настройки
func _on_save_pressed():
	# Передаем значения из временных переменных в SettingsManager
	SettingsManager.master_volume = temp_volume
	SettingsManager.vsync_mode = temp_vsync
	SettingsManager.fullscreen_mode = temp_fullscreen
	SettingsManager.current_language = temp_language
	
	# Применяем настройки к движку
	SettingsManager.apply_settings()
	
	# Сохраняем в файл
	SettingsManager.save_settings()


func _on_key_binds_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/key_binds_menu.tscn")
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")

func _on_en_button_pressed():
	temp_language = "en"
	_update_language_buttons()
	
func _on_ru_button_pressed():
	temp_language = "ru"
	_update_language_buttons()
	
func _update_language_buttons():
	if temp_language == "ru":
		_apply_blue_style(ru_button)
		_apply_gray_style(en_button)
	else:
		_apply_blue_style(en_button)
		_apply_gray_style(ru_button)
	# НОВОЕ: Функции применения стилей
func _apply_blue_style(btn: Button):
	# --- Normal (Обычный) ---
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#ff007f") # Синий
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	
	# --- Hover (Наведение) ---
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#ff4da6") # Светлее синий
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	# Применяем только два состояния. Pressed будет использовать Hover или Normal.
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal) # При нажатии остается светлым
	btn.add_theme_stylebox_override("focused", style_normal)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)


func _apply_gray_style(btn: Button):
	# --- Normal (Обычный) ---
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#505050") # Темно-серый/черный
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	
	# --- Hover (Наведение) ---
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#4a4a4a") # Серый
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	# Применяем
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal) # При нажатии остается серым
	btn.add_theme_stylebox_override("focused", style_normal)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
