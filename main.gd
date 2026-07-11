extends Node2D

@onready var fossil_label: Label = $HUD/MarginContainer/VBoxContainer/FossilLabel
@onready var win_overlay: CenterContainer = $HUD/WinOverlay
@onready var win_label: Label = $HUD/WinOverlay/PanelContainer/MarginContainer/VBoxContainer/WinLabel
@onready var restart_button: Button = $HUD/WinOverlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var trex: Sprite2D = $TrexBackground

func _ready() -> void:
	# Reset global values
	Global.reset_game()
	Global.total_fossils_in_level = 0
	
	# Connect signals
	Global.score_changed.connect(_on_score_changed)
	Global.game_won.connect(_on_game_won)
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Initialize visual states
	win_overlay.visible = false
	trex.scale = Vector2.ZERO
	trex.modulate.a = 0.0
	
	# Wait a frame for the fossils to register their counts
	await get_tree().process_frame
	_update_fossil_ui()

func _on_score_changed(_new_score: int) -> void:
	_update_fossil_ui()

func _update_fossil_ui() -> void:
	fossil_label.text = "Fossils: %d / %d" % [Global.fossils_collected, Global.total_fossils_in_level]

func _on_game_won() -> void:
	win_overlay.visible = true
	win_label.text = "GOOOOL!!!\nSIUUUUUUU!\n\nYou collected %d of %d fossils!" % [Global.fossils_collected, Global.total_fossils_in_level]
	
	# Trigger the T-Rex Siuuu animation!
	# Scale up from zero with a bouncy transition and fade in
	var tween = create_tween().set_parallel(true)
	trex.global_position = Vector2(576, 450)
	tween.tween_property(trex, "scale", Vector2(2.5, 2.5), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(trex, "modulate:a", 1.0, 0.4)
	
	# Chain a secondary bounce and tilt jump celebration
	var jump_tween = create_tween()
	jump_tween.tween_property(trex, "global_position:y", 350.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(trex, "global_position:y", 450.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	jump_tween.parallel().tween_property(trex, "rotation_degrees", 15.0, 0.3)
	jump_tween.tween_property(trex, "rotation_degrees", 0.0, 0.2)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
