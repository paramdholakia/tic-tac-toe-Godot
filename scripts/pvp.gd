extends Node
@export var circle_scene : PackedScene
@export var cross_scene : PackedScene

# board size
var board_size : int
var cell_size  : int
var grid_pos : Vector2i
var grid_data : Array
var player : int
var temp_marker
var player_panel_pos : Vector2i
var winner : int
var moves : int
var row_sum : int
var col_sum : int
var diag1_sum : int
var diag2_sum : int

func _ready():
	board_size = $Board.texture.get_width()
	cell_size = board_size / 3
	player_panel_pos = $PlayerPanel.get_position()
	player = 1
	winner = 0
	
	new_game()

func _process(delta):
	pass

func _input(event):
	if event is InputEventKey and event.alt_pressed and event.scancode == KEY_ENTER:
		event.consume()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.position.x < board_size:
				# Convert mouse position to grid position
				var x = int(event.position.x / cell_size)
				var y = int(event.position.y / cell_size)
				grid_pos = Vector2i(x, y)
				if grid_data[grid_pos.y][grid_pos.x] == 0:
					moves += 1
					grid_data[y][x] = player
					create_marker(player, grid_pos * cell_size + Vector2i(cell_size / 2.0, cell_size / 2.0))
					
					# Check for winner
					winner = check_winner()
					if winner != 0:
						# Show game over menu with winner message
						if winner == 1:
							$GameOverMenu.get_node("ResultLabel").text = "Player 1 wins!"
						elif winner == -1:
							$GameOverMenu.get_node("ResultLabel").text = "Player 2 wins!"
						$GameOverMenu.show()
						get_tree().paused = true
						return  # Exit early if the game is over

					# Check for tie
					if moves == 9 and winner == 0:
						$GameOverMenu.get_node("ResultLabel").text = "It's a draw!"
						$GameOverMenu.show()
						get_tree().paused = true
						return  # Exit early if the game is over

					# Switch players
					player *= -1
					if temp_marker != null:
						temp_marker.queue_free()
					create_marker(player, player_panel_pos + Vector2i(cell_size / 2.0, cell_size / 2.0), true)
					print(grid_data)

func new_game():
	# Restart variables
	moves = 0
	player = 1
	winner = 0
	row_sum = 0
	col_sum = 0
	diag1_sum = 0
	diag2_sum = 0
	grid_data = [	[0, 0, 0], 
					[0, 0, 0], 
					[0, 0, 0]
				]
	temp_marker = null  # Ensure temp_marker is initialized
	get_tree().call_group("crosses", "queue_free")
	get_tree().call_group("circles", "queue_free")
	# Create a marker to show starting player
	create_marker(player, player_panel_pos + Vector2i(cell_size/2, cell_size/2), true)
	$GameOverMenu.hide()
	get_tree().paused = false

func create_marker(player, position, temp=false):
	if player == 1:
		if circle_scene == null:
			print("circle_scene is not assigned!")
			return
		var circle = circle_scene.instantiate()
		circle.position = position
		add_child(circle)
		if temp: temp_marker = circle
	else:
		if cross_scene == null:
			print("cross_scene is not assigned!")
			return
		var cross = cross_scene.instantiate()
		cross.position = position
		add_child(cross)
		if temp: temp_marker = cross

func check_winner():
	for i in range(3):
		# Check rows and columns
		row_sum = grid_data[i][0] + grid_data[i][1] + grid_data[i][2]
		col_sum = grid_data[0][i] + grid_data[1][i] + grid_data[2][i]
		if row_sum == 3 or col_sum == 3:
			return 1  # Player 1 wins
		elif row_sum == -3 or col_sum == -3:
			return -1  # Player 2 wins

	# Check diagonals
	diag1_sum = grid_data[0][0] + grid_data[1][1] + grid_data[2][2]
	diag2_sum = grid_data[0][2] + grid_data[1][1] + grid_data[2][0]
	if diag1_sum == 3 or diag2_sum == 3:
		return 1  # Player 1 wins
	elif diag1_sum == -3 or diag2_sum == -3:
		return -1  # Player 2 wins

	return 0  # No winner yet

func _on_game_over_menu_restart_game():
	new_game()

func _on_go_to_menu_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")
