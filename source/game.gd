extends Control
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

signal play_again_selected
signal return_to_menu_selected

# ------------------------------------------------------------- VIRTUAL METHODS

func _ready():
	$game_container/game.queue_free()  # For code completion.
	$canvas_layer/gameover/middle/pointer.disable()


func _process(delta):
	if not $game_timer.is_stopped():
		#$status.text = str(int($game_timer.time_left))  # TODO: Better feedback.
		$status.text = ""
		$timer_bg/color_rect.rect_size.x = 92.0 * $game_timer.time_left / $game_timer.wait_time

# -------------------------------------------------------------- PUBLIC METHODS

func show_game():
	$game_container/tween.stop_all()
	$game_container/tween.interpolate_property(
		$game_container/cover, "position:y", 
		$game_container/cover.position.y, 
		-400.0,
		0.5, Tween.TRANS_QUAD, Tween.EASE_OUT
	)
	$game_container/tween.start()


func hide_game():
	$game_container/tween.stop_all()
	$game_container/tween.interpolate_property(
		$game_container/cover, "position:y", 
		$game_container/cover.position.y, 
		0.0,
		0.5, Tween.TRANS_BACK, Tween.EASE_OUT
	)
	$game_container/tween.start()

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS

func _on_game_timer_timeout():
	$player.in_game = false
	$status.text = ""
	$countdown/timer.stop()
	hide_game()


func _on_pointer_option_selected(name):
	if name == "play_again":
		emit_signal("play_again_selected")
	elif name == "return_to_menu":
		emit_signal("return_to_menu_selected")


func _on_timer_timeout():
	$countdown.stop()
	$countdown.pitch_scale += 0.025
	$countdown.play()
	$countdown/timer.wait_time *= 0.96
	$countdown/timer.start()
