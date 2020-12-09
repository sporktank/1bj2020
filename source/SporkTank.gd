extends Node


const VERSION = "0.2"


var splash_shown = false


func _input(event):  # TODO: Make this unhandled?
	if event is InputEventKey and event.scancode == KEY_ESCAPE: get_tree().quit()
	#if event is InputEventKey and event.is_pressed() and event.scancode == KEY_R: get_tree().reload_current_scene()
	#if Input.is_action_just_pressed("fullscreen"):
	#	OS.window_fullscreen = not OS.window_fullscreen
	#	get_tree().set_input_as_handled()


# Screenshot generation.
func _process(_delta):
	if Input.is_action_just_pressed("screenshot"):
		
		# Setup.
		get_tree().paused = true
		get_viewport().set_clear_mode(Viewport.CLEAR_MODE_NEVER)
		var count
		for num in range(1, 1000):
			var file = File.new()
			if not file.file_exists("res://screenshots/screenshot%s-normal.png" % [num]):
				count = num
				break
		
		# Normal.
		yield(VisualServer, "frame_post_draw")
		var img = get_viewport().get_texture().get_data() ; img.flip_y()
		img.save_png("res://screenshots/screenshot%s-normal.png" % [count])
		
		# iOS sizes.
		var original_size = OS.get_window_size()
		var portrait = original_size.y > original_size.x
		var sizes = {
			"iphone-65": Vector2(1242, 2688) if portrait else Vector2(2688, 1242),
			"iphone-55": Vector2(1242, 2208) if portrait else Vector2(2208, 1242),
			"ipad": Vector2(2048, 2732) if portrait else Vector2(2732, 2048),
		}
		for key in sizes:
			var size = sizes[key]
			OS.set_window_size(size / 2)  # !! Full size doesn't fit on my monitor!
			yield(get_tree().create_timer(0.5), "timeout")
			yield(VisualServer, "frame_post_draw")
			img = get_viewport().get_texture().get_data() ; img.flip_y()
			img.resize(size.x, size.y, Image.INTERPOLATE_CUBIC)  # !!
			img.save_png("res://screenshots/screenshot%s-%s.png" % [count, key])
		
		# Restore.
		OS.set_window_size(original_size)
		get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
		get_tree().paused = false
