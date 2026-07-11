extends Node2D

@onready var fossil_label: Label = $HUD/MarginContainer/VBoxContainer/FossilLabel
@onready var scoreboard_label: Label = $HUD/ScoreboardContainer/PanelContainer/MarginContainer/HBoxContainer/ScoreboardLabel
@onready var timer_label: Label = $HUD/ScoreboardContainer/PanelContainer/MarginContainer/HBoxContainer/TimerLabel
@onready var win_overlay: CenterContainer = $HUD/WinOverlay
@onready var win_label: Label = $HUD/WinOverlay/PanelContainer/MarginContainer/VBoxContainer/WinLabel
@onready var restart_button: Button = $HUD/WinOverlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var trex: Sprite2D = $TrexBackground

# Temporary banner shown when a goal is scored
@onready var goal_banner: CenterContainer = $HUD/GoalBanner
@onready var goal_banner_label: Label = $HUD/GoalBanner/PanelContainer/MarginContainer/GoalBannerLabel

var match_time := 90.0
var is_match_running := true
var is_in_round_reset := false

var player_start_pos := Vector2(300, 544)
var opponent_start_pos := Vector2(850, 544)
var ball_start_pos := Vector2(576, 500)

func _ready() -> void:
	Global.reset_game()
	Global.total_fossils_in_level = 0
	
	# Connect signals
	Global.score_changed.connect(_on_score_changed)
	Global.goals_changed.connect(_on_goals_changed)
	Global.goal_scored.connect(_on_goal_scored)
	Global.match_ended.connect(_on_match_ended)
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Initial states
	win_overlay.visible = false
	goal_banner.visible = false
	trex.scale = Vector2.ZERO
	trex.modulate.a = 0.0
	
	await get_tree().process_frame
	_update_fossil_ui()
	_update_scoreboard_ui()
	_update_timer_ui()

func _process(delta: float) -> void:
	if is_match_running and not is_in_round_reset:
		match_time -= delta
		if match_time <= 0:
			match_time = 0.0
			is_match_running = false
			var winner = "Draw"
			if Global.player_goals > Global.opponent_goals:
				winner = "CR7"
			elif Global.opponent_goals > Global.player_goals:
				winner = "Dino"
			Global.match_ended.emit(winner, Global.player_goals, Global.opponent_goals)
		
		_update_timer_ui()

func _on_score_changed(_new_score: int) -> void:
	_update_fossil_ui()

func _on_goals_changed(_p_goals: int, _o_goals: int) -> void:
	_update_scoreboard_ui()

func _update_fossil_ui() -> void:
	fossil_label.text = "Fossils: %d / %d" % [Global.fossils_collected, Global.total_fossils_in_level]

func _update_scoreboard_ui() -> void:
	scoreboard_label.text = "CR7 [ %d - %d ] DINO" % [Global.player_goals, Global.opponent_goals]

func _update_timer_ui() -> void:
	var minutes := int(match_time) / 60
	var seconds := int(match_time) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _on_goal_scored(scorer: String) -> void:
	is_in_round_reset = true
	SoundManager.play("whistle")
	
	# Freeze the ball physics using deferred properties to avoid physics server errors
	$Ball.set_deferred("freeze", true)
	$Ball.set_deferred("linear_velocity", Vector2.ZERO)
	$Ball.set_deferred("angular_velocity", 0.0)
	$Ball.set_deferred("global_position", ball_start_pos)
	
	# Freeze player and opponent
	$Player.process_mode = Node.PROCESS_MODE_DISABLED
	if has_node("Opponent"):
		$Opponent.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Determine kickoff possession: ball goes to the side that conceded the goal
	# CR7 scored -> Dino conceded -> Dino gets kickoff (spawn ball at x = 750)
	# Dino scored -> CR7 conceded -> CR7 gets kickoff (spawn ball at x = 400)
	var next_kickoff_pos = Vector2(400, 500) if scorer != "CR7" else Vector2(752, 500)
	
	# Show goal banner
	goal_banner.visible = true
	if scorer == "CR7":
		goal_banner_label.text = "GOOOL DO CR7!!!\nSIUUUUUUU!"
		# Delay SIUUU slightly to align with T-Rex jumping up
		get_tree().create_timer(0.15).timeout.connect(func(): SoundManager.play("siuuu"))
		
		# Animate T-Rex
		trex.global_position = Vector2(576, 324)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(trex, "scale", Vector2(2.5, 2.5), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(trex, "modulate:a", 1.0, 0.3)
		
		var jump_tween = create_tween()
		jump_tween.tween_property(trex, "global_position:y", 224.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		jump_tween.tween_property(trex, "global_position:y", 324.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		jump_tween.parallel().tween_property(trex, "rotation_degrees", 15.0, 0.25)
		jump_tween.tween_property(trex, "rotation_degrees", 0.0, 0.2)
	else:
		goal_banner_label.text = "GOL DO DINO!"
		
	# Wait 2.5 seconds
	await get_tree().create_timer(2.5).timeout
	
	# Hide T-Rex
	var hide_tween = create_tween().set_parallel(true)
	hide_tween.tween_property(trex, "scale", Vector2.ZERO, 0.3)
	hide_tween.tween_property(trex, "modulate:a", 0.0, 0.3)
	
	goal_banner.visible = false
	
	# Reset player and opponent positions
	$Player.global_position = player_start_pos
	$Player.velocity = Vector2.ZERO
	if has_node("Opponent"):
		$Opponent.global_position = opponent_start_pos
		$Opponent.velocity = Vector2.ZERO
	
	# Place the ball at the calculated kickoff position and unfreeze it
	$Ball.global_position = next_kickoff_pos
	$Ball.linear_velocity = Vector2.ZERO
	$Ball.angular_velocity = 0.0
	$Ball.freeze = false
	
	# Unfreeze characters
	$Player.process_mode = Node.PROCESS_MODE_INHERIT
	if has_node("Opponent"):
		$Opponent.process_mode = Node.PROCESS_MODE_INHERIT
		
	# Reset goal triggers monitoring
	$GoalLeft.monitoring = true
	$GoalRight.monitoring = true
	
	is_in_round_reset = false

func _on_match_ended(winner: String, p_score: int, o_score: int) -> void:
	win_overlay.visible = true
	
	# Play triple whistle for full time (short, short, long)
	SoundManager.play("whistle")
	get_tree().create_timer(0.2).timeout.connect(func(): SoundManager.play("whistle"))
	get_tree().create_timer(0.45).timeout.connect(func(): SoundManager.play("whistle"))
	
	# Freeze all
	$Player.process_mode = Node.PROCESS_MODE_DISABLED
	$Ball.process_mode = Node.PROCESS_MODE_DISABLED
	if has_node("Opponent"):
		$Opponent.process_mode = Node.PROCESS_MODE_DISABLED
		
	if winner == "CR7":
		win_label.text = "FIM DE JOGO!\nCR7 VENCEU!\n\nPlacar: CR7 %d x %d DINO\n\nFósseis coletados: %d / %d" % [p_score, o_score, Global.fossils_collected, Global.total_fossils_in_level]
	elif winner == "Dino":
		win_label.text = "FIM DE JOGO!\nDINO VENCEU!\n\nPlacar: CR7 %d x %d DINO\n\nFósseis coletados: %d / %d" % [p_score, o_score, Global.fossils_collected, Global.total_fossils_in_level]
	else:
		win_label.text = "FIM DE JOGO!\nEMPATE!\n\nPlacar: CR7 %d x %d DINO\n\nFósseis coletados: %d / %d" % [p_score, o_score, Global.fossils_collected, Global.total_fossils_in_level]

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
