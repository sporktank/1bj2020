extends Node2D
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

const MAX_BALLOON_SCALE = 3.0

export(int) var max_value = 100
export(float) var scale_value = 1
export(int) var num_decimals = 0
export(int) var correct_answer = 50
export(bool) var is_opponent = false
export(NodePath) var _camera_path

var can_repeat = false
var current_value = 0
var popped = false
var in_game = false
var client_id = null
var _camera

# ------------------------------------------------------------- VIRTUAL METHODS

func _ready():
	reset()
	visible = not is_opponent
	if _camera_path:
		_camera = get_node(_camera_path)
	if is_opponent:
		$pop.volume_db = 4.0


func _process(delta):
	
	# Hacky last minute fix?
	if $blow.playing:
		if popped or not in_game:
			$blow.stop()
	
	if not is_opponent and in_game and not popped:
		
		if Input.is_action_just_pressed("action"):
			current_value += 1
			$echo_start_timer.start()
			if not $blow.playing:
				$blow.play()
			
		elif Input.is_action_just_released("action"):
			$echo_start_timer.stop()
			$echo_repeat_timer.stop()
			$blow.stop()
		
		if Input.is_action_pressed("action") and can_repeat:
			can_repeat = false
			current_value += 1
	
	if current_value > correct_answer:
		if not popped:
			pop()
		
	elif not popped:
		var pct = float(current_value) / float(max_value)
		$balloon.scale = Vector2.ONE * (1.0 + (MAX_BALLOON_SCALE-1.0) * pct)
		
		var value = current_value * scale_value
		$value.text = str(round(value)) if num_decimals == 0 else ("%%.%df" % num_decimals) % value

# -------------------------------------------------------------- PUBLIC METHODS

func set_details(name, color, client_id_):
	$name.text = name
	$avatar.modulate = Color(color)
	client_id = client_id_


func reset():
	client_id = null
	popped = false
	current_value = 0
	$echo_start_timer.stop()
	$echo_repeat_timer.stop()
	$value.visible = not is_opponent
	unpop()


func pop():
	popped = true
	$value.visible = false
	$tween.stop_all()
	$tween.interpolate_property($balloon, "scale", $balloon.scale, 20*Vector2.ONE, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.interpolate_property($balloon, "modulate:a", 1.0, 0.0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.start()
	$pop.play()
	$blow.stop()
	if _camera:
		_camera.shake(0.5, 100, 10)


func unpop():
	$tween.stop_all()
	$balloon.scale = Vector2.ONE


func show_value(value):
	current_value = value
	$value.visible = true


func celebrate():
	if popped:
		return
	var time = 0.0
	var step = 0.2
	for jump in range(3):
		$celebrate_tween.interpolate_property($avatar, "position:y", 0, -20, step, Tween.TRANS_QUAD, Tween.EASE_OUT, time)
		$celebrate_tween.interpolate_property($avatar, "position:y", -20, 0, step, Tween.TRANS_QUAD, Tween.EASE_IN, time+step)
		time += 2*step + 0.5*step
	$celebrate_tween.start()

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS

func _on_echo_start_timer_timeout():
	can_repeat = true
	$echo_repeat_timer.start()


func _on_echo_repeat_timer_timeout():
	can_repeat = true
