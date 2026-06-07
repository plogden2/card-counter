extends PanelContainer

const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")

signal closed

@onready var _sound_toggle: CheckButton = %SoundToggle
@onready var _motion_toggle: CheckButton = %MotionToggle
@onready var _music_toggle: CheckButton = %MusicToggle
@onready var _sfx_toggle: CheckButton = %SfxToggle
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider

var _controller: Node = null


func _ready() -> void:
	UiTheme.apply_to(self, UiTheme.ScreenClass.OVERLAY)
	visible = false
	_load_from_profile()


func set_controller(controller: Node) -> void:
	_controller = controller
	_load_from_profile()


func open() -> void:
	_load_from_profile()
	visible = true


func close_panel() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _load_from_profile() -> void:
	var profile: Dictionary
	if _controller != null and _controller.has_method("get_profile"):
		profile = _controller.call("get_profile")
	else:
		profile = LearnerProfile.load_profile()
	_sound_toggle.button_pressed = bool(profile.get("soundEnabled", true))
	_motion_toggle.button_pressed = bool(profile.get("motionReduced", false))
	_music_toggle.button_pressed = bool(profile.get("musicEnabled", profile.get("soundEnabled", true)))
	_sfx_toggle.button_pressed = bool(profile.get("sfxEnabled", profile.get("soundEnabled", true)))
	_music_slider.value = float(profile.get("musicVolume", 0.5))
	_sfx_slider.value = float(profile.get("sfxVolume", 0.8))


func _save_profile() -> void:
	var profile: Dictionary
	if _controller != null and _controller.has_method("get_profile"):
		profile = _controller.call("get_profile").duplicate(true)
	else:
		profile = LearnerProfile.load_profile()
	profile["soundEnabled"] = _sound_toggle.button_pressed
	profile["motionReduced"] = _motion_toggle.button_pressed
	profile["musicEnabled"] = _music_toggle.button_pressed
	profile["sfxEnabled"] = _sfx_toggle.button_pressed
	profile["musicVolume"] = _music_slider.value
	profile["sfxVolume"] = _sfx_slider.value
	LearnerProfile.save_profile(profile)
	if _controller != null:
		_controller.set("profile", profile)
		if _controller.get("audio_manager") != null:
			var audio: Node = _controller.audio_manager
			audio.call("set_enabled", profile["soundEnabled"] and profile["sfxEnabled"])
			audio.call("set_music_enabled", profile["soundEnabled"] and profile["musicEnabled"])
			audio.call("set_music_volume", profile["musicVolume"])
			audio.call("set_sfx_volume", profile["sfxVolume"])


func _on_close_pressed() -> void:
	_save_profile()
	close_panel()


func _on_sound_toggled(_pressed: bool) -> void:
	_save_profile()


func _on_motion_toggled(_pressed: bool) -> void:
	_save_profile()


func _on_music_toggled(_pressed: bool) -> void:
	_save_profile()


func _on_sfx_toggled(_pressed: bool) -> void:
	_save_profile()


func _on_music_slider_changed(_value: float) -> void:
	_save_profile()


func _on_sfx_slider_changed(_value: float) -> void:
	_save_profile()
