extends VBoxContainer

@onready var _running_count_label: Label = %RunningCountValue
@onready var _true_count_label: Label = %TrueCountValue
@onready var _bankroll_label: Label = %BankrollValue
@onready var _recommended_bet_label: Label = %RecommendedBetValue
@onready var _shoe_progress_label: Label = %ShoeProgressValue

var _stats := {
	"runningCount": 0,
	"trueCount": 0,
	"bankroll": 1000,
	"recommendedBet": 0,
	"shoeProgress": "0%",
}


func update_stats(next_stats: Dictionary) -> void:
	for key in _stats.keys():
		if next_stats.has(key):
			_stats[key] = next_stats[key]
	_refresh_labels()


func _ready() -> void:
	_refresh_labels()


func _refresh_labels() -> void:
	_running_count_label.text = str(_stats["runningCount"])
	_true_count_label.text = str(_stats["trueCount"])
	_bankroll_label.text = "$%s" % str(_stats["bankroll"])
	_recommended_bet_label.text = "$%s" % str(_stats["recommendedBet"])
	_shoe_progress_label.text = str(_stats["shoeProgress"])
