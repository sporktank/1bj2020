extends Sprite
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

signal option_selected(name)

export(float) var countdown_length = 5.0

export(NodePath) var option_null = null
export(NodePath) var option_1 = null
export(NodePath) var option_2 = null
export(NodePath) var option_3 = null
export(NodePath) var option_4 = null

var option_nodes = []
var current_option_index = 0
var option_emitted = false

onready var countdown_value = countdown_length

# ------------------------------------------------------------- VIRTUAL METHODS

func _ready():
	
	assert(option_null != null and option_1 != null)
	option_nodes.append(get_node(option_null))
	option_nodes.append(get_node(option_1))
	if option_2 != null: option_nodes.append(get_node(option_2))
	if option_3 != null: option_nodes.append(get_node(option_3))
	if option_4 != null: option_nodes.append(get_node(option_4))


func _process(delta):
	
	if option_emitted:
		return
	
	if Input.is_action_just_pressed("action"):
		current_option_index = (current_option_index + 1) % option_nodes.size()
		if current_option_index == 0:
			countdown_value = countdown_length
	
	if current_option_index != 0:
		countdown_value -= delta
	
	if countdown_value <= 0.0:
		countdown_value = 0.0
		emit_signal("option_selected", option_nodes[current_option_index].name)
		$click.play()
		option_emitted = true
	
	_update_pointer()

# -------------------------------------------------------------- PUBLIC METHODS

func reset():
	option_emitted = false
	current_option_index = 0
	countdown_value = countdown_length
	_update_pointer()


func disable():
	option_emitted = true

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS

func _update_pointer():
	var n = option_nodes[current_option_index]
	position.y = n.rect_position.y + 0.5*n.rect_size.y  # TODO: Bit hacky.
	$countdown.text = "%.1f" % countdown_value
	$countdown2.rect_size.x = clamp(25.0 * countdown_value / countdown_length, 0.0, 50.0)
