class_name CancelableTimer
extends Timer

signal timeout_or_cancel

var _is_cancelled: bool = false


func is_cancelled() -> bool:
	return _is_cancelled


func cancel() -> void:
	if _is_cancelled:
		return
	_is_cancelled = true
	stop()
	timeout.disconnect(_on_timeout)
	timeout_or_cancel.emit()


func _init() -> void:
	timeout.connect(_on_timeout)


func _on_timeout() -> void:
	if _is_cancelled:
		return

	timeout_or_cancel.emit()
