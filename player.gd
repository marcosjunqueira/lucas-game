extends CharacterBody2D

const SPEED = 280.0
const JUMP_VELOCITY = -450.0
const PUSH_FORCE = 50.0
const KICK_FORCE_X = 350.0
const KICK_FORCE_Y = -250.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var initial_position := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var kick_area: Area2D = $KickArea

func _ready() -> void:
	initial_position = global_position

func _physics_process(delta: float) -> void:
	# Respawn if player falls into a pit
	if global_position.y > 750:
		respawn()

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
	# Prevent spamming spins while already spinning
	if sprite.rotation != 0.0:
		return
		
	var ball: RigidBody2D = null
	var overlapping = kick_area.get_overlapping_bodies()
	for body in overlapping:
		if body is RigidBody2D and body.is_in_group("ball"):
			ball = body
			break

	var kick_dir = -1.0 if sprite.flip_h else 1.0
	
	# Play bicycle kick backflip animation (spin backwards)
	# Facing right (flip_h=false) -> spin counter-clockwise (-360)
	# Facing left (flip_h=true) -> spin clockwise (360)
	var spin_dir = 360.0 if sprite.flip_h else -360.0
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", spin_dir, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.0)

	if ball:
		# 1. Pop the ball straight up and slightly back
		ball.linear_velocity = Vector2(kick_dir * 40.0, -380.0)
		
		# 2. Player leaps up towards the ball
		velocity.y = JUMP_VELOCITY * 1.15
		
		# 3. Wait a short moment (0.18s) for player to reach upside-down stance in the air
		await get_tree().create_timer(0.18).timeout
		
		# 4. Final kick: launch the ball high over the opponent into the net
		if is_instance_valid(ball):
			ball.linear_velocity = Vector2(kick_dir * 580.0, -380.0)



func respawn() -> void:
	global_position = initial_position
	velocity = Vector2.ZERO

