extends Node

# Character data singleton - all three women
# Access via Characters.get_portrait("elena", "happy")

const CHARACTER_DATA = {
	"elena": {
		"display_name": "Elena",
		"role": "Stepmom",
		"accent_color": Color(0.8, 0.3, 0.2),
		"portraits": {
			"neutral": "res://assets/characters/elena/elena_portrait_neutral.png",
			"happy": "res://assets/characters/elena/elena_portrait_happy.png",
			"flirt": "res://assets/characters/elena/elena_portrait_flirt.png",
			"surprised": "res://assets/characters/elena/elena_portrait_surprised.png",
			"annoyed": "res://assets/characters/elena/elena_portrait_annoyed.png",
		},
		"bodies": {
			"pose1": "res://assets/characters/elena/elena_body_pose1.png",
			"pose2": "res://assets/characters/elena/elena_body_pose2.png",
		},
	},
	"maya": {
		"display_name": "Maya",
		"role": "Stepsis",
		"accent_color": Color(0.9, 0.7, 0.2),
		"portraits": {
			"neutral": "res://assets/characters/maya/maya_portrait_neutral.png",
			"happy": "res://assets/characters/maya/maya_portrait_happy.png",
			"flirt": "res://assets/characters/maya/maya_portrait_flirt.png",
			"surprised": "res://assets/characters/maya/maya_portrait_surprised.png",
			"annoyed": "res://assets/characters/maya/maya_portrait_annoyed.png",
		},
		"bodies": {
			"pose1": "res://assets/characters/maya/maya_body_pose1.png",
			"pose2": "res://assets/characters/maya/maya_body_pose2.png",
		},
	},
	"vanessa": {
		"display_name": "Vanessa",
		"role": "Aunt",
		"accent_color": Color(0.4, 0.3, 0.8),
		"portraits": {
			"neutral": "res://assets/characters/vanessa/vanessa_portrait_neutral.png",
			"happy": "res://assets/characters/vanessa/vanessa_portrait_happy.png",
			"flirt": "res://assets/characters/vanessa/vanessa_portrait_flirt.png",
			"surprised": "res://assets/characters/vanessa/vanessa_portrait_surprised.png",
			"annoyed": "res://assets/characters/vanessa/vanessa_portrait_annoyed.png",
		},
		"bodies": {
			"pose1": "res://assets/characters/vanessa/vanessa_body_pose1.png",
			"pose2": "res://assets/characters/vanessa/vanessa_body_pose2.png",
		},
	},
}

const BACKGROUND_PATHS = {
	"living_room": "res://assets/backgrounds/bg_living_room.png",
	"bedroom": "res://assets/backgrounds/bg_bedroom.png",
	"kitchen": "res://assets/backgrounds/bg_kitchen.png",
	"park": "res://assets/backgrounds/bg_park.png",
	"cafe": "res://assets/backgrounds/bg_cafe.png",
}

func get_portrait(char_id: String, expression: String) -> String:
	if CHARACTER_DATA.has(char_id):
		var portraits = CHARACTER_DATA[char_id]["portraits"]
		if portraits.has(expression):
			return portraits[expression]
	return ""

func get_body(char_id: String, pose: String) -> String:
	if CHARACTER_DATA.has(char_id):
		var bodies = CHARACTER_DATA[char_id]["bodies"]
		if bodies.has(pose):
			return bodies[pose]
	return ""

func get_display_name(char_id: String) -> String:
	if CHARACTER_DATA.has(char_id):
		return CHARACTER_DATA[char_id]["display_name"]
	return char_id

func get_accent_color(char_id: String) -> Color:
	if CHARACTER_DATA.has(char_id):
		return CHARACTER_DATA[char_id]["accent_color"]
	return Color.WHITE

func get_background(bg_id: String) -> String:
	if BACKGROUND_PATHS.has(bg_id):
		return BACKGROUND_PATHS[bg_id]
	return ""

func get_character_ids() -> Array:
	return CHARACTER_DATA.keys()

func get_expressions(char_id: String) -> Array:
	if CHARACTER_DATA.has(char_id):
		return CHARACTER_DATA[char_id]["portraits"].keys()
	return []

func get_background_ids() -> Array:
	return BACKGROUND_PATHS.keys()
