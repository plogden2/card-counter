class_name EventBus

const VALID_EVENTS := {
	"count:updated": true,
	"hand:settled": true,
	"stay:assessed": true,
	"player:joined": true,
	"player:left": true,
	"shoe:reshuffled": true,
	"coaching:message": true,
	"mode:changed": true,
	"scene:navigate": true,
}

var _listeners: Dictionary = {}


func on(event: String, listener: Callable) -> Callable:
	_ensure_valid_event(event)
	if not _listeners.has(event):
		_listeners[event] = []
	var event_listeners: Array = _listeners[event]
	event_listeners.append(listener)
	_listeners[event] = event_listeners
	return func() -> void:
		off(event, listener)


func off(event: String, listener: Callable) -> void:
	if not _listeners.has(event):
		return
	var event_listeners: Array = _listeners[event]
	var index := event_listeners.find(listener)
	if index >= 0:
		event_listeners.remove_at(index)
	_listeners[event] = event_listeners


func emit_event(event: String, payload: Dictionary) -> void:
	_ensure_valid_event(event)
	var event_listeners: Array = _listeners.get(event, [])
	for listener in event_listeners:
		listener.call(payload)


func clear() -> void:
	_listeners.clear()


func _ensure_valid_event(event: String) -> void:
	if not VALID_EVENTS.has(event):
		push_error("Unknown event: %s" % event)
