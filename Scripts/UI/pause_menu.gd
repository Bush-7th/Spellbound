extends CanvasLayer

@onready var btn_resume: Button = %ResumeButton
@onready var btn_settings: Button = %SettingsButton
@onready var btn_main_menu: Button = %MainMenuButton

func _ready():
	# Важно: чтобы клики работали, даже когда игра на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Подключаем кнопки
	if btn_resume:
		btn_resume.pressed.connect(_on_resume_pressed)
		btn_resume.grab_focus() # Сразу даем фокус кнопке "Продолжить"
		
	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)
		
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed():
	PauseManager.toggle_pause()

func _on_settings_pressed():
	PauseManager.open_settings_over_pause()

func _on_main_menu_pressed():
	# 1. Сначала очищаем состояние паузы (удаляем меню и снимаем флаг paused)
	PauseManager.close_pause_menu()
	
	# 2. Теперь безопасно меняем сцену
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
