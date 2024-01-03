# Encapsulates networking configuration and player info.
# Nodes are still responsible for their own RPCs.
extends Node

signal player_connected(peer_id: int, player: Player)
signal player_disconnected(peer_id: int)
signal server_disconnected

var players: Dictionary = {}
# Null for dedicated server.
var local_player: Player

const _MAX_CONNECTIONS = 6
# Range 10991-10999 is unassigned: https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=10999
const _PORT = 10991
const _SERVER_ID = 1
var _upnp := UPNP.new()

func create() -> void:
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_server(_PORT, _MAX_CONNECTIONS)
    if error:
        return
    multiplayer.multiplayer_peer = peer

    if local_player:
        players[_SERVER_ID] = local_player
        player_connected.emit(_SERVER_ID, local_player)

func join(address: String) -> void:
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_client(address, _PORT)
    if error:
        return
    multiplayer.multiplayer_peer = peer
    _handshake.rpc_id(_SERVER_ID, BuildInfo.version)

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

@rpc("any_peer", "reliable")
func _handshake(version: PackedInt32Array) -> void:
    if !multiplayer.is_server():
        return

    if !BuildInfo.is_verion_compatible(version):
        _disconnect.rpc_id(multiplayer.get_remote_sender_id())

@rpc("authority", "reliable")
func _disconnect() -> void:
    multiplayer.multiplayer_peer = null
    server_disconnected.emit()

@rpc("any_peer", "reliable")
func _register_player(p_player: PackedByteArray) -> void:
    var player := Player.from_bin(p_player)
    var id := multiplayer.get_remote_sender_id()
    players[id] = player
    player_connected.emit(id, player)

func _on_player_disconnected(id: int) -> void:
    players.erase(id)
    player_disconnected.emit(id)

func _on_connected_fail() -> void:
    multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
    multiplayer.multiplayer_peer = null
    players.clear()
    server_disconnected.emit()

func _on_player_connected(id: int) -> void:
    if local_player:
        _register_player.rpc_id(id, local_player.to_bin())

func _on_connected_ok() -> void:
    if !local_player:
        return

    var id := multiplayer.get_unique_id()
    players[id] = local_player
    player_connected.emit(id, local_player)

# NOTE: Currently not called to avoid latency during testing.
# This should run in a separate thread because it blocks for 2s.
# https://docs.godotengine.org/en/stable/classes/class_upnp.html
func _init_upnp() -> void:
    if _upnp.discover() != UPNP.UPNP_RESULT_SUCCESS:
        return
    if not _upnp.get_gateway() or not _upnp.get_gateway().is_valid_gateway():
        return

    _upnp.add_port_mapping(_PORT, _PORT, "galactic_udp", "UDP")

func _exit_tree() -> void:
    _upnp.delete_port_mapping(_PORT, "UDP")
