extends Camera3D

const _SPEED = 40

func _physics_process(delta: float) -> void:
    var vector := Vector3()
    if Input.is_action_pressed("ui_up"):
        vector -= global_transform.basis.z
    if Input.is_action_pressed("ui_down"):
        vector += global_transform.basis.z
    if Input.is_action_pressed("ui_left"):
        vector -= global_transform.basis.x
    if Input.is_action_pressed("ui_right"):
        vector += global_transform.basis.x

    vector.y = 0
    if !vector:
        return

    transform.origin += vector * _SPEED * delta
