class_name HandSnapshot

const _PROFILE_DIR := "user://card-counter"
const _SNAPSHOT_PATH := "user://card-counter/hand-snapshot.json"


static func load_hand_snapshot_or_null() -> Variant:
	if not FileAccess.file_exists(_SNAPSHOT_PATH):
		return null
	var file := FileAccess.open(_SNAPSHOT_PATH, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	var error: int = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		return null
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var snapshot: Dictionary = parsed
	if not snapshot.has("sessionState") or not snapshot.has("phase"):
		return null
	return snapshot


static func load_hand_snapshot() -> Dictionary:
	var snapshot: Variant = load_hand_snapshot_or_null()
	if snapshot == null:
		return {}
	return snapshot


static func save_hand_snapshot(snapshot: Dictionary) -> void:
	_ensure_profile_dir()
	var file := FileAccess.open(_SNAPSHOT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open hand snapshot path for writing")
		return
	file.store_string(JSON.stringify(snapshot))
	file.close()


static func clear_hand_snapshot() -> void:
	DirAccess.remove_absolute(_SNAPSHOT_PATH)


static func has_snapshot() -> bool:
	return load_hand_snapshot_or_null() != null


static func create_snapshot(session: Dictionary, phase: String, active_seat_id: String) -> Dictionary:
	return {
		"sessionState": session,
		"phase": phase,
		"activeSeatId": active_seat_id,
		"savedAt": Time.get_datetime_string_from_system(true, true),
	}


static func write_raw_snapshot_json(text: String) -> void:
	_ensure_profile_dir()
	var file := FileAccess.open(_SNAPSHOT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open hand snapshot path for writing")
		return
	file.store_string(text)
	file.close()


static func _ensure_profile_dir() -> void:
	if not DirAccess.dir_exists_absolute(_PROFILE_DIR):
		DirAccess.make_dir_recursive_absolute(_PROFILE_DIR)
