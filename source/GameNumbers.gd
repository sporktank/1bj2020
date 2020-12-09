extends Control
# [docstring]

# ------------------------------------------------------------------ PROPERTIES

const MULTIPLY_CHAR = "×"
const DIVIDE_CHAR = "÷"

var game_type = null
var duration = null
var solution = null
var difficulty = null
var objective = "Add the numbers"
var max_value = 250
var scale_value = 1
var num_decimals = 0

# ------------------------------------------------------------- VIRTUAL METHODS

# -------------------------------------------------------------- PUBLIC METHODS

func setup(game_info, server_only=false):
	
	var rng = RandomNumberGenerator.new()
	rng.seed = game_info.seed_num
	
	difficulty = game_info.difficulty
	duration = 8.0 + rng.randi() % 5
	if difficulty == "hard":
		duration += 4.0
	
	var num_numbers = rng.randi_range(3, 5) if difficulty == "easy" else rng.randi_range(5, 8)
	var visible_numbers = range(8)
	var temp = visible_numbers.duplicate()
	visible_numbers.clear()
	while visible_numbers.size() < num_numbers:
		var index = rng.randi() % temp.size()
		visible_numbers.append(temp[index])
		temp.remove(index)
	
	for node in $center.get_children():
		node.visible = false
	
	solution = 0
	for index in visible_numbers:
		var node = $center.get_node("number" + str(index))
		node.visible = true
		var pr_mult = 0.15 if difficulty == "easy" else 0.3
		if rng.randf() < pr_mult:
			var n1 = rng.randi_range(2, 6) if difficulty == "easy" else rng.randi_range(3, 8)
			var n2 = rng.randi_range(2, 6) if difficulty == "easy" else rng.randi_range(3, 8)
			solution += n1 * n2
			node.text = "%d%s%s" % [n1, MULTIPLY_CHAR, n2]
		else:
			var n = rng.randi_range(6, 15)
			solution += n
			node.text = str(n)
	
	return self

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
