extends Node

# Exported PackedScenes for the circle and cross markers, used to instantiate markers on the board dynamically.
@export var circle_scene: PackedScene  # Scene for player 1's marker (circle)
@export var cross_scene: PackedScene   # Scene for player 2's marker (cross)

# Board and game state variables
var board_size: int  				# The size (width and height) of the board texture, used for calculating grid placement.
var cell_size: int   				# The size of each cell within the grid (determined by board_size / 3 for a 3x3 grid).
var grid_data: Array 				# A 2D array representing the tic-tac-toe board (0 = empty, 1 = player 1, -1 = player 2).
var player: int  					# The current player (1 for Player 1, -1 for AI or Player 2 in multiplayer).
var temp_marker  					# Temporary marker used to preview the player's move before placing it.
var player_panel_pos: Vector2i  	# The position where the player's marker preview appears before making a move.
var winner: int 					# Indicates the winner of the game (1 for Player 1, -1 for Player 2, 0 if no winner yet).
var moves: int  					# Tracks the number of moves made in the game, useful for detecting draws.

# Called when the node enters the scene tree for the first time.
func _ready():
	board_size = $Board.texture.get_width()  		# Retrieve the board texture width to determine grid dimensions.
	cell_size = int(board_size / 3.0)  				# Calculate the individual cell size for the 3x3 grid.
	player_panel_pos = $PlayerPanel.get_position()  # Store the initial position of the player's panel (UI hint).
	new_game()  									# Start a new game when the scene is first loaded.

# Called every frame. Not used here but may be useful for future extensions.
func _process(_delta):
	pass

"""
@func new_game

@desc Resets the game state and starts a new game. It clears the board, sets the player to 1, and creates the first marker.
"""
func new_game():
	moves 		= 0  								# Reset move counter.
	player 		= 1  								# Player 1 always starts first.
	winner 		= 0  								# No winner at the beginning.
	grid_data 	= [[0, 0, 0], [0, 0, 0], [0, 0, 0]] # Reset the game board to an empty state.
	temp_marker = null  							# Clear the temporary marker preview.
	
	# Remove all existing markers from the board.
	get_tree().call_group("crosses", "queue_free")
	get_tree().call_group("circles", "queue_free")
	
	# Create the first player's marker preview at their panel.
	create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)
	
	# Hide the game over menu and ensure the game is active.
	$GameOverMenu.hide()
	get_tree().paused = false							# Unpause the game if it was paused

"""
@func create_marker

@desc Creates a marker (either a circle or cross) at the specified position on the board.

@param marker_player : 	The player who owns the marker (1 for player 1, -1 for player 2)
@param position		 : 	The position where the marker should be placed
@param temp 		 : 	Whether the marker is temporary (used for previewing a move) default is false
"""
func create_marker(marker_player, position, temp = false):
	var marker = (circle_scene if marker_player == 1 else cross_scene).instantiate()  # Instantiate the marker scene based on the player (1 for circle, else for cross)
	marker.position = position                                                        # Assign the marker's position on the board.
	add_child(marker)                                                                 # Add the marker to the game scene.
	if temp: temp_marker = marker                                                     # Store the temporary marker if previewing the move.

"""
@func _input

@desc Handles input events, specifically mouse button clicks. It checks if the click is within the board boundaries.

@param event : The input event that triggered this function
"""
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.x < board_size:  						# Ensure click is within the board boundary.
			var x = int(event.position.x / float(cell_size)) 	# Convert mouse X position to grid coordinates.
			var y = int(event.position.y / float(cell_size))  	# Convert mouse Y position to grid coordinates.
			
			if grid_data[y][x] == 0 and player == 1:  			# Only allow Player 1 to place moves.
				moves += 1  									# Increment move counter.
				grid_data[y][x] = player  						# Mark the move on the grid.
				create_marker(player, Vector2i(x, y) * cell_size + Vector2i(cell_size / 2.0, cell_size / 2.0))
				
				if check_end_state():
					return  # Stop further execution if the game has ended.
				
				player *= -1  # Switch to Player 2 (AI in single-player mode).
				if temp_marker:
					temp_marker.queue_free()  # Remove preview marker.
				create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)
				
				if player == -1:
					best_move()  # AI calculates and makes the best move.


"""
@func check_winner_grid

@desc Checks for a winner by evaluating rows, columns, and diagonals.

@param grid : The grid to check for a winner
@return : The winner (1 for player 1, -1 for player 2, 0 for no winner)
"""
func check_winner_grid(grid):
	# Check rows and columns for a winner
	for i in range(3):
		var row = grid[i]
		if abs(row[0] + row[1] + row[2]) == 3:  # If all elements in the row are the same (sum = 3 or -3)
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

"""
@func check_winner

@desc Calls check_winner_grid on the grid data to get the winner.

@return : The winner (1 for player 1, -1 for player 2, 0 for no winner)
"""
func check_winner():
	return check_winner_grid(grid_data)

"""
@func check_end_state

@desc Checks if the game has ended by determining if there is a winner or a draw.

@return : True if the game has ended, False otherwise
"""
func check_end_state():
	winner = check_winner()  		# Get the winner
	if winner != 0:
		$GameOverMenu.get_node("ResultLabel").text = "Player 1 wins!" if winner == 1 else "Player 2 wins!"
		$GameOverMenu.show()  		# Display the game over menu
		get_tree().paused = true  	# Pause the game
		return true
	elif moves == 9: 				 # Check for a draw (9 moves means the board is full)
		$GameOverMenu.get_node("ResultLabel").text = "It's a draw!"
		$GameOverMenu.show()  		# Display the game over menu
		get_tree().paused = true  	# Pause the game
		return true
	return false

"""
@func copy_grid

@desc Makes a copy of the grid.

@param grid : The grid to copy
@return : A new copy of the grid
"""
func copy_grid(grid):
	var new_grid = []
	for row in grid:
		new_grid.append(row.duplicate())  # Duplicate each row of the grid
	return new_grid

"""
@func minimax

@desc Minimax algorithm for calculating the best move (recursive).

@param grid : The current state of the grid
@param depth : The depth of the recursion (used to prioritize faster wins)
@param is_maximizing : Whether the current player is maximizing (AI) or minimizing (human)
@return : The score of the best move
"""
func minimax(grid, depth, is_maximizing):
	var result = check_winner_grid(grid)
	if result == -1:  # AI wins
		return 10 - depth
	elif result == 1:  # Human wins
		return depth - 10
	elif is_grid_full(grid):  # Check for a draw (grid is full)
		return 0

	if is_maximizing:  # Maximizing player (AI)
		var best_score = -INF
		for y in range(3):
			for x in range(3):
				if grid[y][x] == 0:  # If the cell is empty
					var new_grid = copy_grid(grid)
					new_grid[y][x] = -1  # Make AI's move
					var score = minimax(new_grid, depth + 1, false)  # Recursively evaluate the move
					best_score = max(best_score, score)  # Maximize the score for the AI
		return best_score
	else:  # Minimizing player (Human)
		var best_score = INF
		for y in range(3):
			for x in range(3):
				if grid[y][x] == 0:  # If the cell is empty
					var new_grid = copy_grid(grid)
					new_grid[y][x] = 1  # Make human's move
					var score = minimax(new_grid, depth + 1, true)  # Recursively evaluate the move
					best_score = min(best_score, score)  # Minimize the score for the human
		return best_score

"""
@func is_grid_full

@desc Checks if the grid is full (no empty cells).

@param grid : The grid to check
@return : True if the grid is full, False otherwise
"""
func is_grid_full(grid):
	for y in range(3):
		for x in range(3):
			if grid[y][x] == 0:  # If there's an empty cell
				return false
	return true

"""
@func best_move

@desc Determines the best move for the AI by first checking for an immediate win or block.
If neither is possible, the Minimax algorithm is used to choose the best move.
"""
func best_move():
	var _best_score = -INF
	var _best_move = Vector2i(-1, -1)

	# Check if AI can win immediately
	for y in range(3):
		for x in range(3):
			if grid_data[y][x] == 0:
				var grid_copy = copy_grid(grid_data)
				grid_copy[y][x] = -1  # AI's move
				if check_winner_grid(grid_copy) == -1:
					_best_move = Vector2i(x, y)  # AI wins with this move
					break
		if _best_move != Vector2i(-1, -1):
			break

	# Check if player can win next turn and block it
	if _best_move == Vector2i(-1, -1):
		for y in range(3):
			for x in range(3):
				if grid_data[y][x] == 0:
					var grid_copy = copy_grid(grid_data)
					grid_copy[y][x] = 1  # Player's move
					if check_winner_grid(grid_copy) == 1:
						_best_move = Vector2i(x, y)  # Block player's winning move
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
					grid_copy[y][x] = -1  # AI's move
					var current_score = minimax(grid_copy, 0, false)
					if current_score > highest_score:
						highest_score = current_score
						_best_move = Vector2i(x, y)

	# Execute the best move
	if _best_move != Vector2i(-1, -1):
		grid_data[_best_move.y][_best_move.x] = -1
		moves += 1
		create_marker(-1, _best_move * cell_size + Vector2i(cell_size / 2.0, cell_size / 2.0))  # Place AI's marker
		
		if check_end_state():
			return
		
		player *= -1  # Switch back to the human player
		if temp_marker:
			temp_marker.queue_free()  # Remove the temporary marker
		create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)  # Create preview marker for player

"""
@func _on_game_over_menu_restart_game

@desc Called when the game over menu's "Restart" button is pressed. Resets the game state.
"""
func _on_game_over_menu_restart_game():
	new_game()  # Start a new game

"""
@func _on_go_to_menu_pressed

@desc Called when the "Go to Menu" button is pressed in the game over menu. Changes the scene to the main menu.
"""
func _on_go_to_menu_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")  # Go back to the main menu
