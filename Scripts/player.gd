class_name Player

extends CharacterBody3D

@export var head : Node3D
@export var camera : Camera3D
@export var animation_player : AnimationPlayer
@export var crouch_shape_cast : ShapeCast3D

var direction
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 8.0

# Camera movement variables
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3

var player_rotation : Vector3
var camera_rotation : Vector3

const MIN_CAMERA_TILT := deg_to_rad(-90)
const MAX_CAMERA_TILT := deg_to_rad(90)

const SENSITIVITY = 0.25

# Head bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

var can_head_bob : bool = true

# FOV variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set global reference to camera in the Global script
	Global.camera = camera

func _input(event):
	# Handle quit
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_input = -event.relative.x * SENSITIVITY
		tilt_input = -event.relative.y * SENSITIVITY

func _process(delta):
	# Handle camera movement
	update_camera(delta)

func _physics_process(delta):
	
	## Handle jump
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Head bob
	if can_head_bob:
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = head_bob(t_bob)
	
	# FOV
	var velocity_clamped = clamp (velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Debug
	Global.debug.add_debug_property("Move Speed", snappedf(velocity.length(), 0.01), 2)

func update_camera(delta):
	mouse_rotation.y += rotation_input * delta
	mouse_rotation.x += tilt_input * delta
	mouse_rotation.x = clamp(mouse_rotation.x, MIN_CAMERA_TILT, MAX_CAMERA_TILT)
	
	player_rotation = Vector3(0.0, mouse_rotation.y, 0.0)
	camera_rotation = Vector3(mouse_rotation.x, 0.0, 0.0)
	
	global_transform.basis = Basis.from_euler(player_rotation)
	head.transform.basis = Basis.from_euler(camera_rotation)
	head.rotation.z = 0.0
	
	rotation_input = 0.0
	tilt_input = 0.0

func head_bob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# State machine functions
func update_gravity(delta) -> void:
	velocity.y -= gravity * delta

func stand_up(current_state, anim_speed : float, is_repeating_check : bool):
	# If there is nothing blocking the player from standing up, play the respective animation
	if crouch_shape_cast.is_colliding() == false:
		# Check if it is the crouch or slide animation
		if current_state == "CrouchPlayerState":
			animation_player.play("Crouch", -1, -anim_speed, true)
		elif current_state == "SlidePlayerState":
			animation_player.play("Slide", -1, -anim_speed, true)
		
		if animation_player.is_playing():
			await animation_player.animation_finished
	# If there is something blocking the way, try to uncrouch again in 0.1 seconds
	elif crouch_shape_cast.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		stand_up(current_state, anim_speed, true)
