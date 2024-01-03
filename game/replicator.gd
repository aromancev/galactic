# Replicator is the backbone for saving, loading, and replicating game state to all clients.
# It handles model getting and setting, and replicating it to all clients. It DOES NOT handle save
# game specifics. To implement saving, get the model using Replicator and save it using desired
# method.
#
# See root README for more details on usage and design.
class_name Replicator
extends Node

enum NodeScheme {
	SCENE = 1,
	PATH = 2,
	MODEL = 3,
}

enum ModelScheme {
	NODES = 1,
}

const GROUP = "Replicate"
const GET_METHOD = "_get_model"
const SET_METHOD = "_set_model"

# The Node that will be the root for replication.
# Make sure all replicated Nodes are contained in it.
@export var container: Node


# Replicate game model to another player.
func send_model(peer_id: int) -> void:
	if !multiplayer.is_server():
		return

	if peer_id == multiplayer.get_unique_id():
		return

	_receive_model.rpc_id(peer_id, get_model())


@rpc("authority", "call_remote", "reliable")
func _receive_model(model: PackedByteArray) -> void:
	set_model(model)


# Collects all models for Nodes and returns the aggregated model.
# Can be expensive so do not call too often.
func get_model() -> PackedByteArray:
	var model := BinaryPayload.new()
	var appender := NodeAppender.new(container, model, ModelScheme.NODES)

	for node in get_tree().get_nodes_in_group(GROUP):
		if !node.is_inside_tree():
			continue

		appender.append(node)

	return model.encode()


# Creates all replicated Nodes and propagates corersponding models to them.
# Should only be called one when a player joins the game.
func set_model(model: PackedByteArray) -> void:
	var payload := BinaryPayload.decoded(model)

	for data in payload.get_payload_array(ModelScheme.NODES):
		var path := data.get_var(NodeScheme.PATH) as NodePath

		var node := container.get_node_or_null(path)
		if !node:
			var scene := load(data.get_var(NodeScheme.SCENE) as String) as PackedScene
			node = scene.instantiate()
			node.name = _get_name(path)
			var parent := _get_parent_path(path)
			if parent:
				container.get_node(parent).add_child(node)
			else:
				container.add_child(node)

		if node.has_method(SET_METHOD):
			node.call(SET_METHOD, data.get_var(NodeScheme.MODEL))


func _get_name(path: NodePath) -> StringName:
	return path.get_name(path.get_name_count() - 1)


func _get_parent_path(path: NodePath) -> NodePath:
	return NodePath("/".join(path.get_concatenated_names().split("/").slice(0, -1)))


# Encapsulates logic for traversing the node tree and collecting models.
# It is a bit complicated because we need to make sure all parents are stored first and there are
# no duplicates.
class NodeAppender:
	var container: Node
	var payload: BinaryPayload
	var append_index: int
	var appended: Dictionary = {}

	func _init(p_container: Node, p_payload: BinaryPayload, p_append_index: int) -> void:
		container = p_container
		payload = p_payload
		append_index = p_append_index

	# Recursive.
	func append(node: Node) -> void:
		if node in appended:
			return

		# Append parent before appending self.
		# This ensures that when model is set, all Nodes will already have parent ceated.
		if node.get_parent() != container:
			append(node.get_parent())

		var p := BinaryPayload.new()
		p.set_var(NodeScheme.SCENE, node.get_scene_file_path())
		p.set_var(NodeScheme.PATH, container.get_path_to(node))
		if node.has_method(GET_METHOD):
			p.set_var(NodeScheme.MODEL, node.call(GET_METHOD))
		payload.append_payload(1, p)

		appended[node] = null
