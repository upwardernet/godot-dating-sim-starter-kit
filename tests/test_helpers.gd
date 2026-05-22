# Test assertion helpers and result tracking

var _passed: int = 0
var _failed: int = 0
var _results: Array = []

func assert_eq(actual, expected, description: String = "") -> void:
	if actual == expected:
		_passed += 1
		_results.append("PASS: %s" % description)
	else:
		_failed += 1
		_results.append("FAIL: %s — expected [%s], got [%s]" % [description, expected, actual])

func assert_ne(actual, expected, description: String = "") -> void:
	if actual != expected:
		_passed += 1
		_results.append("PASS: %s" % description)
	else:
		_failed += 1
		_results.append("FAIL: %s — expected not [%s], got [%s]" % [description, expected, actual])

func assert_true(condition: bool, description: String = "") -> void:
	if condition:
		_passed += 1
		_results.append("PASS: %s" % description)
	else:
		_failed += 1
		_results.append("FAIL: %s — expected true" % description)

func assert_false(condition: bool, description: String = "") -> void:
	if not condition:
		_passed += 1
		_results.append("PASS: %s" % description)
	else:
		_failed += 1
		_results.append("FAIL: %s — expected false" % description)

func assert_not_empty(value, description: String = "") -> void:
	if value == null:
		_failed += 1
		_results.append("FAIL: %s — expected non-empty, got null" % description)
	elif value is String and value == "":
		_failed += 1
		_results.append("FAIL: %s — expected non-empty string" % description)
	elif value is Array and value.is_empty():
		_failed += 1
		_results.append("FAIL: %s — expected non-empty array" % description)
	elif value is Dictionary and value.is_empty():
		_failed += 1
		_results.append("FAIL: %s — expected non-empty dict" % description)
	else:
		_passed += 1
		_results.append("PASS: %s" % description)

func assert_contains(collection, item, description: String = "") -> void:
	if collection.has(item):
		_passed += 1
		_results.append("PASS: %s" % description)
	else:
		_failed += 1
		_results.append("FAIL: %s — collection does not contain [%s]" % [description, item])

func print_summary() -> void:
	print("\n========== TEST RESULTS ==========")
	for r in _results:
		print(r)
	print("================================")
	print("Total: %d | Passed: %d | Failed: %d" % [_passed + _failed, _passed, _failed])
	print("================================\n")

func all_passed() -> bool:
	return _failed == 0

func reset() -> void:
	_passed = 0
	_failed = 0
	_results = []
