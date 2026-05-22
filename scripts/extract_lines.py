import json

with open('C:/Users/D/Documents/sigma-date/data/story.json', 'r', encoding='utf-8') as f:
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

by_char = {}
for line in lines:
    c = line['char']
    if c not in by_char:
        by_char[c] = []
    by_char[c].append(line)

for char_id, char_lines in sorted(by_char.items()):
    print(f'\n=== {char_id} ({len(char_lines)} lines) ===')
    for line in char_lines:
        text = line['text'][:80]
        print(f'  {line["index"]}: {text}')
