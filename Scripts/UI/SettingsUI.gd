extends CanvasLayer

@onready var volume_slider: HSlider = %Volume_HSlider
@onready var vsync_checkbox: CheckBox = %VSync_CheckBox
@onready var fullscreen_checkbox: CheckBox = %FullScreen_CheckBox
@onready var Apply_button: Button = %Apply_Button
@onready var back_button: Button = %Back_Button
@onready var key_binds_button: Button = %KeyBinds_Button
@onready var en_button: Button = %EN_Button
@onready var ru_button: Button = %RU_Button
@onready var background_color_rect: ColorRect = %ColorRect # <--- ВАЖНО: Дай это имя своему фону в сцене!

var is_over_pause: bool = false
var temp_volume: float
var temp_vsync: int
var temp_fullscreen: bool
var temp_language: String = "ru"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if background_color_rect:
		if is_over_pause:
			# Полупрозрачный черный для игры
			background_color_rect.color = Color(0, 0, 0, 0.7) 
		else:
			# Почти сплошной черный для главного меню (выглядит солиднее)
			background_color_rect.color = Color(0, 0, 0, 0.95) 
	_load_temp_settings()
	_refresh_ui()
	
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	vsync_checkbox.toggled.connect(_on_vsync_checkbox_toggled)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_checkbox_toggled)
	Apply_button.pressed.connect(_on_save_pressed)
	en_button.pressed.connect(_on_en_button_pressed)
	ru_button.pressed.connect(_on_ru_button_pressed)
	
	if back_button: back_button.pressed.connect(_on_back_button_pressed)
	if key_binds_button: key_binds_button.pressed.connect(_on_key_binds_button_pressed)

func _load_temp_settings():
	temp_volume = SettingsManager.master_volume
	temp_vsync = SettingsManager.vsync_mode
	temp_fullscreen = SettingsManager.fullscreen_mode
	temp_language = SettingsManager.current_language

func _refresh_ui():
	volume_slider.value = temp_volume
	vsync_checkbox.button_pressed = (temp_vsync != DisplayServer.VSYNC_DISABLED)
	fullscreen_checkbox.button_pressed = temp_fullscreen
	_update_language_buttons()

func _on_volume_slider_value_changed(value: float): temp_volume = value
func _on_vsync_checkbox_toggled(toggled_on: bool): 
	temp_vsync = DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
func _on_fullscreen_checkbox_toggled(toggled_on: bool): temp_fullscreen = toggled_on

func _on_save_pressed():
	SettingsManager.master_volume = temp_volume
	SettingsManager.vsync_mode = temp_vsync
	SettingsManager.fullscreen_mode = temp_fullscreen
	SettingsManager.current_language = temp_language
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_back_button_pressed():
	if is_over_pause:
		PauseManager._on_settings_closed()
	queue_free() 

func _on_key_binds_button_pressed():
	var keybinds_scene = preload("res://scenes/UI/key_binds_overlay.tscn").instantiate()
	
	# 🔥 Передаем тот же флаг, который получили сами
	if "is_over_pause" in keybinds_scene:
		keybinds_scene.is_over_pause = self.is_over_pause
		
	get_tree().root.add_child(keybinds_scene)
	self.visible = false
	
	keybinds_scene.tree_exited.connect(func(): self.visible = true)

func _on_en_button_pressed(): temp_language = "en"; _update_language_buttons()
func _on_ru_button_pressed(): temp_language = "ru"; _update_language_buttons()

func _update_language_buttons():
	if temp_language == "ru":
		_apply_blue_style(ru_button); _apply_gray_style(en_button)
	else:
		_apply_blue_style(en_button); _apply_gray_style(ru_button)

# ... (Твои функции стилей _apply_blue_style и _apply_gray_style оставь без изменений) ...
func _apply_blue_style(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#ff007f")
	style_normal.corner_radius_top_left = 8; style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8; style_normal.corner_radius_bottom_right = 8
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#ff4da6")
	style_hover.corner_radius_top_left = 8; style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8; style_hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_stylebox_override("focused", style_normal)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

func _apply_gray_style(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#505050")
	style_normal.corner_radius_top_left = 8; style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8; style_normal.corner_radius_bottom_right = 8
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#4a4a4a")
	style_hover.corner_radius_top_left = 8; style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8; style_hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_stylebox_override("focused", style_normal)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
