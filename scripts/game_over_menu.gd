extends CanvasLayer

signal restart_game

func _on_restart_button_pressed():
	restart_game.emit()
