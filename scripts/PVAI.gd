extends Node

@export var circle_scene: PackedScene
@export var cross_scene: PackedScene

# Board and game state variables
var board_size: int
var cell_size: int
var grid_data: Array
var player: int
var temp_marker
var player_panel_pos: Vector2i
var winner: int
var moves: int

func _ready():
	board_size = $Board.texture.get_width()
	cell_size = int(board_size / 3.0)  # Explicitly cast to int
	player_panel_pos = $PlayerPanel.get_position()
	new_game()

func _process(_delta):
	pass

func create_marker(marker_player, position, temp = false):
	var marker = (circle_scene if marker_player == 1 else cross_scene).instantiate()
	marker.position = position
	add_child(marker)
	if temp:
		temp_marker = marker

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.x < board_size:
			var x = int(event.position.x / float(cell_size))  # Use float division
			var y = int(event.position.y / float(cell_size))  # Use float division
			if grid_data[y][x] == 0 and player == 1:
				moves += 1
				grid_data[y][x] = player
				@warning_ignore("narrowing_conversion")
				create_marker(player, Vector2i(x, y) * cell_size + Vector2i(cell_size / 2.0, cell_size / 2.0))

				if check_end_state():
					return

				player *= -1
				if temp_marker:
					temp_marker.queue_free()
				@warning_ignore("narrowing_conversion")
				create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)

				if player == -1:
					best_move()

func new_game():
	moves = 0
	player = 1
	winner = 0
	grid_data = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
	temp_marker = null
	get_tree().call_group("crosses", "queue_free")
	get_tree().call_group("circles", "queue_free")
	@warning_ignore("narrowing_conversion")
	create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)
	$GameOverMenu.hide()
	get_tree().paused = false

func check_winner_grid(grid):
	# Check rows and columns
	for i in range(3):
		var row = grid[i]
		if abs(row[0] + row[1] + row[2]) == 3:
			return row[0]
		var col = [grid[0][i], grid[1][i], grid[2][i]]
		if abs(col[0] + col[1] + col[2]) == 3:
			return col[0]
	
	# Check diagonals
	var diag1 = grid[0][0] + grid[1][1] + grid[2][2]
	var diag2 = grid[0][2] + grid[1][1] + grid[2][0]
	if abs(diag1) == 3:
		return grid[0][0]
	if abs(diag2) == 3:
		return grid[0][2]
	
	return 0  # No winner

func check_winner():
	return check_winner_grid(grid_data)

func check_end_state():
	winner = check_winner()
	if winner != 0:
		$GameOverMenu.get_node("ResultLabel").text = "Player 1 wins!" if winner == 1 else "Player 2 wins!"
		$GameOverMenu.show()
		get_tree().paused = true
		return true
	elif moves == 9:
		$GameOverMenu.get_node("ResultLabel").text = "It's a draw!"
		$GameOverMenu.show()
		get_tree().paused = true
		return true
	return false

func copy_grid(grid):
	var new_grid = []
	for row in grid:
		new_grid.append(row.duplicate())
	return new_grid

func minimax(grid, depth, is_maximizing):
	var result = check_winner_grid(grid)
	if result == -1:  # AI wins
		return 10 - depth
	elif result == 1:  # Human wins
		return depth - 10
	elif is_grid_full(grid):
		return 0  # Draw

	if is_maximizing:
		var best_score = -INF
		for y in range(3):
			for x in range(3):
				if grid[y][x] == 0:
					var new_grid = copy_grid(grid)
					new_grid[y][x] = -1  # AI's move
					var score = minimax(new_grid, depth + 1, false)
					best_score = max(best_score, score)
		return best_score
	else:
		var best_score = INF
		for y in range(3):
			for x in range(3):
				if grid[y][x] == 0:
					var new_grid = copy_grid(grid)
					new_grid[y][x] = 1  # Human's move
					var score = minimax(new_grid, depth + 1, true)
					best_score = min(best_score, score)
		return best_score

func is_grid_full(grid):
	for y in range(3):
		for x in range(3):
			if grid[y][x] == 0:
				return false
	return true

func best_move():
	var _best_score = -INF  # Renamed to avoid unused variable warning
	var _best_move = Vector2i(-1, -1)  # Renamed to avoid shadowing function name
	
	# First check if AI can win immediately
	for y in range(3):
		for x in range(3):
			if grid_data[y][x] == 0:
				var grid_copy = copy_grid(grid_data)
				grid_copy[y][x] = -1
				if check_winner_grid(grid_copy) == -1:
					_best_move = Vector2i(x, y)
					break
		if _best_move != Vector2i(-1, -1):
			break
	
	# Then check if player can win next turn (block)
	if _best_move == Vector2i(-1, -1):
		for y in range(3):
			for x in range(3):
				if grid_data[y][x] == 0:
					var grid_copy = copy_grid(grid_data)
					grid_copy[y][x] = 1
					if check_winner_grid(grid_copy) == 1:
						_best_move = Vector2i(x, y)
						break
			if _best_move != Vector2i(-1, -1):
				break
	
	# If no immediate win/block, use Minimax
	if _best_move == Vector2i(-1, -1):
		var highest_score = -INF
		for y in range(3):
			for x in range(3):
				if grid_data[y][x] == 0:
					var grid_copy = copy_grid(grid_data)
					grid_copy[y][x] = -1
					var current_score = minimax(grid_copy, 0, false)
					if current_score > highest_score:
						highest_score = current_score
						_best_move = Vector2i(x, y)
	
	# Execute the best move
	if _best_move != Vector2i(-1, -1):
		grid_data[_best_move.y][_best_move.x] = -1
		moves += 1
		@warning_ignore("narrowing_conversion")
		create_marker(-1, _best_move * cell_size + Vector2i(cell_size / 2.0, cell_size / 2.0))
		
		if check_end_state():
			return
		
		player *= -1
		if temp_marker:
			temp_marker.queue_free()
		@warning_ignore("narrowing_conversion")
		create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)

func _on_game_over_menu_restart_game():
	new_game()

func _on_go_to_menu_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")
