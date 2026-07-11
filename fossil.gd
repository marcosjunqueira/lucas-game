extends Area2D

func _ready() -> void:
	Global.total_fossils_in_level += 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("ball"):
		Global.fossils_collected += 1
		SoundManager.play("fossil")
		# Disable monitoring immediately to avoid double collisions
		set_deferred("monitoring", false)
		
		# Create a juice pickup effect (fade and shrink)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(queue_free)
