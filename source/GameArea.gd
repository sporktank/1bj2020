extends Control
# [docstring]

# https://stackoverflow.com/questions/451426/how-do-i-calculate-the-area-of-a-2d-polygon

# ------------------------------------------------------------------ PROPERTIES

var duration = null
var solution = null
var difficulty = null
var objective = "Guess the area"
var max_value = 200
var scale_value = 0.5
var num_decimals = 1

var points = null

# ------------------------------------------------------------- VIRTUAL METHODS

func _process(delta):
	pass

# -------------------------------------------------------------- PUBLIC METHODS

func setup(game_info, server_only=false):
	
	var rng = RandomNumberGenerator.new()
	rng.seed = game_info.seed_num
	
	difficulty = game_info.difficulty
	duration = 12.0 + rng.randi() % 4 + (5 if difficulty == "hard" else 0)
	
	points = PoolVector2Array([])
	var num_points = 6 if difficulty == "easy" else 8
	for i in range(num_points):
		var angle = float(i) / num_points * 2*PI
		var dist = (rng.randf_range(1, 3.2) if difficulty == "easy" else rng.randf_range(2, 5)) * (sqrt(2) if i%2 == 1 else 1)
		points.append(Vector2(dist, 0).rotated(angle).round())
	if not server_only:
		$center/polygon.set_polygon(points)
		$center/polygon.scale = Vector2.ONE * 20 * (2 if difficulty == "easy" else 1.5)
		$center/grid.scale = Vector2.ONE * 1 * (2 if difficulty == "easy" else 1.5)
	
	var area = 0.0
	points.append(points[0])
	for i in range(points.size()-1):
		var a = points[i]
		var b = points[i+1]
		area += a.x*b.y - b.x*a.y
	area = 0.5*area
	
	solution = int(2*area)  # Game is played in integers.
	
	return self

# ------------------------------------------------- PRIVATE METHODS/CONNECTIONS
