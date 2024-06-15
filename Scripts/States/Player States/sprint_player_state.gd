class_name SprintPlayerState

extends PlayerState

const SPRINT_SPEED = 8.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Sprint player state.")

func physics_update(delta : float):
	# Handle movement
	player.velocity.x = input.get_direction().x * SPRINT_SPEED
	player.velocity.z = input.get_direction().z * SPRINT_SPEED
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Air state with jump
	elif input.is_jump_just_pressed() and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
	# Transition to Idle state
	elif !input.get_direction():
		transition.emit("IdlePlayerState")
	# Transition to Walk state
	elif input.is_sprint_just_released():
		transition.emit("WalkPlayerState")
	# Handle crouch
	if input.is_crouch_pressed():
		# Transition to Slide state
		if input.is_move_forwards_pressed() and player.velocity.length() > 6.0:
			transition.emit("SlidePlayerState")
		# Transition to Crouch state
		else:
			transition.emit("CrouchPlayerState")
