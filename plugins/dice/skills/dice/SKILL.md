---
name: dice
description: This skill should be used when the user wants to roll dice, randomly choose between options, decide quickly without analysis, use "dice", "주사위", "골라줘", "랜덤", or asks for a lightweight arbitrary choice.
version: 0.1.0
---

# Dice

Use the shared roller script for quick arbitrary choices.

## Behavior

Run `../../scripts/roll.py` from this skill directory, passing the user's option text as arguments.

- No arguments: roll 1-6.
- One positive integer `N`: roll 1-N.
- Multiple words: choose one item.
- Comma-separated text: choose one comma-delimited item.

## Output

Return only the script output. Do not add analysis, pros/cons, or follow-up explanation.

## Examples

```bash
python3 ../../scripts/roll.py
python3 ../../scripts/roll.py 20
python3 ../../scripts/roll.py pizza chicken burger
python3 ../../scripts/roll.py "pizza, chicken, burger"
```
