# Encapsulates networking configuration and player info.
# Nodes are still responsible for their own RPCs.
extends Node

const Player = preload("res://game/session/player.gd")

signal player_connected(peer_id: int, player: Player)
signal player_disconnected(peer_id: int)
signal server_disconnected

const MAX_CONNECTIONS = 6
# Range 10991-10999 is unassigned: https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=10999
const PORT = 10991
const SERVER_ID = 1
var upnp := UPNP.new()

var players = {}
# Null for dedicated server.
var local_player: Player

func create():
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_server(PORT, MAX_CONNECTIONS)
    if error:
        return
    multiplayer.multiplayer_peer = peer

    if local_player:
        players[SERVER_ID] = local_player
        player_connected.emit(SERVER_ID, local_player)

func join(address):
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(address, PORT)
    if error:
        return
    multiplayer.multiplayer_peer = peer

func _ready():
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

@rpc("any_peer", "reliable")
func _register_player(player_serialized: Dictionary):
    var player := dict_to_inst(player_serialized) as Player
    var id := multiplayer.get_remote_sender_id()
    players[id] = player
    player_connected.emit(id, player)

func _on_player_disconnected(id):
    players.erase(id)
    player_disconnected.emit(id)

func _on_connected_fail():
    multiplayer.multiplayer_peer = null

func _on_server_disconnected():
    multiplayer.multiplayer_peer = null
    players.clear()
    server_disconnected.emit()

func _on_player_connected(id):
    if !local_player:
        return

    _register_player.rpc_id(id, inst_to_dict(local_player))

func _on_connected_ok():
    if !local_player:
        return

    var id = multiplayer.get_unique_id()
    players[id] = local_player
    player_connected.emit(id, local_player)

# NOTE: Currently not called to avoid latency during testing.
# This should run in a separate thread because it blocks for 2s.
# https://docs.godotengine.org/en/stable/classes/class_upnp.html
func _init_upnp():
    if upnp.discover() != UPNP.UPNP_RESULT_SUCCESS:
        return
    if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
        return

    upnp.add_port_mapping(PORT, PORT, "galactic_udp", "UDP")

func _exit_tree():
    upnp.delete_port_mapping(PORT, "UDP")
