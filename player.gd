extends CharacterBody2D

# Movement speed in pixels per second
const SPEED = 400.0
# Friction coefficient to slow down the player when no input is provided
const FRICTION = 15.0

func _physics_process(delta: float) -> void:
	# Get the input direction using WASD, Arrow keys, or controller D-pad/Joystick
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		# Accelerate towards the input direction
		velocity = direction * SPEED
	else:
		# Smoothly decelerate to a stop
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * FRICTION * delta)

	# Move the character handling collision physics
	move_and_slide()
