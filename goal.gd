extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		# Soccer goal scored!
		set_deferred("monitoring", false)
		
		# Emit the global game won signal
		Global.game_won.emit()
