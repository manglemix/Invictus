extends Node


const SECRET_PATH := "user://secret_key"
const GOOD_TO_BAD_COUNT := 3.0
const VOTE_TIME := 90.0
const ROLE_TIME := 2.5

signal new_player_added(state: PlayerState)
signal player_vote_changed(state: PlayerState)
signal player_removed(name: StringName)

# COMMON
var is_game_started := false
# player name to player state map
var peers := {}
# multiplayer_id to player name map
var peer_ids := {}
var timer := 0.0
var votes := {}

# Client
signal game_has_started
signal player_state_received
var my_secret: int
var my_state: PlayerState

# Server
#signal player_connected(player_secret: int)
# Secret to name
var peer_names := {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
#	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_peer_disconnected(peer_id: int):
	if peer_id in peer_ids:
		player_removed.emit(peer_ids[peer_id])


func _on_peer_connected(peer_id: int):
	if multiplayer.is_server():
		pre_init_peer.rpc_id(peer_id, is_game_started)


@rpc("any_peer", "reliable", "call_remote")
func identify_peer(secret: int):
	var state: PlayerState
	
	if secret in peer_names:
		state = peers[peer_names[secret]]
		
	else:
		state = PlayerState.new()
		state.multiplayer_id = multiplayer.get_remote_sender_id()
		while state.name.is_empty() or state.name in peers:
			state.name = "Player" + str(randi_range(1, 99))
		peer_names[secret] = state.name
		peers[state.name] = state
	
	peer_ids[multiplayer.get_remote_sender_id()] = state.name
	var peers_dict := {}
	for name in peers:
		peers_dict[name] = peers[name].to_dict()
	init_peer.rpc_id(multiplayer.get_remote_sender_id(), peers_dict, state.name)
	add_peer.rpc(state.to_dict())
#	player_connected.emit(secret)
	new_player_added.emit(state)


@rpc("authority", "reliable", "call_remote")
@warning_ignore("shadowed_variable")
func pre_init_peer(is_game_started: bool):
	self.is_game_started = is_game_started
	if is_game_started:
		var file := FileAccess.open(SECRET_PATH, FileAccess.WRITE)
		if file == null:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			# TODO
			return
		my_secret = file.get_64()
		identify_peer.rpc_id(1, my_secret)
		
	else:
		var bytes := Crypto.new().generate_random_bytes(8)
		my_secret = bytes.decode_u64(0)
		identify_peer.rpc_id(1, my_secret)
		var file := FileAccess.open(SECRET_PATH, FileAccess.WRITE)
		file.store_64(my_secret)


@rpc("authority", "reliable", "call_remote")
func add_peer(peer_state: Dictionary):
	var state := PlayerState.from_dict(peer_state)
	if my_state != null and state.name == my_state.name:
		return
	peers[state.name] = state
	peer_ids[state.multiplayer_id] = state.name
	new_player_added.emit(state)


@rpc("authority", "reliable", "call_remote")
func init_peer(peers_dict: Dictionary, your_name: StringName):
	for name in peers_dict:
		var state := PlayerState.from_dict(peers_dict[name])
		peers[name] = state
		peer_ids[state.multiplayer_id] = state.name
		new_player_added.emit(state)
	my_state = peers[your_name]


func get_player_state(player_name: StringName) -> PlayerState:
	if player_name in peers:
		return peers[player_name]
	return null


func sync_player_name(new_name: String) -> bool:
	new_name = new_name.strip_edges()
	if is_game_started:
		push_error("Attempted to sync player name after game has started")
		return false
	if new_name in peers:
		return false
	if new_name.is_empty():
		return false
	_sync_player_name.rpc(my_state.name, new_name)
	return true


@rpc("any_peer", "reliable", "call_local")
func _sync_player_name(old_name: String, new_name: String):
	var state: PlayerState = peers[old_name]
	state.name = new_name
	peers[new_name] = state
	if multiplayer.is_server():
		for secret in peer_names:
			if peer_names[secret] == old_name:
				peer_names[secret] = new_name
				break


func start_game():
	if !multiplayer.is_server():
		push_error("Attempted to start game on %s" % multiplayer.get_unique_id())
		return
	is_game_started = true
	timer = VOTE_TIME + ROLE_TIME
	init_votes()
	var bad_count := roundi(peers.size() / GOOD_TO_BAD_COUNT)
	var infected_names: Array[StringName] = []
	var peer_states := peers.values()
	for _i in range(bad_count):
		while true:
			var state: PlayerState = peer_states.pick_random()
			if state.is_infected:
				continue
			state.is_infected = true
			infected_names.append(state.name)
			break
	var designated_survivor: StringName
	while true:
		var state: PlayerState = peer_states.pick_random()
		if state.is_infected:
			continue
		state.is_designated_survivor = true
		designated_survivor = state.name
		break
	host_started_game.rpc(infected_names, designated_survivor)


@rpc("authority", "call_remote", "reliable")
func host_started_game(infected_names: Array, designated_survivor: StringName):
	is_game_started = true
	for name in infected_names:
		peers[name].is_infected = true
	peers[designated_survivor].is_designated_survivor = true
	game_has_started.emit()
	timer = VOTE_TIME + ROLE_TIME
	init_votes()


func vote_for(player_name: StringName):
	_vote_for.rpc(player_name)


func unvote_for(player_name: StringName):
	_unvote_for.rpc(player_name)


@rpc("any_peer", "call_local", "reliable")
func _vote_for(player_name: StringName):
	var state: PlayerState = peers[player_name]
	state.votes.append(peer_ids[multiplayer.get_remote_sender_id()])
	player_vote_changed.emit(state)


@rpc("any_peer", "call_local", "reliable")
func _unvote_for(player_name: StringName):
	var state: PlayerState = peers[player_name]
	state.votes.erase(peer_ids[multiplayer.get_remote_sender_id()])
	player_vote_changed.emit(state)


func get_top_voted() -> Array:
	var states := peers.values()
	states.sort_custom(
		func(a: PlayerState, b: PlayerState):
			if a.votes.size() == b.votes.size():
				return a.name.naturalcasecmp_to(b.name) >= 0
			return a.votes.size() > b.votes.size()
	)
	return states.slice(0, 3)


func init_votes():
	for state in peers.values():
		state.votes.clear()


func _process(delta: float) -> void:
	if timer > 0:
		timer -= delta
