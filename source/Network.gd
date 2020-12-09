extends Node
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

const POLL_STATUS = [NetworkedMultiplayerPeer.CONNECTION_CONNECTED, NetworkedMultiplayerPeer.CONNECTION_CONNECTING]
#const MAX_CLIENTS = 2  # Not sure how to specify using WS
const RUNNING_IN_CLOUD = true

var ws  # WebSocketServer or WebSocketClient

# ------------------------------------------------------------- VIRTUAL METHODS

func _process(delta):
	if ws is WebSocketClient and ws.get_connection_status() in POLL_STATUS:
		ws.poll()

# -------------------------------------------------------------- PUBLIC METHODS


func init_server(callback):
	get_tree().connect("network_peer_connected", callback, "_on_server_got_client_connection")
	get_tree().connect("network_peer_disconnected", callback, "_on_server_lost_client_connection")
	ws = WebSocketServer.new()
	if RUNNING_IN_CLOUD:
		ws.bind_ip = "*"
		ws.private_key = CryptoKey.new()
		ws.private_key.load("res://resources/privkey.key")
		ws.ssl_certificate = X509Certificate.new()
		ws.ssl_certificate.load("res://resources/cert.crt")
		ws.ca_chain = X509Certificate.new()
		ws.ca_chain.load("res://resources/chain.crt")
	ws.listen(44444, PoolStringArray(), true)
	get_tree().set_network_peer(ws)
#	ws = WebSocketServer.new()
#	ws.private_key = load("res://resources/private.key")
#	ws.ssl_certificate = load("res://resources/cert.crt")
#	prints(ws.private_key, ws.ssl_certificate)
#	ws.listen(server_port, PoolStringArray(), true)
#	get_tree().set_network_peer(ws)
#	prints(ws.private_key, ws.ssl_certificate, ws.ca_chain)
#	var error = ws.listen(server_port, PoolStringArray(), true)
#	print(error)


func init_client(callback, do_disconnect=false):
	if do_disconnect:
		get_tree().disconnect("connected_to_server", callback, "_on_client_connected_to_server")
		get_tree().disconnect("connection_failed", callback, "_on_client_connection_failed")
		get_tree().disconnect("server_disconnected", callback, "_on_client_server_disconnected")
		get_tree().set_network_peer(null)
		ws = null
	get_tree().connect("connected_to_server", callback, "_on_client_connected_to_server")
	get_tree().connect("connection_failed", callback, "_on_client_connection_failed")
	get_tree().connect("server_disconnected", callback, "_on_client_server_disconnected")
	ws = WebSocketClient.new()
	if RUNNING_IN_CLOUD:
		ws.trusted_ssl_certificate = load("res://resources/chain.crt")
		ws.verify_ssl = true
		ws.connect_to_url("wss://sporktanktest.ddns.net:44444", PoolStringArray(), true)
	else:
		ws.connect_to_url("ws://localhost:44444", PoolStringArray(), true)
	get_tree().set_network_peer(ws)
	#ws.trusted_ssl_certificate = load("res://resources/cert.crt")
	#ws.verify_ssl = true
	#ws.connect_to_url("ws://" + server_ip_address + ":" + str(server_port), PoolStringArray(), true)
	#ws.connect_to_url("wss://localhost:" + str(server_port), PoolStringArray(), true)
	#ws.connect_to_url("wss://" + server_ip_address + ":" + str(server_port), PoolStringArray(), true)
	#ws.trusted_ssl_certificate = X509Certificate.new()
	#ws.trusted_ssl_certificate.load("res://resources/chain.crt")
#	ws.trusted_ssl_certificate = load("res://resources/chain.crt")
#	ws.verify_ssl = true
#	#var error = ws.connect_to_url("wss://" + server_ip_address + ":" + str(server_port), PoolStringArray(), true)
#	var error = ws.connect_to_url("wss://sporktanktest.ddns.net:44444", PoolStringArray(), true)
#	#print("wss://" + server_ip_address + ":" + str(server_port))
#	print(error)
#	get_tree().set_network_peer(ws)

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
