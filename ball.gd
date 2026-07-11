extends RigidBody2D

var initial_position := Vector2.ZERO

func _ready() -> void:
	initial_position = global_position

func _physics_process(_delta: float) -> void:
	# If the ball falls below the viewport (e.g. y > 750), respawn it
	if global_position.y > 750:
		respawn()

func respawn() -> void:
	# Reset physics state cleanly using deferred operations
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	# Find player and spawn slightly above them, or fall back to initial position
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		global_position = player.global_position + Vector2(0, -100)
	else:
		global_position = initial_position
