extends CharacterBody2D

const SPEED = 280.0
const JUMP_VELOCITY = -450.0
const PUSH_FORCE = 50.0
const KICK_FORCE_X = 350.0
const KICK_FORCE_Y = -250.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: Sprite2D = $Sprite2D
@onready var kick_area: Area2D = $KickArea

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump (W, Up Arrow, or gamepad button)
	var wants_jump = Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W)
	if wants_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Horizontal Movement (A/D, Left/Right Arrows, or Gamepad)
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
		# Flip the kick area direction
		kick_area.scale.x = -1.0 if direction < 0 else 1.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 8 * delta)

	move_and_slide()

	# Contact Pushing (dribbling the ball by running into it)
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D and collider.is_in_group("ball"):
			var force_dir = (collider.global_position - global_position).normalized()
			# Apply impulse to the ball
			collider.apply_central_impulse(force_dir * PUSH_FORCE)

	# Active Kicking (Spacebar, Enter, or Click)
	var wants_kick = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if wants_kick:
		kick_ball()

func kick_ball() -> void:
	var overlapping = kick_area.get_overlapping_bodies()
	for body in overlapping:
		if body is RigidBody2D and body.is_in_group("ball"):
			# Kick direction matches the facing direction of CR7
			var kick_dir = -1.0 if sprite.flip_h else 1.0
			var impulse = Vector2(kick_dir * KICK_FORCE_X, KICK_FORCE_Y)
			body.apply_central_impulse(impulse)
			# Add a temporary visual velocity flash (optional, feels good!)
			body.linear_velocity += impulse * 0.2
