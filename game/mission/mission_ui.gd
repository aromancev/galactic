class_name MissionUI
extends CanvasLayer
"""
Represents the main UI overlay of the mission. It should be the only place that directly handles
Ability key bindings, shortcuts, etc.
"""

signal spawn(node: Node)

var _selected_unit: Unit = null
var _preparing_order: Order = null

@onready var _abilities: VBoxContainer = $Abilities
@onready var _order_container: Node = $PreparingOrder


func select_unit(unit: Unit) -> void:
	_selected_unit = unit
	_render_abilities()
	unit.ability_added.connect(_on_unit_ability_changed)
	unit.ability_removed.connect(_on_unit_ability_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_alt"):
		_cancel_prepare()
		return

	if event.is_action_pressed("select"):
		if _preparing_order != null:
			return

		var target: Variant = MissionCamera.get_instance().get_level_cursor_projection()
		if target == null:
			return

		var e := AbilityUsedEvent.new(_selected_unit.id, "navigate", target)
		Input.parse_input_event(e)

	elif event.is_action_pressed("orders_clear"):
		Input.parse_input_event(AbilityQueueClearEvent.new(_selected_unit.id))

	elif event is InputEventKey:
		var e: InputEventKey = event
		if e.pressed and e.keycode > KEY_0 and e.keycode <= KEY_9:
			var slug: String = _abilities.get_child(e.keycode - KEY_1).get_meta("slug")
			_prepare(slug)


func _render_abilities() -> void:
	for a in _abilities.get_children():
		_abilities.remove_child(a)

	var i := 0
	var abilities := _selected_unit.get_abilities()
	for slug: String in abilities:
		i += 1
		var ability: AbilityResource = abilities[slug]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "[%s] %s" % [i, ability.name]
		btn.pressed.connect(_prepare.bind(slug))
		btn.set_meta("slug", slug)
		_abilities.add_child(btn)


func _prepare(slug: String) -> void:
	if !_selected_unit:
		return

	_cancel_prepare()

	var ability := _selected_unit.get_ability(slug)
	_preparing_order = Order.new()
	_preparing_order.set_script(ability.order.order_script)
	_preparing_order.is_preparing = true
	_preparing_order.ability_slug = slug
	_preparing_order.ability = ability
	_preparing_order.unit_position = _selected_unit.get_planned_position()
	_preparing_order.spawn.connect(_on_spawn)
	_preparing_order.prepared.connect(_on_prepared)
	_order_container.add_child(_preparing_order)


func _on_spawn(node: Node) -> void:
	spawn.emit(node)


func _on_prepared(target: Variant) -> void:
	var e := AbilityUsedEvent.new(_selected_unit.id, _preparing_order.ability_slug, target)
	Input.parse_input_event(e)
	_cancel_prepare()


func _cancel_prepare() -> void:
	if _preparing_order == null:
		return

	_preparing_order.queue_free()
	_preparing_order = null


func _on_unit_ability_changed(res: AbilityResource) -> void:
	if res.is_displayed:
		_render_abilities()
