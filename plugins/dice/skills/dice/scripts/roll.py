#!/usr/bin/env python3
"""Shared dice roller for Claude command and Codex skill adapters."""

import random
import re
import sys


def parse_choices(text):
    text = text.strip()
    if not text:
        return []
    if "," in text or "\n" in text:
        return [part.strip() for part in re.split(r"[,\n]+", text) if part.strip()]
    return text.split()


def roll(text):
    text = text.strip()
    if not text:
        return str(random.randint(1, 6))
    if re.fullmatch(r"[1-9][0-9]*", text):
        return str(random.randint(1, int(text)))
    choices = parse_choices(text)
    if not choices:
        return str(random.randint(1, 6))
    return random.choice(choices)


def main():
    text = " ".join(sys.argv[1:])
    print(f"🎲 {roll(text)}")


if __name__ == "__main__":
    main()
