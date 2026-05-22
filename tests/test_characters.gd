# Unit tests for Characters.gd — portrait/body/background path resolution

var helpers = null

func _init(h) -> void:
	helpers = h

func run_all() -> void:
	test_character_ids()
	test_display_names()
	test_accent_colors()
	test_portrait_paths()
	test_body_paths()
	test_background_paths()
	test_unknown_character_returns_empty()
	test_unknown_expression_returns_empty()
	test_unknown_background_returns_empty()
	test_character_data_completeness()

func test_character_ids() -> void:
	var ids = Characters.get_character_ids()
	helpers.assert_eq(ids.size(), 3, "3 character IDs exist")
	helpers.assert_contains(ids, "elena", "elena in character IDs")
	helpers.assert_contains(ids, "maya", "maya in character IDs")
	helpers.assert_contains(ids, "vanessa", "vanessa in character IDs")

func test_display_names() -> void:
	helpers.assert_eq(Characters.get_display_name("elena"), "Elena", "Elena display name")
	helpers.assert_eq(Characters.get_display_name("maya"), "Maya", "Maya display name")
	helpers.assert_eq(Characters.get_display_name("vanessa"), "Vanessa", "Vanessa display name")
	helpers.assert_eq(Characters.get_display_name("unknown"), "unknown", "Unknown char returns ID")

func test_accent_colors() -> void:
	var elena_color = Characters.get_accent_color("elena")
	helpers.assert_true(is_equal_approx(elena_color.r, 0.8), "Elena accent color R")
	helpers.assert_true(is_equal_approx(elena_color.g, 0.3), "Elena accent color G")
	helpers.assert_true(is_equal_approx(elena_color.b, 0.2), "Elena accent color B")

	var maya_color = Characters.get_accent_color("maya")
	helpers.assert_true(is_equal_approx(maya_color.r, 0.9), "Maya accent color R")
	helpers.assert_true(is_equal_approx(maya_color.g, 0.7), "Maya accent color G")
	helpers.assert_true(is_equal_approx(maya_color.b, 0.2), "Maya accent color B")

	var vanessa_color = Characters.get_accent_color("vanessa")
	helpers.assert_true(is_equal_approx(vanessa_color.r, 0.4), "Vanessa accent color R")
	helpers.assert_true(is_equal_approx(vanessa_color.g, 0.3), "Vanessa accent color G")
	helpers.assert_true(is_equal_approx(vanessa_color.b, 0.8), "Vanessa accent color B")

	helpers.assert_eq(Characters.get_accent_color("unknown"), Color.WHITE, "Unknown char returns white")

func test_portrait_paths() -> void:
	var expressions = ["neutral", "happy", "flirt", "surprised", "annoyed"]
	for char_id in Characters.get_character_ids():
		for expr in expressions:
			var path = Characters.get_portrait(char_id, expr)
			helpers.assert_not_empty(path, "Portrait path for %s/%s" % [char_id, expr])
			helpers.assert_true(path.begins_with("res://"), "Portrait path is res:// for %s/%s" % [char_id, expr])
			helpers.assert_true(path.contains(char_id), "Portrait path contains char_id for %s/%s" % [char_id, expr])
			helpers.assert_true(path.contains(expr), "Portrait path contains expr for %s/%s" % [char_id, expr])

func test_body_paths() -> void:
	for char_id in Characters.get_character_ids():
		var pose1 = Characters.get_body(char_id, "pose1")
		helpers.assert_not_empty(pose1, "Body pose1 path for %s" % char_id)
		helpers.assert_true(pose1.contains("body"), "Body path contains 'body' for %s" % char_id)

		var pose2 = Characters.get_body(char_id, "pose2")
		helpers.assert_not_empty(pose2, "Body pose2 path for %s" % char_id)

func test_background_paths() -> void:
	var bg_ids = Characters.get_background_ids()
	helpers.assert_true(bg_ids.size() >= 3, "At least 3 backgrounds exist")
	helpers.assert_contains(bg_ids, "living_room", "living_room in backgrounds")
	helpers.assert_contains(bg_ids, "bedroom", "bedroom in backgrounds")
	helpers.assert_contains(bg_ids, "kitchen", "kitchen in backgrounds")

	for bg_id in bg_ids:
		var path = Characters.get_background(bg_id)
		helpers.assert_not_empty(path, "Background path for %s" % bg_id)
		helpers.assert_true(path.begins_with("res://"), "Background path is res:// for %s" % bg_id)

func test_unknown_character_returns_empty() -> void:
	helpers.assert_eq(Characters.get_portrait("nobody", "neutral"), "", "Unknown char portrait returns empty")
	helpers.assert_eq(Characters.get_body("nobody", "pose1"), "", "Unknown char body returns empty")
	helpers.assert_eq(Characters.get_display_name("nobody"), "nobody", "Unknown char display name returns ID")
	helpers.assert_eq(Characters.get_accent_color("nobody"), Color.WHITE, "Unknown char accent returns white")

func test_unknown_expression_returns_empty() -> void:
	helpers.assert_eq(Characters.get_portrait("elena", "nonexistent"), "", "Unknown expression returns empty")

func test_unknown_background_returns_empty() -> void:
	helpers.assert_eq(Characters.get_background("nonexistent"), "", "Unknown background returns empty")

func test_character_data_completeness() -> void:
	for char_id in Characters.get_character_ids():
		var expressions = Characters.get_expressions(char_id)
		helpers.assert_eq(expressions.size(), 5, "%s has 5 expressions" % char_id)
		helpers.assert_contains(expressions, "neutral", "%s has neutral expression" % char_id)
		helpers.assert_contains(expressions, "happy", "%s has happy expression" % char_id)
		helpers.assert_contains(expressions, "flirt", "%s has flirt expression" % char_id)
		helpers.assert_contains(expressions, "surprised", "%s has surprised expression" % char_id)
		helpers.assert_contains(expressions, "annoyed", "%s has annoyed expression" % char_id)
