@icon("res://components/collisions/2D/hitbox.svg")
class_name Hitbox2D extends Area2D


func _init() -> void:
	collision_mask = 0
	collision_layer = 64 ## Hitboxes layer
	monitoring = false
	monitorable = true


func enable():
	set_deferred("monitorable", true)
	

func disable():
	set_deferred("monitorable", false)
