extends Node

# GalleryManager — tracks which character portraits, tier images, and backgrounds have been seen.
# Persists across save slots to user://gallery.json (meta-progression, not per-save).

const GALLERY_PATH = "user://gallery.json"

var unlocked_portraits: Dictionary = {}  # { "elena": ["neutral", "happy", ...], ... }
var unlocked_backgrounds: PackedStringArray = []
var unlocked_bodies: Dictionary = {}  # { "elena": ["pose1", "pose2"], ... }

signal gallery_changed

func _ready() -> void:
	_load_gallery()

func unlock_portrait(char_id: String, expression: String) -> void:
	if not unlocked_portraits.has(char_id):
		unlocked_portraits[char_id] = []
	var expressions: Array = unlocked_portraits[char_id]
	if not expressions.has(expression):
		expressions.append(expression)
		_save_gallery()
		gallery_changed.emit()

func unlock_background(bg_id: String) -> void:
	if not unlocked_backgrounds.has(bg_id):
		unlocked_backgrounds.append(bg_id)
		_save_gallery()
		gallery_changed.emit()

func unlock_body(char_id: String, pose: String) -> void:
	if not unlocked_bodies.has(char_id):
		unlocked_bodies[char_id] = []
	var poses: Array = unlocked_bodies[char_id]
	if not poses.has(pose):
		poses.append(pose)
		_save_gallery()
		gallery_changed.emit()

func is_portrait_unlocked(char_id: String, expression: String) -> bool:
	if not unlocked_portraits.has(char_id):
		return false
	return unlocked_portraits[char_id].has(expression)

func is_background_unlocked(bg_id: String) -> bool:
	return unlocked_backgrounds.has(bg_id)

func is_body_unlocked(char_id: String, pose: String) -> bool:
	if not unlocked_bodies.has(char_id):
		return false
	return unlocked_bodies[char_id].has(pose)

func get_unlocked_expressions(char_id: String) -> Array:
	if unlocked_portraits.has(char_id):
		return unlocked_portraits[char_id]
	return []

func get_gallery_stats() -> Dictionary:
	var total_portraits = 0
	var unlocked_count = 0
	var char_data = {}
	for char_id in Characters.get_character_ids():
		var all_expr = Characters.get_expressions(char_id)
		var unlocked = get_unlocked_expressions(char_id)
		total_portraits += all_expr.size()
		unlocked_count += unlocked.size()
		char_data[char_id] = {
			"total": all_expr.size(),
			"unlocked": unlocked.size(),
			"expressions": all_expr.duplicate(),
		}
	var bg_all = Characters.get_background_ids()
	var bg_unlocked = unlocked_backgrounds.size()
	return {
		"characters": char_data,
		"portraits_unlocked": unlocked_count,
		"portraits_total": total_portraits,
		"backgrounds_unlocked": bg_unlocked,
		"backgrounds_total": bg_all.size(),
		"background_ids": bg_all
	}

func has_any_unlocks() -> bool:
	return unlocked_portraits.size() > 0 or unlocked_backgrounds.size() > 0 or unlocked_bodies.size() > 0

func reset_all() -> void:
	unlocked_portraits.clear()
	unlocked_backgrounds.clear()
	unlocked_bodies.clear()
	_save_gallery()
	gallery_changed.emit()
	print("[GalleryManager] Gallery reset")

func _save_gallery() -> void:
	var data = {
		"portraits": unlocked_portraits,
		"backgrounds": unlocked_backgrounds,
		"bodies": unlocked_bodies
	}
	var file = FileAccess.open(GALLERY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_gallery() -> void:
	if not FileAccess.file_exists(GALLERY_PATH):
		return
	var file = FileAccess.open(GALLERY_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		if parse_result == OK:
			var data = json.get_data()
			unlocked_portraits = data.get("portraits", {})
			unlocked_backgrounds = PackedStringArray(data.get("backgrounds", []))
			unlocked_bodies = data.get("bodies", {})
