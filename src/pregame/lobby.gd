class_name Lobby
extends ScrollContainer


var player_labels := {}

@onready var player_name_edit: LineEdit = $VBoxContainer/PlayerStuff/HBoxContainer/PlayerName


func _ready() -> void:
	set_room_code()
	WebrtcHost.room_code_received.connect(set_room_code)
	if WebrtcHost.hosting:
		$VBoxContainer/HostStuff/HBoxContainer/Ready.hide()
		$VBoxContainer/HostStuff/HBoxContainer/NotEnough.show()
		$VBoxContainer/PlayerStuff.queue_free()
		GameState.new_player_added.connect(
			func(state: PlayerState):
				var label := Label.new()
				player_labels[state.name] = label
				label.text = state.name
				$VBoxContainer/HostStuff/Players.add_child(label)
				state.name_changed.connect(
					func():
						if is_instance_valid(label):
							label.text = state.name
				)
				if player_labels.size() >= 3:
					$VBoxContainer/HostStuff/HBoxContainer/NotEnough.hide()
					$VBoxContainer/HostStuff/HBoxContainer/Ready.show()
					$VBoxContainer/HostStuff/HBoxContainer/Start.disabled = false
		)
		GameState.player_removed.connect(
			func(name: StringName):
				if not name in player_labels:
					return
				player_labels[name].queue_free()
				player_labels.erase(name)
				if player_labels.size() < 3:
					$VBoxContainer/HostStuff/HBoxContainer/NotEnough.show()
					$VBoxContainer/HostStuff/HBoxContainer/Ready.hide()
					$VBoxContainer/HostStuff/HBoxContainer/Start.disabled = true
		)
		
	else:
		GameState.game_has_started.connect(
			func():
				Main.fade_change_scene(preload("res://src/game/role.tscn").instantiate()),
			CONNECT_ONE_SHOT
		)
		$VBoxContainer/HostStuff.queue_free()
		var on_player_added := func(state: PlayerState):
				var label := Label.new()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				player_labels[state.name] = label
				label.text = state.name
				$VBoxContainer/PlayerStuff/Players.add_child(label)
				state.name_changed.connect(
					func():
						if is_instance_valid(label):
							label.text = state.name
				)
		for peer_state in GameState.peers.values():
			if peer_state.name != GameState.my_state.name:
				on_player_added.call(peer_state)
		GameState.new_player_added.connect(on_player_added)
		GameState.player_removed.connect(
			func(name: StringName):
				if not name in player_labels:
					return
				player_labels[name].queue_free()
				player_labels.erase(name)
		)
		GameState.player_state_received.connect(_on_player_state_received)
		if GameState.my_state != null:
			_on_player_state_received()


func set_room_code():
	$"VBoxContainer/HostStuff/HBoxContainer2/Room Code".text = str(WebrtcHost.room_code)


func _on_player_state_received():
	player_name_edit.text = GameState.my_state.name


func _on_player_name_changed(_text:="") -> void:
	if !GameState.sync_player_name(player_name_edit.text):
		player_name_edit.text = GameState.my_state.name


func _on_host_start_pressed() -> void:
	GameState.start_game()
