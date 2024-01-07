extends CharacterBody3D

const _SPEED = 2.0

@export var ball: Node3D
@onready var _agent: NavigationAgent3D = $NavigationAgent3D


func _input(event: InputEvent) -> void:
	# Mouse in viewport coordinates.
	if !(event is InputEventMouseButton):
		return

	if !event.is_pressed():
		return

	var mouse := event as InputEventMouseButton
	var mouse_position_world := get_viewport().get_camera_3d().project_position(mouse.position, 0)

	ball.transform.origin = mouse_position_world
	#_agent.set_target_position(transform.origin + Vector3(30, 50, 0))
	print(get_viewport().get_camera_3d().project_ray_normal(mouse.position))


func _physics_process(delta: float) -> void:
	if _agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = _agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * _SPEED
	move_and_slide()
