extends Control
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

var game_type = null
var duration = null
var solution = null
var difficulty = null
var objective = "Count the dots"
var max_value = 100
var scale_value = 1
var num_decimals = 0

# ------------------------------------------------------------- VIRTUAL METHODS

func _process(delta):
	
	match game_type:
		"circle":
			for dot in $center.get_children():
				dot.rotation_degrees += 360*delta * (-1 if dot.flip_h else 1)
		
		"fly":
			var speed = 800.0/(duration-1)
			for dot in $center.get_children():
				dot.position.x += speed*delta * (1 if dot.flip_h else -1)

# -------------------------------------------------------------- PUBLIC METHODS

func setup(game_info, server_only=false):
	
	var rng = RandomNumberGenerator.new()
	rng.seed = game_info.seed_num
	
	difficulty = game_info.difficulty
	game_type = ["static", "circle", "fly"][rng.randi() % 3]
	duration = 8.0 + rng.randi() % 5
	solution = rng.randi_range(10, 30) if difficulty == "easy" else rng.randi_range(35, 70)
	
	var points = []
	for y in range(-160, 160+1, 40):
		for x in range(-160, 160+1, 40):
			points.append(Vector2(x, y))
	
	#points.shuffle()  # TODO: Not using rng above.
	var points_copy = points.duplicate()
	points.clear()
	while points_copy.size() > 0:
		var index = rng.randi() % points_copy.size()
		points.append(points_copy[index])
		points_copy.remove(index)
		
	for point in points.slice(0, solution-1):
		var dot = $dot.duplicate()
		dot.visible = true
		dot.position = Vector2(point)
		if game_type == "circle":
			dot.offset.y = 40
			dot.flip_h = bool(rng.randi()%2)
			dot.rotation_degrees = rng.randf_range(0, 360)
		if not server_only:
			$center.add_child(dot)
	
	if game_type == "fly" and not server_only:
		for dot in $center.get_children():
			dot.flip_h = bool(rng.randi()%2)
			dot.position.x += 400 * (-1 if dot.flip_h else 1)
	
	return self

#	solution = 0
#	for y in range(-160, 160+1, 40):
#		for x in range(-160, 160+1, 40):
#			if rng.randi() % 10 < 3:
#				solution += 1
#				var dot = $dot.duplicate()
#				dot.visible = true
#				dot.position = Vector2(x, y)
#				$center.add_child(dot)


# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
