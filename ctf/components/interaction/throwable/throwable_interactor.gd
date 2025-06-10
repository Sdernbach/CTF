class_name ThrowableInteractor extends RayCast3D


var current_throwable: Throwable3D
var focused := false


func _enter_tree():
	collide_with_bodies = true
	collide_with_areas = false
	collision_mask = 16 ## Throwables layer


func _physics_process(_delta):
	var detected_throwable: Throwable3D = get_collider() as Throwable3D if is_colliding() else null
	
	if detected_throwable:
		if current_throwable != detected_throwable and !focused:
			focus(detected_throwable)
	else:
		if focused and current_throwable:
			unfocus(current_throwable)



func focus(throwable: Throwable3D):
	current_throwable = throwable
	
	if !focused and throwable.has_signal("focused"):
		throwable.focused.emit(self)
		GlobalEventBus.throwable_focused.emit(current_throwable)
		
	focused = true
	
	
func unfocus(throwable: Throwable3D = current_throwable):
	if focused and throwable.has_signal("unfocused"):
		throwable.unfocused.emit(self)
		GlobalEventBus.throwable_unfocused.emit(current_throwable)
		
	current_throwable = null
	focused = false

