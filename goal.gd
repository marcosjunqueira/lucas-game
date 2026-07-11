extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		# Goal scored! Deactivate further detections
		set_deferred("monitoring", false)
		
		# Check name to determine which side scored
		if name.to_lower().contains("left"):
			Global.game_over.emit("Dinosaur")
		else:
			Global.game_over.emit("CR7")
