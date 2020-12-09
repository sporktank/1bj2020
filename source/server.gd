extends Node2D
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

enum STATE {WAITING, PRE_GAME, IN_GAME, COLLECT_GUESSES, POST_GAME}

const POLL_RATE = 0.25
const MAX_PLAYERS_PER_ROOM = 20

var rooms = {
	lobby={players=[]},
	easy={which="easy", number=0, state=STATE.WAITING, timer=5.0, players=[], waiting=[], game_info=null, player_guesses={}, scoreboard=[]},
	hard={which="hard", number=0, state=STATE.WAITING, timer=5.0, players=[], waiting=[], game_info=null, player_guesses={}, scoreboard=[]},
}

var available_names = Common.NAMES.duplicate()
var available_colors = Common.COLORS.duplicate()
var all_players = {}
var poll_time = 0.0

onready var client = get_node("../client")

# ------------------------------------------------------------- VIRTUAL METHODS

func _ready():
	randomize()


func _process(delta):
	poll_time += delta
	if poll_time >= POLL_RATE:
		for room in rooms:
			if room != "lobby":
				_update_room(rooms[room], POLL_RATE)
		poll_time = 0.0

# -------------------------------------------------------------- PUBLIC METHODS

remote func join_room(which):
	var client_id = get_tree().get_rpc_sender_id()
	Log.debug(client_id, "join_room", which)
	
	if rooms[which].players.size() + rooms[which].waiting.size() >= MAX_PLAYERS_PER_ROOM:
		client.rpc_id(client_id, "room_joined_failed", "too many players already")
		return
	
	rooms.lobby.players.erase(client_id)
	rooms[which].waiting.append(client_id)
	Log.debug(rooms)
	
	client.rpc_id(client_id, "room_joined", which)
	#for id in rooms[which].players + rooms[which].waiting: 
	#	client.rpc_id(id, "player_joined", client_id)


remote func return_player_guess(room, value):
	rooms[room].player_guesses[get_tree().get_rpc_sender_id()] = value


remote func return_to_lobby(which):
	var client_id = get_tree().get_rpc_sender_id()
	if rooms[which].players.has(client_id):
		rooms[which].players.erase(client_id)
		rooms.lobby.players.append(client_id)
	elif rooms[which].waiting.has(client_id):
		rooms[which].waiting.erase(client_id)
		rooms.lobby.players.append(client_id)

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS

func _on_server_got_client_connection(client_id):
	Log.debug("Client", client_id, "connected.")
	rooms.lobby.players.append(client_id)
	available_colors.shuffle()
	available_names.shuffle()
	all_players[client_id] = {name=available_names.pop_front(), color=available_colors.pop_front()}
	client.rpc("set_player_details", all_players)


func _on_server_lost_client_connection(client_id):
	Log.debug("Client", client_id, "disconnected.")
	if all_players.keys().has(client_id):
		available_names.push_back(all_players[client_id].name)
		available_colors.push_back(all_players[client_id].color)
		all_players.erase(client_id)
	for room in rooms:
		if rooms[room].players.has(client_id):
			rooms[room].players.erase(client_id)
		if room != "lobby" and rooms[room].waiting.has(client_id):
			rooms[room].waiting.erase(client_id)


func _update_room(room, delta):
	
	match room.state:
		
		STATE.WAITING:
			if room.waiting.size() > 0:
				room.state = STATE.PRE_GAME
				room.timer = 5.0
		
		STATE.PRE_GAME:
			room.timer -= delta
			if room.players.size() == 0 and room.waiting.size() == 0:
				room.state = STATE.WAITING
			elif room.timer > 0.0:
				for id in room.players + room.waiting: 
					client.rpc_unreliable_id(id, "waiting_to_start", room.timer)
			else:
				room.state = STATE.IN_GAME
				room.number += 1
				for id in room.waiting:
					room.players.append(id)
				room.waiting.clear()
				room.game_info = Common.generate_random_game_info(room.which)
				var game = Common.GAMES[room.game_info.which].instance().setup(room.game_info, true)
				room.timer = 1.0 + game.duration
				room.solution = game.solution
				game.free()
				# Remove players who have left before next game.
				var scoreboard_copy = room.scoreboard.duplicate()
				room.scoreboard.clear()
				for row in scoreboard_copy:
					if room.players.has(row[0]):
						room.scoreboard.append(row)
				for id in room.players: 
					client.rpc_id(id, "game_started", room)
		
		STATE.IN_GAME:
			room.timer -= delta
			if room.timer > 0.0:
				for id in room.players:
					client.rpc_unreliable_id(id, "get_player_guess")
					client.rpc_unreliable_id(id, "room_updated", room)
			else:
				room.timer = 5.0
				room.state = STATE.COLLECT_GUESSES
				for id in room.players:
					client.rpc_id(id, "get_player_guess")
		
		STATE.COLLECT_GUESSES:
			room.timer -= delta
			if room.player_guesses.size() == room.players.size() or room.timer < 0.0:
				_update_scoreboard(room)
				room.timer = 6.0
				room.state = STATE.POST_GAME
				for id in room.players:
					client.rpc_id(id, "game_finished", room)
					#room.waiting.append(id)
				room.players.clear()
				room.player_guesses.clear()
		
		STATE.POST_GAME:
			room.timer -= delta
			if room.timer <= 0.0:
				room.timer = 10.0
				room.state = STATE.WAITING


func _sort_func(a, b):
	return true if a[1] < b[1] else false


func _calc_score(guess, correct):
	return Common.POP_SCORE if guess > correct else correct - guess


func _update_scoreboard(room):
	var old_scoreboard = room.scoreboard
	var correct_guess = room.solution
	var seen = []
	room.scoreboard = []
	for row in old_scoreboard:
		if room.player_guesses.keys().has(row[0]):
			seen.append(row[0])
			room.scoreboard.append([row[0], _calc_score(room.player_guesses[row[0]], correct_guess)])
	for id in room.player_guesses:
		if not seen.has(id):
			room.scoreboard.append([id, _calc_score(room.player_guesses[id], correct_guess)])
	room.scoreboard.sort_custom(self, "_sort_func")
