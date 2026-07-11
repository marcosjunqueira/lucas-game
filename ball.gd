extends RigidBody2D

var initial_position := Vector2(576, 300)

func _ready() -> void:
	initial_position = global_position

func _physics_process(_delta: float) -> void:
	# If the ball falls below the viewport (e.g. y > 650), respawn it
	if global_position.y > 650:
		respawn()

func respawn() -> void:
	# Reset physics state cleanly
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	# Spawn at center of the field
	global_position = Vector2(576, 300)
