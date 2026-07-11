extends Node

signal score_changed(new_score: int)
signal game_won

var fossils_collected := 0:
	set(val):
		fossils_collected = val
		score_changed.emit(fossils_collected)

var total_fossils_in_level := 0

func reset_game() -> void:
	fossils_collected = 0
