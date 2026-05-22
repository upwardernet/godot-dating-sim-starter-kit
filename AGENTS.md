# AGENTS.md

## Project
- Godot 4.6 ("Sigma Date") — 2D visual novel / dating simulator
- Rendering: GL Compatibility, D3D12 on Windows
- Viewport: 1280x720
- Main scene: `res://scenes/main_menu.tscn`

## Other Docs
- `README.md` — milestones, character voice personas, conventions
- `PROMPT.md` — ComfyUI workflows, asset generation, Godot patterns, enum reference, audio bus config

## Directory Structure
```
scenes/          — .tscn files (main_menu, game, dialogue_box, save_load_menu, gallery_menu)
scripts/         — All .gd scripts except data/script.gd
data/            — story.json + script.gd (Story autoload, NOT in scripts/)
tests/           — test_runner.tscn + 6 test suites + test_helpers.gd
assets/          — characters/, backgrounds/, audio/ (bgm, sfx, tts)
workflows/       — ComfyUI workflow JSONs
```

## Commands
- Open editor / run game: `godot_run_project`
- Test specific scene: `godot_run_project` with `scene` param (e.g. `res://scenes/game.tscn`)
- Check errors: `godot_get_debug_output` — game auto-quits at end of script
- Stop game: `godot_stop_project`
- **CRITICAL: `godot_run_project` does NOT pass `--auto-advance`.** To test, temporarily uncomment auto-skip block in `game.gd:_ready` (lines 96-100), then revert before committing.
- **Revert all test-only changes** before finishing.

## Test Suite
- **Runner:** `res://tests/test_runner.tscn` — 6 suites (characters, save, gallery, dialogue, full story, TTS)
- **Run:** Open `test_runner.tscn` in Godot, or `godot --path . res://tests/test_runner.tscn`
- **Files:**
  - `tests/test_helpers.gd` — Assertion helpers (assert_eq, assert_true, assert_contains, etc.)
  - `tests/test_characters.gd` — Character IDs, display names, accent colors, asset paths, unknown char handling
  - `tests/test_save_manager.gd` — Save/load roundtrip, metadata, delete, has_save, version, constants
  - `tests/test_gallery_manager.gd` — Portrait/tier/background unlocks, no-duplication, stats, persistence
  - `tests/test_dialogue_manager.gd` — Script loading, deep copy, flags, jumps, stop, auto-advance, entry types
  - `tests/test_dialogue_full.gd` — story.json structure, all labels/jumps valid, say_index uniqueness, choice branches, attraction changes, character/expression/background references, route convergence
  - `tests/test_tts_manager.gd` — Enable/disable, display names, cache, has_line
- **Adding tests:** Create `test_*.gd` in `tests/` with `run_all()` method and `_init(h)` constructor. Register in `test_runner.gd`.

## Architecture
- **Autoloads** (`project.godot [autoload]`):
  - `AudioManager` — BGM crossfade + SFX (`play_bgm(id)`, `play_sfx(id)`, `set_volume()`)
  - `Characters` — portrait/body/background path resolution
  - `DialogueManager` — signal-based dialogue playback (choices/flags/jumps)
  - `Story` — loads `data/story.json`, calls `DialogueManager.start()` on load. Script at `res://data/script.gd` (outside `scripts/`)
  - `SaveManager` — 3-slot save/load (`save_game(slot, state)`, `load_game(slot)`)
  - `Screenshot` — automated captures (`capture_now(label)`). Disabled by default.
  - `TTSManager` — per-character TTS playback (`play_line(char_id, say_index)`, `set_enabled()`)
  - `GalleryManager` — persistent gallery unlocks. Saves to `user://gallery.json` (meta-progression, not per-save).
- **Scenes**: `main_menu.tscn` → `game.tscn` → `dialogue_box.tscn` (reusable UI) → `save_load_menu.tscn` (overlay) → `gallery_menu.tscn`
- **Signal flow**: `DialogueManager.line_started` → `dialogue_box._on_line_started` → `dialogue_box.line_confirmed` → `DialogueManager.advance()`
- **Gallery unlocks**: `game.gd:show_character()` calls `GalleryManager.unlock_portrait()`, `game.gd:set_background()` calls `GalleryManager.unlock_background()`

## Story Format
- `data/story.json` — JSON script with `script` array
- Entry types: `label`, `say`, `bg`, `show`, `hide`, `choice`, `flag`, `jump`, `wait`, `change_attraction`
- `say` with empty `char` = narrator text (hides portrait, full-width text)
- `say_index` counts ALL `say` entries (including narrator). Only character lines (non-empty `char`) get TTS files.

## Characters
- **Elena** (stepmom) — accent: red. Expressions: neutral, happy, flirt, surprised, annoyed
- **Maya** (stepsis) — accent: gold. Expressions: neutral, happy, flirt, surprised, annoyed
- **Vanessa** (aunt) — accent: purple. Expressions: neutral, happy, flirt, surprised, annoyed
- Character node names use `.to_pascal_case()` (e.g. "elena" → "Elena")
- Full voice personas: see `README.md`

## Gallery System
- Gallery menu is **data-driven** from `characters.gd` constants.
- To add characters/expressions/backgrounds, **only update `characters.gd`**:
  - Add to `CHARACTER_DATA` → new tab auto-appears
  - Add key to character's `"portraits"` dict → new slot auto-appears
  - Add to `BACKGROUND_PATHS` → new slot auto-appears
- No scene/UI changes needed. `gallery_menu.gd` queries `Characters.get_character_ids()`, `get_expressions()`, `get_background_ids()` at runtime.

## TTS Voice Generation
- Model: `Qwen/Qwen3-TTS-12Hz-1.7B-Base`
- **After regenerating TTS: delete old files, clear `.godot/imported/`, reimport in Godot editor**
- Python helpers: `scripts/tts_batch_generate.py`, `scripts/extract_lines.py`
- Full workflow: see `PROMPT.md`

## Testing Gotchas
- **6MB REQUEST BODY LIMIT:** LLM API rejects requests >6MB. Screenshots auto-downscale to 640px width in `screenshot.gd` (~250-500KB). **NEVER remove the downscale.**
- Auto-skip and screenshot capture are **disabled by default**. Enable temporarily in `game.gd:_ready` for testing, revert before commit.
- Game auto-quits at end of script when auto-advance is on (`dialogue_box.gd:270-275`). Expected behavior.
- Read screenshots with `read` tool to verify UI layout, positioning, visual correctness
- **Screenshot CLI flag:** Pass `--screenshots` to capture frames every 2s to `user://screenshots/`

## Conventions
- **GDScript indentation:** Tabs. `.editorconfig` sets `charset = utf-8`. `.gitattributes` enforces LF line endings.
- `game.tscn` root `Game` node requires `anchors_preset=15` for child UI to inherit viewport bounds
- Dark overlay (`DarkOverlay` ColorRect) behind dialogue box in game.tscn
- All UI transitions use `create_tween()`
- **Attraction system:** Choices use `change_attraction` entries in story.json. `game.gd:_on_attraction_changed` updates scores and checks for game over (all three at 0).
- Affection flags: `maya_affection`, `elena_affection`, `vanessa_affection` → mapped to attraction scores in `game.gd:_on_flag_changed`
- Save state: dialogue_index, flags, attraction_scores, play_time
- `Story.load_slot` defaults to -1 (no save). Set by main menu Continue; `game.gd` checks on `_ready`
- `.uid` files are committed (Godot 4.4+ UID tracking). Do not delete them.
- `.gitignore` is minimal: only `.godot/` and `/android/`
- **Container choice:** `HSplitContainer`/`VSplitContainer` are for exactly 2 children. For 3+ children, use `HBoxContainer`, `VBoxContainer`, or `GridContainer`.
- **.tscn file gotchas:** Remove `load_steps` from header (deprecated in 4.6). Remove `mouse_filter` from root Control if set to `2` (IGNORE) — default is `0` (STOP).
- **PROMPT.md partially stale:** Its Story autoload path (`scripts/story.gd`) is wrong — real path is `data/script.gd`.

## Git Workflow
- `main` — stable, release-ready
- `dev` — active development
- `feature/*` — individual features, merged into `dev`
- `hotfix/*` — urgent fixes, merged into `main` and `dev`
