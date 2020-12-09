extends Control
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

const GAME_SCREEN_SCENE = preload("res://source/GameScreen.tscn")

const DETAILS_TEMPLATE = """[u]ROOM[/u]
%s

[u]GAME[/u]
%s

[u]PLAYERS[/u]
%s"""

enum STATE {MENU, GAME_WAIT, GAME_PLAY, GAME_POST}

var room = null
var game_node = null
var all_player_details = null
var player_details = null
var _show_controls_timer = 0.0
var _music_position = 0.0
var _connect_tries = 1

onready var server = get_node("../server")

# ------------------------------------------------------------- VIRTUAL METHODS

func _ready():
	$screens/game.queue_free()  # To get code completion.
	$screens/menu/middle/pointer.disable()


# TODO: Why doesn't emulate mouse from touch cause this to happen on mobile?
func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			Input.action_press("action")
		else:
			Input.action_release("action")


func _process(delta):
	_show_controls_timer += delta
	if _show_controls_timer > 2 and _show_controls_timer < 5 and not $music.playing:  # HACKY towards end of submission.
		$music.play()
	if _show_controls_timer > 9:
		$screens/menu/bottom/center/controls.visible = false
	else:
		$screens/menu/bottom/center/controls.visible = fmod(_show_controls_timer, 2) > 1.5

# -------------------------------------------------------------- PUBLIC METHODS

func show_network_message(msg, timeout=true):
	$top/status.visible = true
	$top/status.text = msg
	if timeout:
		$top/timer.start()


remote func set_player_details(details):
	Log.debug("all player details are", details)
	all_player_details = details
	player_details = all_player_details[get_tree().get_network_unique_id()]


remote func room_joined(which):
	#room = null
	$screens/menu.visible = false
	if game_node != null:
		game_node.name = "deleting"
		game_node.queue_free()
	game_node = GAME_SCREEN_SCENE.instance()
	$screens.add_child(game_node)
	game_node.connect("return_to_menu_selected", self, "_on_return_to_menu_selected")
	game_node.connect("play_again_selected", self, "_on_play_again_selected")
	$screens/game/player.in_game = false
	$screens/game/player.set_details(player_details.name, player_details.color, get_tree().get_network_unique_id())
	$screens/game/status.text = "next game starting shortly.."
	_update_room_details()
	#if room != null:
	#	_update_scoreboard()


remote func room_joined_failed(reason):
	Log.debug("Room joined failed:", reason)
	show_network_message(reason)
	$screens/menu/middle/pointer.reset()


remote func game_started(room_info):
	Log.debug("game_started", room_info)
	room = room_info
	_update_room_details()
	_update_scoreboard()
	var game = Common.GAMES[room_info.game_info.which].instance()
	$screens/game/game_container.add_child(game)
	yield(get_tree(), "idle_frame")
	game.setup(room_info.game_info)
	$screens/game/status.text = ""  # Something like this? game.objective
	$screens/game/player.in_game = true
	$screens/game/player.correct_answer = game.solution
	$screens/game/player.num_decimals = game.num_decimals
	$screens/game/player.scale_value = game.scale_value
	$screens/game/player.max_value = game.max_value
	$screens/game/player.reset()
	$screens/game/game_timer.wait_time = game.duration
	$screens/game/game_timer.start()
	$screens/game/dummy/objective.text = game.objective
	_add_opponents()
	game_node.show_game()
	_music_position = $music.get_playback_position()
	$music.stop()
	$screens/game/countdown/timer.wait_time = 1.0
	$screens/game/countdown.pitch_scale = 1.0
	$screens/game/countdown/timer.start()
	$screens/game/countdown.play()


remote func get_player_guess():
	#Log.debug("get_player_guess")
	server.rpc_id(1, "return_player_guess", room.which, game_node.get_node("player").current_value)


remote func waiting_to_start(time_left):
	$screens/game/status.text = "starting in %d.." % int(round(time_left))
	$screens/game/answer/label.text = ""


remote func room_updated(room_info):
	#Log.debug("Room update received")
	room = room_info
	_update_room_details()
	_update_opponents()


remote func game_finished(room_info):
	Log.debug("game_finished", room_info)
	room = room_info
	_update_room_details()
	
	var game = $screens/game/game_container/game
	for guess in range(game.solution+1):
		$screens/game/answer/label.text = _format_guess(game, guess)
		var noise = $screens/game/countup.get_node("noise"+str(guess%3))
		noise.pitch_scale = 0.75 + 0.01*guess
		noise.play()
		for node in $screens/game/opponents.get_children():
			if node.visible and room.player_guesses.keys().has(node.client_id):
				if room.player_guesses[node.client_id] == guess:
					node.show_value(guess)
		yield(get_tree().create_timer(3.0 / game.solution), "timeout")
	
	var winners = []
	for row in room.scoreboard:
		if row[1] == room.scoreboard[0][1]:
			winners.append(row[0])
	if winners.has(get_tree().get_network_unique_id()):
		$screens/game/player.celebrate()
	for node in $screens/game/opponents.get_children():
		if node.visible and winners.has(node.client_id):
			node.celebrate()
	
	_update_scoreboard()
	yield(get_tree().create_timer(3.0), "timeout")
	
	$screens/game/canvas_layer/gameover.visible = true
	$screens/game/canvas_layer/gameover/middle/pointer.reset()
	$music.play(_music_position)

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS

func _format_guess(game, guess):
	if game.num_decimals == 0:
		return str(int(guess * game.scale_value))
	else:
		return ("%%.%df" % game.num_decimals) % (guess * game.scale_value)


func _update_scoreboard():
	$screens/game/scoreboard/tween.stop_all()
	$screens/game/scoreboard/tween.interpolate_property($screens/game/scoreboard, "rect_position:x", 450, 650, 0.2, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$screens/game/scoreboard/tween.start()
	yield($screens/game/scoreboard/tween, "tween_all_completed")
	yield(get_tree().create_timer(0.2), "timeout")
	var t = ""
	var i = 0
	for row in room.scoreboard:
		i += 1
		var id = row[0]
		var score = row[1]
		var name = all_player_details[id].name
		var color = all_player_details[id].color
		t += "[rainbow freq=0.8 sat=3 val=1]" if score == 0 else ""
		t += "[shake rate=15 level=5]" if score == Common.POP_SCORE else ""
		t += "[color=%s]%s%d. %s[/color]\n" % [color, "*" if id == get_tree().get_network_unique_id() else "", i, name]
		t += "[/shake]" if score == Common.POP_SCORE else ""
		t += "[/rainbow]" if score == 0 else ""
	$screens/game/scoreboard.bbcode_text = "[right]" + t + "[/right]"
	$screens/game/scoreboard/tween.interpolate_property($screens/game/scoreboard, "rect_position:x", 650, 450, 0.2, Tween.TRANS_BACK, Tween.EASE_OUT)
	$screens/game/scoreboard/tween.start()
	yield($screens/game/scoreboard/tween, "tween_all_completed")


func _update_room_details():
	$screens/game/details.bbcode_text = DETAILS_TEMPLATE % [
		room.which if room != null else "",
		room.number if room != null else "",
		room.players.size() + room.waiting.size() if room != null else "",
	]


func _add_opponents():
	Log.debug("adding opponents")
	for node in $screens/game/opponents.get_children():
		node.reset()
		node.visible = false
	var order = range($screens/game/opponents.get_child_count())
	order.shuffle()
	for id in room.players:
		if id != get_tree().get_network_unique_id():
			var i = order.pop_front()
			var name = all_player_details[id].name
			var color = all_player_details[id].color
			var node = $screens/game/opponents.get_node(str(i))
			node.visible = true
			node.set_details(name, color, id)
			node.correct_answer = $screens/game/game_container/game.solution
			node.num_decimals = $screens/game/game_container/game.num_decimals
			node.scale_value = $screens/game/game_container/game.scale_value
			node.max_value = $screens/game/game_container/game.max_value


func _update_opponents():
	for node in $screens/game/opponents.get_children():
		if node.visible and room.player_guesses.keys().has(node.client_id):
			#Log.debug("updating", node.client_id, "guess to", room.player_guesses[node.client_id])
			node.current_value = room.player_guesses[node.client_id]


func _on_client_connected_to_server():
	var client_id = get_tree().get_network_unique_id()
	Log.debug("Connected to server succeeded, network id =", client_id)
	show_network_message("successfully connected to server")
	$screens/menu/middle/pointer.reset()
	$screens/menu.show()
	_show_controls_timer = 0.0


func _on_client_connection_failed():
	Log.debug("Connected to server failed.")
	show_network_message("failed to connect to server", false)
	if game_node != null:
		game_node.name = "deleting"
		game_node.queue_free()
	$reconnect_timer.start()


func _on_client_server_disconnected():
	Log.debug("Disconnected from server.")
	show_network_message("disconnected from server", false)
	if game_node != null:
		game_node.name = "deleting"
		game_node.queue_free()
	$reconnect_timer.start()


func _on_menu_pointer_option_selected(name):
	server.rpc_id(1, "join_room", name)


func _on_return_to_menu_selected():
	$screens/menu.visible = true
	$screens/menu/middle/pointer.reset()
	game_node.queue_free()
	server.rpc_id(1, "return_to_lobby", room.which)


func _on_play_again_selected():
	$screens/game/canvas_layer/gameover.visible = false
	$screens/game/canvas_layer/gameover/middle/pointer.reset()
	$screens/game/canvas_layer/gameover/middle/pointer.disable()
	server.rpc_id(1, "join_room", room.which)


func _on_timer_timeout():
	$top/status.visible = false


func _on_reconnect_timer_timeout():
	if _connect_tries >= 3:
		show_network_message("failed to connect to server after 3 attempts, sorry :(")
		return
	_connect_tries += 1
	show_network_message("connecting to server (attempt %d)..." % _connect_tries, false)
	Network.init_client(self, true)
