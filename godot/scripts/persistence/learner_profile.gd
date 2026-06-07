class_name LearnerProfile

const TableConfig = preload("res://scripts/domain/table_config.gd")

const _PROFILE_DIR := "user://card-counter"
const _PROFILE_PATH := "user://card-counter/learner-profile.json"


static func default_profile() -> Dictionary:
	return {
		"schemaVersion": 1,
		"balance": TableConfig.STARTING_BANKROLL,
		"selectedBetModel": "spread-table",
		"soundEnabled": true,
		"musicEnabled": true,
		"sfxEnabled": true,
		"musicVolume": 0.5,
		"sfxVolume": 0.8,
		"motionReduced": false,
	}


static func load_profile() -> Dictionary:
	var defaults: Dictionary = default_profile()
	if not FileAccess.file_exists(_PROFILE_PATH):
		return defaults
	var file := FileAccess.open(_PROFILE_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var json := JSON.new()
	var error: int = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		return defaults
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return defaults
	var profile: Dictionary = parsed
	if int(profile.get("schemaVersion", -1)) != 1:
		return defaults
	var merged: Dictionary = defaults.duplicate(true)
	for key in profile.keys():
		merged[key] = profile[key]
	merged["schemaVersion"] = 1
	merged["balance"] = int(merged.get("balance", TableConfig.STARTING_BANKROLL))
	return merged


static func save_profile(profile: Dictionary) -> void:
	_ensure_profile_dir()
	var to_save: Dictionary = profile.duplicate(true)
	to_save["lastSessionAt"] = Time.get_datetime_string_from_system(true, true)
	var file := FileAccess.open(_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open learner profile path for writing")
		return
	file.store_string(JSON.stringify(to_save))
	file.close()


static func read_last_mode() -> Variant:
	return load_profile().get("lastMode", null)


static func write_last_mode(mode: String) -> void:
	var profile: Dictionary = load_profile()
	profile["lastMode"] = mode
	save_profile(profile)


static func reset_bankroll() -> Dictionary:
	var profile: Dictionary = load_profile()
	profile["balance"] = TableConfig.STARTING_BANKROLL
	save_profile(profile)
	profile["balance"] = int(profile["balance"])
	return profile


static func clear_profile_for_tests() -> void:
	if DirAccess.dir_exists_absolute(_PROFILE_DIR):
		DirAccess.remove_absolute(_PROFILE_PATH)


static func write_raw_profile_json(text: String) -> void:
	_ensure_profile_dir()
	var file := FileAccess.open(_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open learner profile path for writing")
		return
	file.store_string(text)
	file.close()


static func _ensure_profile_dir() -> void:
	if not DirAccess.dir_exists_absolute(_PROFILE_DIR):
		DirAccess.make_dir_recursive_absolute(_PROFILE_DIR)
