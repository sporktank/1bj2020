extends Control


export(float) var show_for = 3.5

var _time_shown = 0.0

onready var _logo = $Center/Logo
onready var _background = $Background


func _ready():
	if not SporkTank.splash_shown:
		visible = true
	SporkTank.splash_shown = true
	_logo.modulate.a = 0.0


func _process(delta):
	# TODO: Use Tween or something in the future.
	_time_shown += delta
	if _time_shown <= 0.5:
		_logo.modulate.a = 0.0
	elif _time_shown <= 1.0:
		_logo.modulate.a = (_time_shown - 0.5)/0.5
	elif _time_shown <= show_for - 1.0:
		_logo.modulate.a = 1.0
	elif _time_shown <= show_for - 0.5:
		_logo.modulate.a = (show_for - 0.5 - _time_shown)/0.5
	else:
		_logo.modulate.a = 0.0
		_background.modulate.a = (show_for - _time_shown)/0.5
	if _time_shown >= show_for:
		visible = false
		get_parent().remove_child(self)
		queue_free()
