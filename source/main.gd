extends Control
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

# ------------------------------------------------------------- VIRTUAL METHODS

func _ready():
	if "server" in OS.get_cmdline_args():
		#$client.queue_free()
		$client.visible = false
		$client.pause_mode = Node.PAUSE_MODE_STOP
		Network.init_server($server)
	else:
		Network.init_client($client)

# -------------------------------------------------------------- PUBLIC METHODS

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
