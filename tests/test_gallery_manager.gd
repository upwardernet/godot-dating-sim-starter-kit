# Unit tests for GalleryManager.gd — unlock/persistence logic

var helpers = null

func _init(h) -> void:
	helpers = h

func run_all() -> void:
	test_portrait_unlock()
	test_portrait_double_unlock_no_dup()
	test_background_unlock()
	test_background_double_unlock_no_dup()
	test_portrait_check_unlocked()
	test_background_check_unlocked()
	test_gallery_stats()
	test_gallery_persistence()
	test_get_unlocked_expressions()

func test_portrait_unlock() -> void:
	GalleryManager.unlock_portrait("elena", "happy")
	helpers.assert_true(GalleryManager.is_portrait_unlocked("elena", "happy"), "Portrait unlocked after unlock")

func test_portrait_double_unlock_no_dup() -> void:
	GalleryManager.unlock_portrait("maya", "flirt")
	GalleryManager.unlock_portrait("maya", "flirt")
	var expressions = GalleryManager.get_unlocked_expressions("maya")
	var count = 0
	for e in expressions:
		if e == "flirt":
			count += 1
	helpers.assert_eq(count, 1, "Portrait not duplicated on double unlock")

func test_background_unlock() -> void:
	GalleryManager.unlock_background("living_room")
	helpers.assert_true(GalleryManager.is_background_unlocked("living_room"), "Background unlocked after unlock")

func test_background_double_unlock_no_dup() -> void:
	GalleryManager.unlock_background("kitchen")
	GalleryManager.unlock_background("kitchen")
	var count = 0
	for bg in GalleryManager.unlocked_backgrounds:
		if bg == "kitchen":
			count += 1
	helpers.assert_eq(count, 1, "Background not duplicated on double unlock")

func test_portrait_check_unlocked() -> void:
	helpers.assert_false(GalleryManager.is_portrait_unlocked("nobody", "neutral"), "Unknown char portrait not unlocked")
	helpers.assert_false(GalleryManager.is_portrait_unlocked("elena", "nonexistent"), "Unknown expression not unlocked")

func test_background_check_unlocked() -> void:
	helpers.assert_false(GalleryManager.is_background_unlocked("nonexistent"), "Unknown background not unlocked")

func test_gallery_stats() -> void:
	GalleryManager.unlock_portrait("elena", "neutral")
	GalleryManager.unlock_portrait("elena", "happy")
	GalleryManager.unlock_background("living_room")

	var stats = GalleryManager.get_gallery_stats()
	helpers.assert_true(stats.has("characters"), "Stats has characters")
	helpers.assert_true(stats.has("portraits_unlocked"), "Stats has portraits_unlocked")
	helpers.assert_true(stats.has("backgrounds_unlocked"), "Stats has backgrounds_unlocked")
	helpers.assert_true(stats.get("portraits_unlocked", 0) >= 2, "At least 2 portraits unlocked")
	helpers.assert_true(stats.get("backgrounds_unlocked", 0) >= 1, "At least 1 background unlocked")

	var elena_stats = stats["characters"].get("elena", {})
	helpers.assert_eq(elena_stats.get("unlocked", 0), 2, "Elena has 2 unlocked portraits")
	helpers.assert_eq(elena_stats.get("total", 0), 5, "Elena has 5 total portraits")

func test_gallery_persistence() -> void:
	GalleryManager.unlock_portrait("vanessa", "surprised")
	GalleryManager.unlock_background("park")

	var gallery_path = "user://gallery.json"
	helpers.assert_true(FileAccess.file_exists(gallery_path), "Gallery file exists after unlocks")

	var file = FileAccess.open(gallery_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		helpers.assert_eq(parse_result, OK, "Gallery file parses correctly")
		var data = json.get_data()
		helpers.assert_true(data.has("portraits"), "Gallery data has portraits")
		helpers.assert_true(data.has("backgrounds"), "Gallery data has backgrounds")
	else:
		helpers.assert_true(false, "Gallery file can be opened for reading")

func test_get_unlocked_expressions() -> void:
	helpers.assert_true(GalleryManager.get_unlocked_expressions("nobody").is_empty(), "Unknown char has no expressions")
