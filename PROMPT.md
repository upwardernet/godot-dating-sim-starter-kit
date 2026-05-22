# Sigma Date — AI Game Dev Prompt

**Target:** opencode 1.14.31 + Qwen3.6 Plus on Windows 11
**Engine:** Godot 4.6.2 (GL Compatibility mode, D3D12 driver)
**Viewport:** 1280x720
**Genre:** 2D dating simulator

## Project Setup

### Links must to analyze and follow
https://docs.godotengine.org/en/stable/

### Godot Project Structure
```
sigma-date/
├── project.godot          # Godot 4.6 project file
├── scenes/
│   ├── main_menu.tscn     # Main menu scene
│   └── game.tscn          # Game scene (background + characters + dialogue)
├── scripts/
│   ├── main_menu.gd       # Menu controller
│   ├── game.gd            # Main game controller
│   ├── dialogue_box.gd    # Dialogue UI
│   ├── dialogue_manager.gd # Dialogue playback (signal-based)
│   ├── characters.gd      # Character data singleton (autoload)
│   ├── story.gd           # Story script loader (autoload)
│   └── audio_manager.gd   # BGM with crossfade (autoload)
├── data/
│   └── story.json         # Dialogue script (JSON)
├── assets/
│   ├── characters/{name}/ # Portraits + body poses per character
│   ├── backgrounds/       # Scene backgrounds
│   └── audio/bgm/         # BGM MP3 files
└── AGENTS.md              # AI agent instructions
```

### Autoloads (project.godot [autoload])
- `AudioManager` — `res://scripts/audio_manager.gd`
- `Characters` — `res://scripts/characters.gd`
- `DialogueManager` — `res://scripts/dialogue_manager.gd`
- `Story` — `res://scripts/story.gd`

### Key Commands
```
# Run game (auto-advance for testing)
godot_run_project  # tool call

# Test specific scene directly
godot_run_project with scene="res://scenes/game.tscn"

# Force auto-advance in game.gd:_ready for testing game.tscn directly:
if "--auto-advance" in OS.get_cmdline_args():
    DialogueManager.auto_advance = true
    DialogueManager.auto_advance_delay = 1.5

# Check debug output
godot_get_debug_output

# Stop game
godot_stop_project
```

### Testing Strategy
- **Never wait for manual playthrough.** Always use auto-advance
- Temporarily force `auto_advance = true` in `game.gd:_ready` when testing `game.tscn` directly (bypasses main menu)
- Game auto-quits at end of script — check `get_debug_output` for errors
- Revert test-only changes before finishing

## Architecture

### Game Flow
```
main_menu.tscn → game.tscn → Story autoload plays dialogue via signals → game.gd handles display
```

### Signal Flow
```
DialogueManager.line_started → dialogue_box._on_line_started → dialogue_box.line_confirmed → DialogueManager.advance()
```

## Story Premise

A university exchange student arrives from abroad for a semester abroad. They're hosted by a family of three women — each with their own personality, agenda, and interest in the newcomer. The story explores cultural adjustment, found family, and romantic tension as the student navigates university life while living under the same roof as three very different women.

**Episode 1: Arrival** — First impressions, choice branching between Maya (bold stepsis) and Elena (warm stepmom), and a surprise visit from Vanessa (predatory aunt).

### Dialogue Entry Types (JSON)
```json
{"type": "say", "char": "id", "expr": "expression", "text": "..."}  // dialogue (empty char = narrator)
{"type": "bg", "id": "living_room"}                                  // change background
{"type": "show", "char": "id", "expr": "expression"}                // show character
{"type": "hide", "char": "id"}                                      // hide character
{"type": "choice", "options": [{"text": "...", "jump": "label"}]}   // player choice
{"type": "flag", "set": "name", "value": 1}                         // set story flag
{"type": "jump", "label": "name"}                                   // jump to label
{"type": "label", "label": "name"}                                  // jump target
{"type": "wait", "duration": 0.5}                                   // pause
```

### Character Data (characters.gd)
```gdscript
# Access via Characters.get_portrait("elena", "happy")
# Character node names use .to_pascal_case() (e.g., "elena" → "Elena")
```

### Asset Paths
- Character portraits: `Characters.get_portrait(char_id, expression)` → `res://assets/characters/{name}/{name}_portrait_{expr}.png`
- Character bodies: `Characters.get_body(char_id, pose)` → `res://assets/characters/{name}/{name}_body_{pose}.png`
- Backgrounds: `Characters.get_background(bg_id)` → `res://assets/backgrounds/bg_{id}.png`
- BGM: `res://assets/audio/bgm/bgm_{id}.mp3`
- SFX: `res://assets/audio/sfx/sfx_{id}.mp3` (click, type, choice, transition)

## Characters

### Elena (Stepmom)
- **Appearance:** Auburn hair, soft brown eyes, fair skin
- **Personality:** Shy/bashful, warm caregiver, easily embarrassed
- **Accent color:** Red `Color(0.8, 0.3, 0.2)`
- **Expressions:** neutral, happy, flirt, surprised, annoyed

### Maya (Stepsis)
- **Appearance:** Long blonde hair, blue eyes, fair skin
- **Personality:** Bold, initiator, bratty tease, playful
- **Accent color:** Gold `Color(0.9, 0.7, 0.2)`
- **Expressions:** neutral, happy, flirt, surprised, annoyed

### Vanessa (Aunt)
- **Appearance:** Long dark black hair, green eyes, fair skin
- **Personality:** Direct, sophisticated, confident
- **Accent color:** Purple `Color(0.4, 0.3, 0.8)`
- **Expressions:** neutral, happy, flirt, surprised, annoyed

## Asset Generation (ComfyUI)

### Environment
- ComfyUI runs on `127.0.0.1:8188`
- Workflows stored in: `C:\Users\D\Documents\ComfyUI\user\default\workflows\ai\`
- Output directory: `C:\Users\D\Documents\ComfyUI\output\`

### CRITICAL: KSampler Bug on Windows
**Standard `KSampler` crashes** with `OSError: [Errno 22] Invalid argument` caused by Windows tqdm logging bug.

**Solution:** Use `easy fullkSampler` + `easy pipeIn` nodes instead. These are from the `comfyui-easy-use` custom node pack and work reliably on Windows.

### Model Strategy

Use a general-purpose image generation model for all assets.

### Working Workflows (saved to `workflows/ai/`)

#### 1. Character Image
- **Model:** General-purpose image generation model
- **CLIP:** `qwen_3_4b.safetensors` (type: lumina2)
- **VAE:** `ae.safetensors`
- **Settings:** 8 steps, CFG=1, sampler=res_multistep, scheduler=simple
- **Sampler:** easy fullkSampler (NOT KSampler)
- **Resolution:** 512x512 for portraits, 512x768 for body poses
- **Negative:** `anime, cartoon, drawing, illustration, painting, low quality, blurry, deformed`

**SFW Portrait Example Prompt:**
```
A portrait of a woman with auburn hair, soft brown eyes, fair skin, wearing a fitted white blouse. Realistic photographic portrait, professional photography, natural lighting, high quality, photorealistic.
```

### Asset Generation Checklist Per Character
- **Node:** `easy imageRemBg`
- **Model:** `RMBG-1.4` (RMBG-2.0 is gated/requires HuggingFace auth)
- **Settings:** `add_background=none`, `refine_foreground=false`, `rem_mode=RMBG-1.4`
- **Input:** LoadImage → easy imageRemBg → SaveImage
- **Output:** PNG with transparent background

#### 3. BGM Audio (`bgm_ace_step1_5.json`)
- **Use ACE Turbo** — `acestep_v1.5_xl_turbo_bf16.safetensors` (UNETLoader)
- **CLIP:** DualCLIPLoader — `qwen_0.6b_ace15.safetensors` + `qwen_4b_ace15.safetensors` (type: ace)
- **VAE:** `ace_1.5_vae.safetensors`
- **Node:** `TextEncodeAceStepAudio1.5` with tags, lyrics, bpm, keyscale
- **Sampler:** Standard `KSampler` works for audio (different code path)
- **Settings:** 8 steps, CFG=1, sampler=euler, scheduler=simple
- **Output:** `SaveAudioMP3` → `audio/bgm_{name}.mp3`
- **Duration:** 30 seconds per track
- **Workflow saved:** `workflows/ai/bgm_ace_step1_5.json`

**ACE Turbo Prompt Example:**
```
Tags: Romantic Piano, Soft Strings, Dating Sim BGM, Emotional, Warm
Lyrics: [Instrumental]\nSoft piano intro building to warm strings\nGentle romantic melody\nPerfect for a dating sim main menu\nEmotional and inviting
BPM: 95 | Keyscale: E minor | Duration: 30s
```

#### 4. SFX Audio (`sfx_ace_turbo.json`)
- **Use ACE Turbo** — `acestep_v1.5_xl_turbo_bf16.safetensors` (UNETLoader)
- **CLIP:** DualCLIPLoader — `qwen_0.6b_ace15.safetensors` + `qwen_4b_ace15.safetensors` (type: ace)
- **VAE:** `ace_1.5_vae.safetensors`
- **Node:** `TextEncodeAceStepAudio1.5` with tags, lyrics, bpm, keyscale
- **Sampler:** Standard `KSampler` works for audio (different code path)
- **Settings:** 8 steps, CFG=1, sampler=euler, scheduler=simple
- **Output:** `SaveAudioMP3` → `audio/sfx_{name}.mp3`
- **Duration:** 1-2 seconds per SFX
- **Workflow saved:** `workflows/ai/sfx_ace_turbo.json`

**SFX Prompt Examples:**
```
# UI Click (1s)
Tags: UI Click, Button Press, Digital Click, Short, Crisp
Lyrics: [Instrumental]\nShort crisp UI click sound\nClean digital click\nPerfect for button press
BPM: 120 | Keyscale: C major | Duration: 1s

# Typing Sound (1s)
Tags: Typing Sound, Keyboard Tap, Soft Click, UI Sound
Lyrics: [Instrumental]\nSoft typing sound effect\nGentle keyboard tap\nRepeated soft clicks for dialogue typing
BPM: 100 | Keyscale: C major | Duration: 1s

# Choice Select (1s)
Tags: Selection Chime, Choice Confirm, Positive UI Sound, Bright
Lyrics: [Instrumental]\nBright selection chime\nPositive confirmation sound\nPleasant UI choice selection
BPM: 110 | Keyscale: G major | Duration: 1s

# Transition (2s)
Tags: Transition Swoosh, Scene Change, Whoosh, Smooth, Soft
Lyrics: [Instrumental]\nSmooth scene transition swoosh\nGentle whoosh sound\nSoft fade between scenes
BPM: 90 | Keyscale: D minor | Duration: 2s
```

### Workflow Node Pattern
```
UNETLoader → ModelSamplingAuraFlow(shift=3) → easy pipeIn → easy fullkSampler
CLIPLoader(type=lumina2) → CLIPTextEncode (pos + neg)
VAELoader → EmptySD3LatentImage (512x512 or 512x768)
ConditioningZeroOut (for negative conditioning)
```

### Image-to-Image via ComfyUI

Use image-to-image when you need to maintain character consistency across expressions/poses.

**Method: LoadImage + VAEEncode + KSampler with denoise < 1.0**

```
LoadImage → VAEEncode → easy pipeIn → easy fullkSampler
                                     ↓
CLIPLoader → CLIPTextEncode (describes desired changes)
VAELoader ↗
```

**Key settings for img2img:**
- `denoise`: 0.3-0.5 for subtle changes (expression tweaks), 0.6-0.8 for major changes (pose/clothing)
- `steps`: 8-12 (Z-Image-Turbo is fast, fewer steps needed)
- `cfg`: 1 (Z-Image-Turbo works best at CFG=1)
- `sampler`: res_multistep
- `scheduler`: simple

**Example: Change neutral portrait to happy expression**
1. LoadImage → existing neutral portrait
2. VAEEncode → converts to latent
3. CLIPTextEncode → `"A beautiful woman with auburn hair, warm happy smile, bright eyes. must have clothes. Realistic photographic portrait, professional photography, no anime."`
4. easy fullkSampler → denoise=0.5, seed=different from original
5. Output → new expression variant

**Tips for consistent character faces:**
- Generate one base portrait first (text-to-image) with a good seed
- Use that base as input for all expression variants (img2img, denoise 0.4-0.6)
- Keep the core description identical, only change expression keywords
- Use different seeds per variant to avoid identical outputs
- If face drifts too much, lower denoise to 0.3-0.4

### Asset Generation Checklist Per Character
1. **1 base portrait** (512x512): neutral expression, text-to-image
2. **4 expression variants** (512x512): happy, flirt, surprised, annoyed — img2img from base, denoise 0.5
3. **2 body poses** (512x768): standing, sitting/casual — text-to-image or img2img
4. **Remove backgrounds** from all body poses using `remove_background_easy_rembg.json`
5. Use **different seeds** per variation (e.g., 42 for base, 101-104 for expressions, 401-402 for bodies)

### Copy Assets to Game
```powershell
# Portraits
Copy-Item "C:\Users\D\Documents\ComfyUI\output\{char}_portrait_{expr}_00001_.png" "C:\Users\D\Documents\sigma-date\assets\characters\{char}\{char}_portrait_{expr}.png" -Force

# Body poses (background-removed)
Copy-Item "C:\Users\D\Documents\ComfyUI\output\{char}_body_pose{N}_nobg_00001_.png" "C:\Users\D\Documents\sigma-date\assets\characters\{char}\{char}_body_pose{N}.png" -Force

# BGM
New-Item -ItemType Directory -Path "C:\Users\D\Documents\sigma-date\assets\audio\bgm" -Force
Copy-Item "C:\Users\D\Documents\ComfyUI\output\audio\bgm_{name}_00001_.mp3" "C:\Users\D\Documents\sigma-date\assets\audio\bgm\bgm_{name}.mp3" -Force

# SFX
New-Item -ItemType Directory -Path "C:\Users\D\Documents\sigma-date\assets\audio\sfx" -Force
Copy-Item "C:\Users\D\Documents\ComfyUI\output\audio\sfx_{name}_00001_.mp3" "C:\Users\D\Documents\sigma-date\assets\audio\sfx\sfx_{name}.mp3" -Force
```

## UI Conventions
- Dialogue box has typing animation (click to skip), pulsing "▼ Click to continue" indicator
- Narrator text (empty char): hides portrait/name, text fills full width
- Dark overlay (`DarkOverlay` ColorRect) behind dialogue box for readability
- All UI transitions use `create_tween()` for fade-in/out effects
- Settings panel in main menu: overlay with music/SFX volume sliders
- **Speaker name is clickable** — click to rename a character (stored in `custom_names` dict, persists per session)
- Name panel and dialogue text have **4px padding** from borders (via StyleBoxFlat content margins and MarginContainer)

## BGM Track Recommendations
- `bgm_menu` — Main menu theme (romantic piano, warm strings)
- `bgm_light` — Casual/happy scenes (acoustic guitar, upbeat)
- `bgm_romantic` — Flirt/romance scenes (sensual saxophone, slow jazz)
- `bgm_tension` — Vanessa/mysterious scenes (dark synth, atmospheric)

## Common Issues & Fixes

### KSampler crashes on Windows
- **Fix:** Use `easy fullkSampler` + `easy pipeIn` instead

### RMBG-2.0 gated model error
- **Error:** `Cannot access gated repo... Access to model briaai/RMBG-2.0 is restricted`
- **Fix:** Use `RMBG-1.4` instead — it's free and works without authentication

### Qwen Image Edit dimension mismatch
- **Error:** `expected normalized_shape=[3584], got input of size[1, 90, 2560]`
- **Fix:** Use a general-purpose image generation model for all assets with prompt keywords to control clothing level.

### easy fullkSampler with audio latents
- **Error:** `tuple index out of range` on audio latent shape
- **Fix:** Use standard `KSampler` for ACE Turbo audio workflows (different code path), only use easy fullkSampler for image workflows

### Godot auto-advance not triggering
- `godot_run_project` tool doesn't pass `--auto-advance` CLI arg
- **Fix:** Temporarily force `DialogueManager.auto_advance = true` in `game.gd:_ready` for testing, revert before finishing

### Main menu doesn't auto-start
- **Fix:** Add auto-start logic to `main_menu.gd:_ready`:
```gdscript
if "--auto-advance" in OS.get_cmdline_args():
    await get_tree().create_timer(0.5).timeout
    _on_start_pressed()
    return
```

## Godot Code Patterns

### Tween fade-in
```gdscript
modulate = Color(1, 1, 1, 0)
var tween = create_tween()
tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)
```

### Signal connection
```gdscript
dialogue_box.line_confirmed.connect(func():
    DialogueManager.advance())
```

### Load texture safely
```gdscript
var path = Characters.get_portrait(char_id, expression)
if path and ResourceLoader.exists(path):
    var texture = load(path)
```

## Godot 4.6 Enum Reference

### TextureRect
| Constant | Value |
|----------|-------|
| `EXPAND_FIT_WIDTH` | 2 |
| `EXPAND_FIT_HEIGHT_PROPORTIONAL` | 5 |
| `STRETCH_KEEP_ASPECT` | 4 |
| `STRETCH_KEEP_ASPECT_CENTERED` | 5 |
| `STRETCH_KEEP_ASPECT_COVERED` | 6 |
| `STRETCH_KEEP_CENTERED` | 3 |

### Scene File (.tscn) Gotchas
- **Remove `load_steps` from header** — deprecated in Godot 4.6, causes warnings
- **Remove `mouse_filter` from root Control** if set to `2` (IGNORE) — default is `0` (STOP)
- Always verify enum values match Godot 4.6 constants

## Audio Bus Configuration

Add to `project.godot` for proper bus routing:
```ini
[audio]

bus/main/sends=[Array]
bus/main/solo=false
bus/main/mute=false
bus/main/volume_db=0.0
bus/main/effects=[Array]
bus/Music/sends=[Array]
bus/Music/solo=false
bus/Music/mute=false
bus/Music/volume_db=0.0
bus/Music/effects=[Array]
bus/SFX/sends=[Array]
bus/SFX/solo=false
bus/SFX/mute=false
bus/SFX/volume_db=0.0
bus/SFX/effects=[Array]
```

**Important:** If custom buses aren't defined, use `"Master"` bus in `AudioStreamPlayer.bus` — assigning to a non-existent bus causes silent failure.

## BGM Per-Scene Mapping

| Scene | BGM ID | Mood |
|-------|--------|------|
| Main menu | `menu` | Romantic piano, warm strings |
| Living room | `light` | Casual, acoustic guitar |
| Bedroom | `romantic` | Intimate, slow jazz |
| Kitchen | `light` | Upbeat, cheerful |
| Park | `light` | Bright, nature |
| Cafe | `tension` | Smooth jazz, urban |

Call `AudioManager.play_bgm(id)` in:
- `main_menu.gd:_ready()` → `"menu"`
- `game.gd:_ready()` → `"light"` (or change per background via `set_background()`)

## Story Autoload Pattern

Story autoload must defer its start to ensure dialogue_box signals are connected first:
```gdscript
# story.gd
func _ready() -> void:
    call_deferred("_start_deferred")

func _start_deferred() -> void:
    DialogueManager.load_script(SCRIPT)
    DialogueManager._start_dialogue()
```

## Plan Files Location (Windows)

- **Global plans:** `C:\Users\D\.local\share\opencode\plans\`
- **Project-local plans:** `C:\Users\D\Documents\sigma-date\.opencode\plans\`
- **This prompt file:** `C:\Users\D\Documents\sigma-date\PROMPT.md`
