@icon("res://components/interaction/throwable/throwable_3d.svg")
class_name Throwable3D extends RigidBody3D

signal focused
signal unfocused
signal pulled
signal throwed
signal dropped

@export var title := "Throwable"
@export var description := "Can be throwed"
@export var grab_mode := GRAB_MODE.DYNAMIC
@export_range(0, 255, 1) var transparency_on_pull := 255
@export var focus_pointer: Texture2D = FOCUSED_THROWABLE_POINTER
@export var locked_pointer: Texture2D = LOCKED_THROWABLE_POINTER

const LOCKED_THROWABLE_POINTER = preload("res://assets/ui/crosshair/crosshair005.png")
const FOCUSED_THROWABLE_POINTER = preload("res://assets/ui/crosshair/crosshair008.png")

enum GRAB_MODE {
	DYNAMIC,
	FREEZE
}

enum STATE {
	NEUTRAL,
	PULL,
	THROW
}

var original_parent: Node
var original_collision_layer := 16 ## Throwable layer
var original_collision_mask := 1 | 2 | 4 | 16 | 128 ## Interact with world, player, enemies, other throwables and shards
var current_linear_velocity := Vector3.ZERO

var original_transparency := 255
var grabber: Node3D
var current_state := STATE.NEUTRAL
var active_material: StandardMaterial3D
var locked := false


func _ready():
	original_parent = get_parent()
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	
	var mesh = NodeWizard.first_node_of_class(self, MeshInstance3D.new())
	
	if mesh:
		active_material = mesh.get_active_material(0)
		if active_material:
			original_transparency = active_material.albedo_color.a8;
	
	
func _integrate_forces(state):
	if state_is_pull():
		state.linear_velocity = current_linear_velocity
	
	if state_is_throw() and state.linear_velocity.is_zero_approx():
		current_state = STATE.NEUTRAL
	
		
func update_linear_velocity(_linear_velocity: Vector3):
	current_linear_velocity = _linear_velocity
	

func pull(_grabber: Node3D):
	if _grabber == grabber:
		return
		
	grabber = _grabber
	collision_layer = 0
	
	if grab_mode_is_freeze():
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true
	
	reparent(grabber)
	apply_transparency()
	
	current_state = STATE.PULL
	
	pulled.emit()
		

func throw(impulse: Vector3):
	if grab_mode_is_freeze():
		freeze = false
		
	collision_layer = original_collision_layer
	reparent(original_parent)
	apply_impulse(impulse)
	
	grabber = null
	current_state = STATE.THROW
	recover_transparency()
	
	throwed.emit()
	
	
func drop():
	if grab_mode_is_freeze():
		freeze = false
		
	collision_layer = original_collision_layer
	reparent(original_parent)
	
	linear_velocity = Vector3.ZERO
	apply_impulse(Vector3.ZERO)
	
	grabber = null
	current_state = STATE.NEUTRAL
	recover_transparency()
	
	dropped.emit()
	

func apply_transparency():
	if transparency_on_pull == 255:
		return
	
	if active_material:
		active_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		active_material.albedo_color.a8 = transparency_on_pull


func recover_transparency():
	if transparency_on_pull == 255:
		return
	
	if active_material:
		active_material.albedo_color.a8  = original_transparency


func lock():
	locked = true
	

func unlock():
	locked = false


func grab_mode_is_dynamic() -> bool:
	return grab_mode == GRAB_MODE.DYNAMIC
	

func grab_mode_is_freeze() -> bool:
	return grab_mode == GRAB_MODE.FREEZE


func state_is_throw() -> bool:
	return current_state == STATE.THROW


func state_is_neutral() -> bool:
	return current_state == STATE.NEUTRAL


func state_is_pull() -> bool:
	return current_state == STATE.PULL




 #1. Force vs.Impulse:
#
#Force: Represents a continuous application of force over time (measured in newtons). When applied to a rigid body, it produces acceleration in the direction of the force.
#Impulse: Represents a sudden change in momentum delivered instantly(measured in newton-seconds). Applying an impulse directly changes the linear or angular velocity of the rigid body based on the impulse magnitude and direction.
#
#2. Application Point:
#
#Central vs.Non-Central:
#Central: Applied at the center of mass of the rigid body. This results in pure translation (linear movement) without rotation.
#Non-Central: Applied at a specific point relative to the body's center of mass. This can produce both translation and rotation (torque) depending on the force/impulse direction and its distance from the center of mass. 
#
#Continuous vs. Instantaneous: Use force methods (apply_force or apply_central_force) for situations where you want to continuously influence the body's movement over time. Use impulse methods (apply_impulse or apply_central_impulse) when you want to cause an immediate change in velocity without applying a prolonged force.
#Central vs. Non-Central: Use central methods (apply_central_force or apply_central_impulse) if you only want to translate the body without introducing rotation. Use non-central methods (apply_force or apply_impulse) if you want to introduce both translation and rotation based on the application point relative to the center of mass.
#Torque: Use apply_torque when you want to directly rotate the body around a specific axis without applying a force.
