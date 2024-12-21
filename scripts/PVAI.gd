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
	cell_size = board_size / 3
	player_panel_pos = $PlayerPanel.get_position()
	new_game()

func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.x < board_size:
			var x = int(event.position.x / cell_size)
			var y = int(event.position.y / cell_size)
			if grid_data[y][x] == 0 and player == 1:
				moves += 1
				grid_data[y][x] = player
				create_marker(player, Vector2i(x, y) * cell_size + Vector2i(cell_size / 2, cell_size / 2))

				if check_end_state():
					return

				player *= -1
				if temp_marker:
					temp_marker.queue_free()
				create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)

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
	create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)
	$GameOverMenu.hide()
	get_tree().paused = false

func create_marker(player, position, temp = false):
	var marker = (circle_scene if player == 1 else cross_scene).instantiate()
	marker.position = position
	add_child(marker)
	if temp:
		temp_marker = marker

func check_winner():
	for i in range(3):
		if abs(grid_data[i][0] + grid_data[i][1] + grid_data[i][2]) == 3:
			return grid_data[i][0]
		if abs(grid_data[0][i] + grid_data[1][i] + grid_data[2][i]) == 3:
			return grid_data[0][i]

	if abs(grid_data[0][0] + grid_data[1][1] + grid_data[2][2]) == 3:
		return grid_data[0][0]
	if abs(grid_data[0][2] + grid_data[1][1] + grid_data[2][0]) == 3:
		return grid_data[0][2]

	return 0

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

func best_move():
	var best_score = -INF
	var move = Vector2i(-1, -1)

	# Check for immediate threats to block
	for y in range(3):
		for x in range(3):
			if grid_data[y][x] == 0:
				grid_data[y][x] = 1  # Simulate player's move
				if check_winner() == 1:  # Player can win
					grid_data[y][x] = -1  # Block the player
					moves += 1
					create_marker(player, Vector2i(x, y) * cell_size + Vector2i(cell_size / 2, cell_size / 2))
					if not check_end_state():
						player *= -1
						if temp_marker:
							temp_marker.queue_free()
						create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)
					return
				grid_data[y][x] = 0  # Reset the board

	# Detect double threats from the player and block if necessary
	for y in range(3):
		for x in range(3):
			if grid_data[y][x] == 0:
				grid_data[y][x] = 1
				if detect_double_threat():  # Player can create a double threat
					grid_data[y][x] = -1  # Block the setup
					moves += 1
					create_marker(player, Vector2i(x, y) * cell_size + Vector2i(cell_size / 2, cell_size / 2))
					if not check_end_state():
						player *= -1
						if temp_marker:
							temp_marker.queue_free()
						create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)
					return
				grid_data[y][x] = 0  # Reset the board

	# Use minimax to determine the best move if no immediate threat or double threat exists
	for y in range(3):
		for x in range(3):
			if grid_data[y][x] == 0:
				grid_data[y][x] = -1  # AI makes a move
				moves += 1
				var score = minimax(0, true)
				grid_data[y][x] = 0  # Undo the move
				moves -= 1
				if score > best_score:
					best_score = score
					move = Vector2i(x, y)

	# Execute the best move found
	grid_data[move.y][move.x] = -1
	moves += 1
	create_marker(player, move * cell_size + Vector2i(cell_size / 2, cell_size / 2))

	if not check_end_state():
		player *= -1
		if temp_marker:
			temp_marker.queue_free()
		create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)

func minimax(depth, is_maximizing):
	# Evaluate the board for a win/loss/draw
	var result = check_winner()
	if result == 1:  # Player wins
		return -10 + depth
	elif result == -1:  # AI wins
		return 10 - depth
	elif moves == 9:  # Draw
		return 0

	if is_maximizing:  # AI's turn
		var best_score = -INF
		for y in range(3):
			for x in range(3):
				if grid_data[y][x] == 0:
					grid_data[y][x] = -1  # AI makes a move
					moves += 1
					var score = minimax(depth + 1, false)
					grid_data[y][x] = 0  # Undo the move
					moves -= 1
					best_score = max(best_score, score)
		return best_score
	else:  # Player's turn
		var best_score = INF
		for y in range(3):
			for x in range(3):
				if grid_data[y][x] == 0:
					grid_data[y][x] = 1  # Player makes a move
					moves += 1
					var score = minimax(depth + 1, true)
					grid_data[y][x] = 0  # Undo the move
					moves -= 1
					best_score = min(best_score, score)
		return best_score

func detect_double_threat():
	# Checks if the player can create a double threat
	var threat_count = 0
	for y in range(3):
		for x in range(3):
			if grid_data[y][x] == 0:
				grid_data[y][x] = 1
				if check_winner() == 1:
					threat_count += 1
				grid_data[y][x] = 0
	return threat_count >= 2

func _on_game_over_menu_restart_game():
	new_game()

func _on_go_to_menu_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")
