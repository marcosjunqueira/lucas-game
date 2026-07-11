extends Node

signal score_changed(new_score: int)
signal goals_changed(player_goals: int, opponent_goals: int)
signal goal_scored(scorer: String)
signal match_ended(winner: String, p_score: int, o_score: int)

var fossils_collected := 0:
	set(val):
		fossils_collected = val
		score_changed.emit(fossils_collected)

var total_fossils_in_level := 0

var player_goals := 0
var opponent_goals := 0

func reset_game() -> void:
	fossils_collected = 0
	player_goals = 0
	opponent_goals = 0

func record_goal(scorer: String) -> void:
	if scorer == "CR7":
		player_goals += 1
	else:
		opponent_goals += 1
	goals_changed.emit(player_goals, opponent_goals)
	goal_scored.emit(scorer)
