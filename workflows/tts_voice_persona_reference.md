# TTS Voice Persona Reference

## Character Voice Instructions for Qwen3-TTS

### Elena (Stepmom)
```
A warm, mature adult female voice (mid-30s to early 40s). Pitch is medium-low with a soft, nurturing quality. Speaks at a moderate pace with gentle, caring intonation. Tone is welcoming, slightly shy when flustered, and naturally maternal. Has a breathy warmth that suggests femininity and caring nature. Sounds like a loving homemaker who is devoted to her family. When embarrassed, voice becomes slightly higher and softer. When scolding, firm but never harsh.
```

### Maya (Stepsis)
```
A bratty, energetic young adult female voice (19-21 years old). Pitch is medium-high with noticeable upward inflections at sentence ends. Speaks quickly with playful sassiness. Tone is bold, teasing, and slightly flirtatious. Uses vocal fry occasionally for emphasis. Sounds confident and mischievous, like a college-aged girl who knows she's attractive and uses it. Not childish — clearly an adult woman, just young and spirited.
```

### Vanessa (Aunt)
```
A confident, sophisticated adult female voice (late 30s to early 40s). Pitch is medium with a rich, slightly husky quality. Speaks deliberately with controlled, self-assured intonation. Tone is bold, direct, and subtly flirtatious without being overt. Has a worldly, experienced sound — like a woman who is comfortable in her own skin and knows how to command a room. Slightly lower register than average female voice, with a smooth, velvety texture. Projects confidence and quiet dominance.
```

## Story Dialogue Lines by Character

### Maya (line indices: 0, 1, 5, 8, 12, 14, 17, 19, 20, 21, 23, 32)
0: "Oh my god, he's actually here! The exchange student from overseas!"
1: "Mom said he's studying at the university for a whole semester. That's like... three months of living under our roof~"
5: "Oh, we'll make an impression alright. I've already planned his entire welcome tour~"
8: "Relax, Mom! I'm just being hospitable. Besides, look at his photo — he's totally cute!"
12: "And I'm Maya! Well, technically your host sister, but you can call me whatever you want~"
14: "What? I am being proper! I'm just excited we finally have someone interesting in this house."
17: "Oh, I KNEW you'd pick me! This is going to be the best semester ever."
19: "Settle in later! Right now I need to show him the BEST spots in town. The university is boring — the real education happens outside campus~"
20: "Orientation is just boring paperwork. I'll give him the REAL introduction to this city."
21: "Don't worry, I'll even let you pick the music in my car. That's how generous I am."
23: "Booooring. Come on, let's do something fun!"
32: "Aunt Vanessa! When did you get here?!"

### Elena (line indices: 2, 3, 4, 6, 7, 9, 10, 11, 13, 15, 16, 18, 22, 24, 25, 26, 33)
2: "Maya! Stop hovering by the window like a hawk. He hasn't even rung the bell yet!"
3: "I just hope I made enough food. International students must be so hungry after such a long flight..."
4: "Your father and I agreed to host him to help with his university adjustment. We need to make a good impression."
6: "Maya. No 'tours.' He's here to study, not to be your personal tourist guide."
7: "MAYA. That is completely inappropriate. He's a guest in our home."
9: "Welcome! You must be exhausted from your flight. I'm Elena — your host mother."
10: "I've prepared dinner and your room is all ready. Please, make yourself at home. This is your home now, for as long as you're here."
11: "Maya! Introduce yourself properly!"
13: "W-Wait, already? Maya, give him time to settle in..."
15: "MAYA! He has orientation tomorrow!"
16: "Oh... that's very sweet of you. Thank you."
18: "I-I made a full dinner already. Traditional dishes from our country, but I also looked up some recipes from yours..."
22: "I know moving abroad for university is overwhelming. Your parents must be so proud of you."
24: "My husband travels constantly for work, so it'll mostly be the three of us. I promise I'll help you adjust to everything — the university, the city, the culture..."
25: "Vanessa! I didn't even hear you come in..."
33: (No Elena lines after converge)

### Vanessa (line indices: 27, 28, 29, 30, 31, 34)
27: "Well, well. So you're the famous exchange student."
28: "I have my own key, remember? And I couldn't resist meeting the handsome young man everyone's been talking about."
29: "Elena's sister, by the way. Vanessa. I live just down the street... close enough to drop by whenever I feel like it."
30: "Relax. I'm not here to interrogate you. I just wanted to see what kind of person my sister decided to invite into her home."
31: "And I have to say... Elena has excellent taste. You'll fit right in."
34: "I'll be around more often than you'd expect. This semester should be... interesting."

## Generation Workflow

1. **Voice Design**: Generate reference voice for each character using `Qwen3TTSVoiceDesign`
   - Input: voice_instruction + sample text
   - Output: `tts_{char}_voice_design_*.mp3`

2. **Voice Clone**: For each dialogue line, use `Qwen3TTSVoiceClone`
   - Input: model + ref_audio (voice design) + ref_text + target_text + instruct
   - Output: `tts_{char}_{line_index}.mp3`

3. **Settings for consistency**:
   - seed: 42 (fixed for consistency)
   - temperature: 0.9
   - top_p: 1.0
   - top_k: 50
   - repetition_penalty: 1.05
   - max_new_tokens: 2048
