# Manages new connections over WebRTC
# Does not handle anything directly related to the game, such as names or player state
extends Node

signal room_code_received

var ws: WebSocketPeer

var room_code: String

var hosting := false:
	set(value):
		if hosting == value:
			return
		hosting = value
		if hosting:
			var multiplayer_peer := WebRTCMultiplayerPeer.new()
			multiplayer_peer.create_server()
			multiplayer.multiplayer_peer = multiplayer_peer
			
			ws = WebSocketPeer.new()
			ws.connect_to_url("wss://webrtc.manglemix.com/host")
			room_code = await ws_recv()
			room_code_received.emit()
			
			while true:
				var msg: Dictionary = JSON.parse_string(await ws_recv())
				var client_id: int = msg["id"]
				
				if "new_offer" in msg:
					var peer := WebRTCPeerConnection.new()
					peer.session_description_created.connect(peer.set_local_description)
					multiplayer_peer.add_peer(peer, client_id)
					peer.set_remote_description("offer", msg["new_offer"])
					peer.session_description_created.connect(
						func(type: String, sdp: String):
							assert(type == "answer")
							ws.send_text(str({ "answer": sdp, "id": client_id }))
					)
					peer.ice_candidate_created.connect(
						func(media: String, index: int, _name: String):
							ws.send_text(str({ "ice": { "media": media, "index": index, "name": _name }, "id": client_id }))
					)
				
				elif "ice" in msg:
					var peer: WebRTCPeerConnection = multiplayer_peer.get_peer(client_id)["connection"]
					var ice: Dictionary = msg["ice"]
					peer.add_ice_candidate(ice["media"], ice["index"], ice["name"])
				
				else:
					push_error("Unrecognized message: %s" % msg)
			
		else:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			var tmp := ws
			ws = null
			tmp.close()
			while tmp.get_ready_state() != WebSocketPeer.STATE_CLOSED:
				await get_tree().create_timer(0.2).timeout
				tmp.poll()


func ws_recv() -> String:
	while true:
		await get_tree().create_timer(0.2).timeout
		if ws.get_available_packet_count() > 0:
			return ws.get_packet().get_string_from_utf8()
	return ""


func _process(_delta: float) -> void:
	if ws != null:
		ws.poll()
