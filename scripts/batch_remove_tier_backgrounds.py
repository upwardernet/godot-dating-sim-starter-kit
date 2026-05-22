"""
Batch Background Removal for Tier Images
Uses ComfyUI API to remove backgrounds from all character tier images.
"""
import json
import os
import shutil
import time
import urllib.request
import urllib.error

COMFYUI_URL = "http://127.0.0.1:8188"
TIER_DIR = r"C:\Users\D\Documents\sigma-date\assets\characters"
COMFYUI_INPUT = r"C:\Users\D\Documents\ComfyUI\input"
COMFYUI_OUTPUT = r"C:\Users\D\Documents\ComfyUI\output"

CHARACTERS = ["elena", "maya", "vanessa"]
TIERS = list(range(0, 11))

def upload_image(image_path):
    """Upload image to ComfyUI input directory."""
    filename = os.path.basename(image_path)
    dest = os.path.join(COMFYUI_INPUT, filename)
    shutil.copy2(image_path, dest)
    return filename

def build_remove_bg_workflow(image_filename, output_prefix):
    """Build ComfyUI workflow for background removal."""
    workflow = {
        "1": {
            "class_type": "LoadImage",
            "inputs": {
                "image": image_filename
            }
        },
        "2": {
            "class_type": "easy imageRemBg",
            "inputs": {
                "add_background": "none",
                "image_output": "Save",
                "images": ["1", 0],
                "refine_foreground": False,
                "rem_mode": "RMBG-1.4",
                "save_prefix": output_prefix
            }
        }
    }
    return workflow

def enqueue_workflow(workflow):
    """Submit workflow to ComfyUI."""
    data = json.dumps({
        "prompt": workflow,
        "client_id": "tier_bg_remover"
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

def wait_for_completion(prompt_id, timeout=120):
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
        time.sleep(2)
    print(f"  Timeout after {timeout}s")
    return False

def find_output_file(prefix):
    """Find the output file in ComfyUI output directory."""
    try:
        files = [f for f in os.listdir(COMFYUI_OUTPUT) 
                if f.startswith(prefix) and f.endswith('.png')]
        if files:
            # Return the most recent file
            files.sort(key=lambda f: os.path.getmtime(os.path.join(COMFYUI_OUTPUT, f)), reverse=True)
            return files[0]
    except Exception:
        pass
    return None

def main():
    total = len(CHARACTERS) * len(TIERS)
    processed = 0
    skipped = 0
    success_count = 0
    
    print(f"Processing {total} tier images for background removal...\n")
    
    for char_id in CHARACTERS:
        char_dir = os.path.join(TIER_DIR, char_id)
        if not os.path.exists(char_dir):
            print(f"Skipping {char_id} - directory not found")
            continue
        
        for tier in TIERS:
            tier_file = f"{char_id}_tier_{tier}.png"
            tier_path = os.path.join(char_dir, tier_file)
            
            if not os.path.exists(tier_path):
                print(f"  Skipping {tier_file} - file not found")
                skipped += 1
                continue
            
            processed += 1
            print(f"  [{processed}/{total}] Processing {tier_file}...")
            
            # Upload to ComfyUI input
            input_filename = upload_image(tier_path)
            
            # Build and enqueue workflow with unique prefix
            output_prefix = f"nobg_{char_id}_tier_{tier}"
            workflow = build_remove_bg_workflow(input_filename, output_prefix)
            prompt_id = enqueue_workflow(workflow)
            
            if not prompt_id:
                print(f"    Failed to enqueue workflow")
                continue
            
            # Wait for completion
            success = wait_for_completion(prompt_id)
            if not success:
                print(f"    Workflow failed or timed out")
                continue
            
            # Find output file
            output_file = find_output_file(output_prefix)
            
            if output_file:
                src = os.path.join(COMFYUI_OUTPUT, output_file)
                dst = os.path.join(char_dir, tier_file)
                shutil.copy2(src, dst)
                print(f"    [OK] Background removed")
                success_count += 1
                
                # Clean up output file
                try:
                    os.remove(src)
                except Exception:
                    pass
            else:
                print(f"    [FAIL] Output file not found (prefix: {output_prefix})")
                # List files to debug
                try:
                    all_files = [f for f in os.listdir(COMFYUI_OUTPUT) if f.endswith('.png')]
                    print(f"    Available files: {all_files[:5]}")
                except Exception:
                    pass
            
            time.sleep(0.5)
    
    print(f"\n=== Summary ===")
    print(f"  Processed: {processed}")
    print(f"  Success: {success_count}")
    print(f"  Skipped: {skipped}")
    print(f"  Total: {total}")

if __name__ == "__main__":
    main()
