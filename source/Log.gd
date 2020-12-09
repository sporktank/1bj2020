extends Node
# [docstring]

var _gui_text_node = null

# ------------------------------------------------------------------ PROPERTIES

# ------------------------------------------------------------- VIRTUAL METHODS

# -------------------------------------------------------------- PUBLIC METHODS

func set_gui_textbox(node):
	_gui_text_node = node


const NULL = "062a0413-d565-4b13-9e5e-bfb68a686cd2"
func debug(a=NULL, b=NULL, c=NULL, d=NULL, e=NULL, f=NULL, g=NULL, h=NULL):
	var dt = OS.get_datetime()
	var text = "%04d-%02d-%02d %02d:%02d:%02d [DEBUG]" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
	for i in [a, b, c, d, e, f, g, h]:
		if typeof(i) != TYPE_STRING or i != NULL:
			text += " " + str(i)  # TODO: Want space?
	print(text)
	if _gui_text_node != null:
		_gui_text_node.text += text + "\n"

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
