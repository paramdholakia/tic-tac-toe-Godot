extends Control

func _on_pvp_pressed():
	get_tree().change_scene_to_file("res://scenes/PVP.tscn")

func _on_pvc_pressed():
	get_tree().change_scene_to_file("res://scenes/PVC.tscn")


func _on_pvai_pressed():
	pass # Replace with function body.

func _on_options_pressed():
	pass # Replace with function body.

func _on_exit_pressed():
	get_tree().quit()
