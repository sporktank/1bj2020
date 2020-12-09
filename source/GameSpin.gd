extends Control
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

var game_type = null
var duration = null
var solution = null
var difficulty = null
var objective = "Count the revolutions"
var max_value = 50
var scale_value = 1
var num_decimals = 0

# ------------------------------------------------------------- VIRTUAL METHODS

# -------------------------------------------------------------- PUBLIC METHODS

func setup(game_info, server_only=false):
	
	var rng = RandomNumberGenerator.new()
	rng.seed = game_info.seed_num
	
	difficulty = game_info.difficulty
	duration = 9.0 + rng.randi() % 5
	
	var num_arrows = rng.randi_range(2, 3) if difficulty == "easy" else rng.randi_range(2, 5)
	var visible_arrows = range(5)
	var temp = visible_arrows.duplicate()
	visible_arrows.clear()
	while visible_arrows.size() < num_arrows:
		var index = rng.randi() % temp.size()
		visible_arrows.append(temp[index])
		temp.remove(index)
	
	for node in $center.get_children():
		node.visible = false
	
	solution = 0
	for index in visible_arrows:
		var node = $center.get_node("arrow" + str(index))
		node.visible = true
		var spins = rng.randi_range(2, 4) if difficulty == "easy" else rng.randi_range(2, 5)
		var dir = -1 if rng.randf() < 0.5 else 1
		if not server_only:
			$tween.interpolate_property(
				node, "rotation_degrees", 0, dir*360*spins, duration - 4, 
				[Tween.TRANS_LINEAR, Tween.TRANS_SINE][rng.randi()%2], 
				Tween.EASE_IN_OUT, 
				1.5
			)
		solution += spins
	if not server_only:
		$tween.start()
	
	return self

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
