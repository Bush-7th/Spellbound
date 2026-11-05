extends Node

const SETTINGS_PATH = "user://settings.json"
const CONTROLS_PATH = "user://controls.json"

# --- Настройки игры ---
var master_volume: float = 1.0
var vsync_mode: int = DisplayServer.VSYNC_ENABLED
var fullscreen_mode: bool = false
var current_language: String = "ru"

# --- Управление (Keybinds) ---
# Эти переменные нужны только для UI, чтобы показывать текущие кнопки
var key_look_up: int = KEY_W
var key_look_down: int = KEY_S
var key_move_left: int = KEY_A
var key_move_right: int = KEY_D
var key_jump: int = KEY_SPACE
var key_dash: int = KEY_SHIFT
var key_dodge: int = KEY_CTRL

func _ready():
	load_settings()
	load_controls()
	apply_settings()

# ==========================================
# ЛОГИКА ДЛЯ SETTINGS.JSON (Без изменений)
# ==========================================
func save_settings():
	var settings = {
		"Volume": master_volume,
		"VSync": vsync_mode,
		"Fullscreen": fullscreen_mode,
		"Language": current_language
	}
	var json_string = JSON.stringify(settings, "\t")
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH): return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			if data is Dictionary:
				master_volume = data.get("Volume", 1.0)
				vsync_mode = data.get("VSync", DisplayServer.VSYNC_ENABLED)
				fullscreen_mode = data.get("Fullscreen", false)
				current_language = data.get("Language", "ru")
		file.close()

func apply_settings():
	DisplayServer.window_set_vsync_mode(vsync_mode)
	if fullscreen_mode:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	
	TranslationServer.set_locale(current_language)

# ==========================================
# 🔥 ИСПРАВЛЕННАЯ ЛОГИКА ДЛЯ CONTROLS.JSON
# ==========================================

func save_controls():
	var controls = {
		"look_up": key_look_up,
		"look_down": key_look_down,
		"move_left": key_move_left,
		"move_right": key_move_right,
		"jump": key_jump,
		"dash": key_dash,
		"dodge": key_dodge
	}
	var json_string = JSON.stringify(controls, "\t")
	var file = FileAccess.open(CONTROLS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	print("💾 Сохранено в: ", CONTROLS_PATH)
	print("💾 Клавиша прыжка сохранена как: ", key_jump)

func load_controls():
	# 1. Сначала убедимся, что все действия существуют в InputMap
	var actions_list = ["look_up", "look_down", "move_left", "move_right", "jump", "dash", "dodge"]
	for action in actions_list:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	# 2. Загружаем данные из файла (если он есть)
	var controls_data = {}
	if FileAccess.file_exists(CONTROLS_PATH):
		var file = FileAccess.open(CONTROLS_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				controls_data = json.data
			file.close()

	# 3. Применяем настройки к каждому действию
	for action_name in actions_list:
		# Получаем код клавиши из файла или берем дефолтный
		var key_code = KEY_NONE
		match action_name:
			"look_up": key_code = controls_data.get("look_up", KEY_W)
			"look_down": key_code = controls_data.get("look_down", KEY_S)
			"move_left": key_code = controls_data.get("move_left", KEY_A)
			"move_right": key_code = controls_data.get("move_right", KEY_D)
			"jump": key_code = controls_data.get("jump", KEY_SPACE)
			"dash": key_code = controls_data.get("dash", KEY_SHIFT)
			"dodge": key_code = controls_data.get("dodge", KEY_CTRL)

		# 🔥 ВАЖНО: Полностью очищаем действие от всех старых клавиш
		InputMap.action_erase_events(action_name)
		
		# Создаем новое событие
		var ev = InputEventKey.new()
		ev.keycode = key_code
		ev.physical_keycode = key_code # Важно для корректной работы на разных раскладках
		
		# Добавляем новую привязку
		InputMap.action_add_event(action_name, ev)
		
		# Обновляем переменные для UI (чтобы в меню отображалась правильная кнопка)
		match action_name:
			"look_up": key_look_up = key_code
			"look_down": key_look_down = key_code
			"move_left": key_move_left = key_code
			"move_right": key_move_right = key_code
			"jump": key_jump = key_code
			"dash": key_dash = key_code
			"dodge": key_dodge = key_code
			
	print("✅ Keybinds applied instantly!")
	print("📂 Загружена клавиша прыжка: ", key_jump)
	print("📂 Проверка InputMap: ", InputMap.action_get_events("jump"))
# Вспомогательная функция для UI
func get_key_name(key_code: int) -> String:
	return OS.get_keycode_string(key_code)
