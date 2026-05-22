"""
Batch TTS Generator - generates all character dialogue lines using ComfyUI API
Uses voice cloning with character-specific voice design samples for consistency.
"""
import json
import os
import urllib.request
import urllib.error
import time
import shutil

COMFYUI_URL = "http://127.0.0.1:8189"
OUTPUT_DIR = r"C:\Users\D\Documents\sigma-date\assets\audio\tts"
OUTPUT_AUDIO_DIR = r"C:\Users\D\Documents\ComfyUI\output\audio\tts"

VOICE_INSTRUCTIONS = {
    "maya": "A bratty, energetic young adult female voice. Pitch is medium-high with playful sassiness. Bold, teasing, slightly flirtatious.",
    "elena": "A warm, mature adult female voice. Medium-low pitch with soft, nurturing quality. Gentle, caring, slightly shy when flustered.",
    "vanessa": "A confident, sophisticated adult female voice. Medium pitch with rich, slightly husky quality. Bold, direct, subtly flirtatious."
}

REF_TEXTS = {
    "maya": "Oh my god, he's actually here! The exchange student from overseas!",
    "elena": "Maya! Stop hovering by the window like a hawk. He hasn't even rung the bell yet!",
    "vanessa": "Well, well. So you're the famous exchange student."
}

REF_AUDIO_FILES = {
    "maya": "tts_maya_voice_design_00001_.mp3",
    "elena": "tts_elena_voice_design_00001_.mp3",
    "vanessa": "tts_vanessa_voice_design_00001_.mp3"
}


def extract_lines(story_path):
    with open(story_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    lines = []
    line_index = 0
    for entry in data['script']:
        if entry.get('type') == 'say':
            char_id = entry.get('char', '')
            text = entry.get('text', '')
            if char_id:
                lines.append({'index': line_index, 'char': char_id, 'text': text})
            line_index += 1
    return lines


def build_workflow_for_char(char_id, char_lines):
    """Build a ComfyUI workflow for a batch of lines for one character."""
    workflow = {}
    node_id = 1
    
    # Model loader
    workflow[str(node_id)] = {
        "class_type": "Qwen3TTSLoader",
        "inputs": {
            "attn_mode": "sdpa",
            "auto_download": False,
            "download_source": "HuggingFace",
            "model_repo": "Qwen/Qwen3-TTS-12Hz-1.7B-Base",
            "precision": "bf16"
        }
    }
    model_node = str(node_id)
    node_id += 1
    
    # Load reference audio
    workflow[str(node_id)] = {
        "class_type": "LoadAudio",
        "inputs": {"audio": REF_AUDIO_FILES[char_id]}
    }
    ref_audio_node = str(node_id)
    node_id += 1
    
    for line in char_lines:
        idx = line['index']
        text = line['text']
        
        # Voice clone node
        clone_node = str(node_id)
        workflow[clone_node] = {
            "class_type": "Qwen3TTSVoiceClone",
            "inputs": {
                "enable_x_vector_instant": False,
                "instruct": VOICE_INSTRUCTIONS[char_id],
                "max_new_tokens": 2048,
                "model_obj": [model_node, 0],
                "output_mode": "Concatenate (Merge)",
                "ref_audio": [ref_audio_node, 0],
                "ref_text": REF_TEXTS[char_id],
                "repetition_penalty": 1.05,
                "seed": 42,
                "target_language": "English",
                "target_text": text,
                "temperature": 0.9,
                "top_k": 50,
                "top_p": 1
            }
        }
        node_id += 1
        
        # Save node
        save_node = str(node_id)
        workflow[save_node] = {
            "class_type": "SaveAudioMP3",
            "inputs": {
                "audio": [clone_node, 0],
                "filename_prefix": f"audio/tts/tts_{char_id}_{idx}",
                "quality": "V0"
            }
        }
        node_id += 1
    
    return workflow


def enqueue_workflow(workflow):
    """Submit workflow to ComfyUI."""
    data = json.dumps({
        "prompt": workflow,
        "client_id": "batch_tts_generator"
    }).encode('utf-8')
    
    req = urllib.request.Request(
        f"{COMFYUI_URL}/prompt",
        data=data,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode('utf-8'))
            return result.get('prompt_id')
    except Exception as e:
        print(f"  Error enqueueing: {e}")
        return None


def wait_for_completion(prompt_id, timeout=3600):
    """Wait for workflow to complete."""
    start = time.time()
    while time.time() - start < timeout:
        try:
            req = urllib.request.Request(f"{COMFYUI_URL}/history/{prompt_id}")
            with urllib.request.urlopen(req, timeout=10) as resp:
                history = json.loads(resp.read().decode('utf-8'))
                if prompt_id in history:
                    status = history[prompt_id].get('status', {})
                    if status.get('completed', False):
                        return True
                    if status.get('status_str') == 'error':
                        print(f"  Error in workflow: {status}")
                        return False
        except Exception:
            pass
        time.sleep(5)
    print(f"  Timeout after {timeout}s")
    return False


def copy_output_files(char_lines):
    """Copy generated files from ComfyUI output to game assets."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for line in char_lines:
        char_id = line['char']
        idx = line['index']
        # Find the output file (ComfyUI adds _00001_ suffix)
        src_pattern = f"tts_{char_id}_{idx}_"
        try:
            output_files = [f for f in os.listdir(OUTPUT_AUDIO_DIR) 
                           if f.startswith(src_pattern) and f.endswith('.mp3')]
        except Exception:
            output_files = []
        
        if output_files:
            src = os.path.join(OUTPUT_AUDIO_DIR, output_files[0])
            dst = os.path.join(OUTPUT_DIR, f"tts_{char_id}_{idx}.mp3")
            try:
                shutil.copy2(src, dst)
                print(f"  Copied: {output_files[0]} -> tts_{char_id}_{idx}.mp3")
            except Exception as e:
                print(f"  Failed to copy {output_files[0]}: {e}")
        else:
            print(f"  Missing output for {char_id}_{idx}")


def main():
    story_path = r"C:\Users\D\Documents\sigma-date\data\story.json"
    lines = extract_lines(story_path)
    
    print(f"Total dialogue lines: {len(lines)}")
    
    by_char = {}
    for line in lines:
        c = line['char']
        if c not in by_char:
            by_char[c] = []
        by_char[c].append(line)
    
    for char_id in ['maya', 'elena', 'vanessa']:
        char_lines = by_char.get(char_id, [])
        if not char_lines:
            continue
        
        # Check which files already exist
        existing = [l for l in char_lines 
                   if os.path.exists(os.path.join(OUTPUT_DIR, f"tts_{char_id}_{l['index']}.mp3"))]
        missing = [l for l in char_lines 
                  if not os.path.exists(os.path.join(OUTPUT_DIR, f"tts_{char_id}_{l['index']}.mp3"))]
        
        print(f"\n=== {char_id}: {len(existing)} existing, {len(missing)} to generate ===")
        
        if not missing:
            print(f"  All {char_id} files already exist, skipping")
            continue
        
        workflow = build_workflow_for_char(char_id, missing)
        print(f"  Workflow has {len(workflow)} nodes ({len(missing)} lines)")
        
        prompt_id = enqueue_workflow(workflow)
        if not prompt_id:
            print(f"  Failed to enqueue {char_id} workflow")
            continue
        
        print(f"  Enqueued {char_id} workflow: {prompt_id}")
        print(f"  Waiting for completion (estimated ~{len(missing)*30}s)...")
        
        success = wait_for_completion(prompt_id)
        if success:
            print(f"  {char_id} workflow completed!")
            copy_output_files(missing)
        else:
            print(f"  {char_id} workflow failed or timed out")
        
        time.sleep(2)
    
    # Summary
    print("\n=== Generation Summary ===")
    total = 0
    for char_id in ['maya', 'elena', 'vanessa']:
        try:
            files = [f for f in os.listdir(OUTPUT_DIR) if f.startswith(f"tts_{char_id}_") and f.endswith('.mp3')]
        except Exception:
            files = []
        print(f"  {char_id}: {len(files)} files")
        total += len(files)
    print(f"  Total: {total} TTS files")


if __name__ == "__main__":
    main()
