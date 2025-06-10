extends Node

### PLAYER ###
signal lock_player
signal unlock_player


### CAMERA ###
signal transition_camera_2d_requested(from: Camera2D, to: Camera2D, duration: float)
signal transition_camera_3d_requested(from: Camera3D, to: Camera3D, duration: float)


### INTERACTIONS ###
signal interacted(interactor)
signal canceled_interaction(interactor)
signal focused(interactor)
signal unfocused(interactor)

signal throwable_focused(throwable: Throwable3D)
signal throwable_unfocused(throwable: Throwable3D)


### INPUT ###
signal controller_connected(device: int, controller_name: String)
signal controller_disconnected(device: int, controller_name: String)
