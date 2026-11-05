class_name SfxPlayer
extends AudioStreamPlayer

func _ready() -> void:
	stream = AudioStreamPolyphonic.new()
	play()
	UISfx.playback = get_stream_playback()
