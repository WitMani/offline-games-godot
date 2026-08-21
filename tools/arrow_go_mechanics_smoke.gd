extends SceneTree

const SOLUTION: Array[String] = ["b", "a", "d", "c", "k", "g", "f", "l", "i", "e", "j", "h"]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._arrow_go_clear_recovery()
	game._open_game("arrow_go")
	game._reset_current()
	_expect(game.state.get("legal_ids", []) == ["b", "d", "k"], "entry_legal")
	var before := _authority()
	game._arrow_go_attempt("a", "mechanics_smoke")
	_expect(_authority() == before, "blocked_atomic")
	game._arrow_go_attempt("b", "mechanics_smoke")
	_expect(game.state.get("removed_ids", []) == ["b"], "legal_remove")
	_expect("a" in game.state.get("legal_ids", []), "order_unlock")
	game._reset_current()
	for arrow_id in SOLUTION:
		_expect(arrow_id in game.state.get("legal_ids", []), "solution_legal_%s" % arrow_id)
		game._arrow_go_attempt(arrow_id, "mechanics_smoke")
	_expect(str(game.state.get("status", "")) == "won", "win")
	_expect(int(game.state.get("remaining", -1)) == 0 and int(game.state.get("moves", 0)) == 12, "win_counts")
	before = _authority()
	game._arrow_go_attempt("a", "mechanics_smoke")
	_expect(_authority() == before, "terminal_freeze")
	game._reset_current()
	_expect(int(game.state.get("remaining", 0)) == 12 and str(game.state.get("status", "")) == "playing", "restart")
	game._arrow_go_clear_recovery()
	print("ARROW_GO_MECHANICS_SMOKE=%d" % assertions)
	print("ARROW_GO_MECHANICS_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _authority() -> Dictionary:
	return {
		"removed_ids":game.state.get("removed_ids", []).duplicate(),
		"remaining":int(game.state.get("remaining", -1)),
		"moves":int(game.state.get("moves", -1)),
		"score":int(game.state.get("score", -1)),
		"status":str(game.state.get("status", "")),
	}
