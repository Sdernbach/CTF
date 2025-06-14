@icon("res://components/interaction/lights/switchable_lights.svg")
class_name SwitchableLight3D extends Node3D

signal turned_on
signal turned_off

## The individual light this node will affect
@export var target_light: Light3D
## The interactable that listen when entities in the world interact with this node
@export var interactable: Interactable3D
## The group name of the lights that will be affected by this switchable
@export var lights_group := ""
## Activate temporary mode to keep on the lights for a limited amount of time
@export var temporary_mode := false
## The time lights are on when temporary mode is active
@export var time_lights_are_on := 10.0
## Allow turn off the lights even when the temporary timer is on to force lights off
@export var allow_turn_off_on_timer_started := false
## The state that displays wether the lights are on or not
@export var lights_on := false:
	set(value):
		if value != lights_on:
			if value:
				turned_on.emit()
			else:
				turned_off.emit()
		
		lights_on = value

## Use a custom light energy instead of the one from the lights linked
@export var use_custom_light_energy := true
## The custom light energy value that will override the lights values when use_custom_light_energy is enabled
@export_range(0, 16, 0.01) var custom_light_energy := 1.0
## A smooth transition between on and off states instead of suddenly change the light energy
@export var smooth_light_state_switch := false
## When this switchable is locked no actions can be done on it
@export var locked := false

var rng = RandomNumberGenerator.new()
var original_light_energies := {}
var temporary_light_timer: Timer


func _ready():
	#assert(interactable is Interactable3D, "SwitchableLight: A interactable 3d must be set")
	
	_create_temporary_light_timer()
	
	if target_light:
		target_light.light_energy = get_original_light_energy(target_light) if lights_on else 0
	
	for light: Light3D in get_lights_on_group():
		light.light_energy = get_original_light_energy(light) if lights_on else 0
		
	#interactable.interacted.connect(on_interacted)
	turned_on.connect(on_turned_on)


func turn_on(smoothly: bool = smooth_light_state_switch):
	if locked:
		return
		
	if target_light:
		if smoothly:
			change_light_energy_smoothly(target_light)
		else:
			target_light.light_energy = get_original_light_energy(target_light)
			
		lights_on = true
		
	if not lights_group.is_empty():
		
		for light: Light3D in get_lights_on_group():
			if smoothly:
				change_light_energy_smoothly(light)
			else:
				light.light_energy = get_original_light_energy(target_light)
				
		lights_on = true
				

func turn_off(smoothly: bool = smooth_light_state_switch, bypass: bool = false):
	if locked:
		return
		
	if temporary_mode and not bypass and not allow_turn_off_on_timer_started and temporary_light_timer.wait_time > 0:
		return


	if target_light:
		if smoothly:
			change_light_energy_smoothly(target_light)
		else:
			target_light.light_energy = 0
	
		lights_on = false
	
	if not lights_group.is_empty():
		
		for light: Light3D in get_lights_on_group():
			if smoothly:
				change_light_energy_smoothly(light)
			else:
				light.light_energy = 0
				
		lights_on = false


func change_light_energy_smoothly(light: Light3D, time: float = 0.45):
	var light_tween: Tween = create_tween()
	light_tween.tween_property(light, "light_energy", get_original_light_energy(light) if lights_on else 0, time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func get_original_light_energy(light: Light3D) -> float:
	return custom_light_energy if use_custom_light_energy else original_light_energies[light.name.to_lower()]


func get_lights_on_group() -> Array[Light3D]:
	var lights: Array[Light3D] = []
	
	for light: Light3D in get_tree().get_nodes_in_group(lights_group).filter(func(node): return node is Light3D):
		original_light_energies[light.name] = light.light_energy
		lights.append(light)
		
	return lights


func blink_effect(turn_off_light_at_the_end: bool = false):
	if target_light:
		blink_animation(target_light, turn_off_light_at_the_end)
		
	if not lights_group.is_empty():
		for light: Light3D in get_lights_on_group():
			blink_animation(light, turn_off_light_at_the_end)	


func blink_animation(light: Light3D, turn_off_light_at_the_end: bool = false):
	var original_energy := light.light_energy
	
	var tween = create_tween()
	tween.set_parallel(true).set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_EXPO)
	tween.chain().tween_property(light, "light_energy", rng.randf_range(0.5, original_energy), 0.5)
	tween.chain().tween_property(light, "light_energy", rng.randf_range(0.5, original_energy), 0.7)
	tween.chain().tween_property(light, "light_energy", rng.randf_range(0.5, original_energy), 1.2)
	tween.chain().tween_property(light, "light_energy", rng.randf_range(0.5, original_energy), 1.5)
	tween.chain().tween_property(light, "light_energy", 0 if turn_off_light_at_the_end else original_energy, 0.4)
	
	lights_on = light.light_energy > 0
		
	
func _create_temporary_light_timer():
	if temporary_light_timer == null:
		temporary_light_timer = Timer.new()
		temporary_light_timer.name = "TemporaryLightTimer"
		temporary_light_timer.wait_time = time_lights_are_on
		temporary_light_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		temporary_light_timer.autostart = false
		temporary_light_timer.one_shot = true
		
		add_child(temporary_light_timer)
		temporary_light_timer.timeout.connect(on_temporary_light_timer_timeout)


func on_temporary_light_timer_timeout():
	turn_off(smooth_light_state_switch, true)


func on_interacted():
	if lights_on:
		turn_off()
	else:
		turn_on()
	
	
func on_turned_on():
	if temporary_mode and is_instance_valid(temporary_light_timer):
		temporary_light_timer.start()
