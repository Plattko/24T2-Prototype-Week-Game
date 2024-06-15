class_name CrouchPlayerState

extends PlayerState

const WALK_SPEED = 5.0
const CROUCH_ANIM_SPEED : float = 7.0

var is_crouch_released : bool = false

func enter(previous_state, msg : Dictionary = {}) -> void:
	print("Entered Crouch player state.")
	# Play the crouch animation
	if previous_state.name != "SlidePlayerState":
		player.animation_player.play("Crouch", -1, CROUCH_ANIM_SPEED)
	else:
		player.animation_player.current_animation = "Crouch"
		player.animation_player.seek(1.0, true)

func exit():
	is_crouch_released = false

func physics_update(delta) -> void:
	# Handle movement
	player.velocity.x = input.get_direction().x * WALK_SPEED
	player.velocity.z = input.get_direction().z * WALK_SPEED
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		player.stand_up("CrouchPlayerState", CROUCH_ANIM_SPEED, true)
		transition.emit("AirPlayerState")
	# Transition to Air state with jump
	elif input.is_jump_just_pressed() and player.crouch_shape_cast.is_colliding() == false:
		player.stand_up("CrouchPlayerState", CROUCH_ANIM_SPEED, true)
		transition.emit("AirPlayerState", {"do_jump" = true})
	# Handle releasing crouch
	elif input.is_crouch_just_released():
		uncrouch()
	elif !input.is_crouch_pressed() and !is_crouch_released:
		uncrouch()

func uncrouch() -> void:
	# If there is nothing blocking the player from standing up, play the uncrouch animation
	if player.crouch_shape_cast.is_colliding() == false:
		player.animation_player.play("Crouch", -1, -CROUCH_ANIM_SPEED, true)
		
		# Wait for uncrouch animation to end
		if player.animation_player.is_playing():
			await player.animation_player.animation_finished
		
		# Transition to Idle state
		if !input.get_direction():
			transition.emit("IdlePlayerState")
			# Transition to Walk state
		elif input.get_direction() and !input.is_sprint_pressed():
			transition.emit("WalkPlayerState")
		# Transition to Sprint state
		elif input.get_direction() and input.is_sprint_pressed():
			transition.emit("SprintPlayerState")
	
	# If there is something blocking the way, try to uncrouch again in 0.1 seconds
	elif player.crouch_shape_cast.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch()
