extends Order


func _ready() -> void:
	super()

	if is_preparing:
		prepared.emit(null)
