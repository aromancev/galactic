class_name ControllerTest
extends Controller

var _timer: Timer = Timer.new()


func _ready() -> void:
	super()

	if !is_multiplayer_authority():
		return

	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

	await get_tree().create_timer(randf_range(0, 3)).timeout
	_timer.start(1)


func _on_timeout() -> void:
	if randi_range(0, 1):
		use_ability("navigate", _get_random_point_on_test_level())
	else:
		use_ability("shoot", _get_random_point_on_test_level())


func _get_random_point_on_test_level() -> Vector3:
	const _TEST_LEVEL_WIDTH = 16. * 4

	var p := Vector3.ZERO
	p.x = randf_range(-_TEST_LEVEL_WIDTH / 2, _TEST_LEVEL_WIDTH / 2)
	p.z = randf_range(-_TEST_LEVEL_WIDTH / 2, _TEST_LEVEL_WIDTH / 2)
	return p
