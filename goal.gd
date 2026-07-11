extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		# Prevent multiple triggers in same frame
		set_deferred("monitoring", false)
		
		if name.to_lower().contains("left"):
			Global.record_goal("Dinosaur")
		else:
			Global.record_goal("CR7")
