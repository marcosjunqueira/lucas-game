extends CharacterBody2D

const SPEED = 160.0
const DETECT_RADIUS = 350.0
const PUSH_FORCE = 70.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var patrol_left := 1400.0
var patrol_right := 1780.0
var patrol_dir := -1

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Find the ball in the level
	var balls = get_tree().get_nodes_in_group("ball")
	var ball = null
	if balls.size() > 0:
		ball = balls[0]
	
	var target_vel_x = 0.0
	
	# AI behavior: Chase the ball if it is close, otherwise patrol
	if ball and global_position.distance_to(ball.global_position) < DETECT_RADIUS:
		var dir_to_ball = (ball.global_position - global_position).normalized()
		# Chase the ball horizontally
		target_vel_x = dir_to_ball.x * SPEED
		# Face the ball
		sprite.flip_h = (dir_to_ball.x < 0)
	else:
		# Patrol between left and right boundary points near the goal
		if global_position.x < patrol_left:
			patrol_dir = 1
		elif global_position.x > patrol_right:
			patrol_dir = -1
		target_vel_x = patrol_dir * (SPEED * 0.7)
		sprite.flip_h = (patrol_dir < 0)

	velocity.x = move_toward(velocity.x, target_vel_x, SPEED * 6 * delta)
	move_and_slide()

	# Apply push back force to the ball on contact to defend the goal
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D and collider.is_in_group("ball"):
			# Push the ball specifically to the left (away from the goal)
			var force_dir = Vector2(-1.0, -0.4).normalized()
			collider.apply_central_impulse(force_dir * PUSH_FORCE)
