#!/usr/bin/env python3
"""Generate the original, deterministic Meowdoku feedback bank.

The sounds are intentionally short and dry so the paper/paw object animation
remains primary. No third-party samples or generated-model outputs are used.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/audio/logic"
RATE = 44_100


def envelope(time: float, attack: float, decay: float) -> float:
    if time < attack:
        return time / max(attack, 1e-6)
    return math.exp(-(time - attack) / decay)


def soft_clip(value: float) -> float:
    return math.tanh(value * 1.25) * 0.82


def write_sound(name: str, duration: float, sample: Callable[[float, random.Random], float]) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    rng = random.Random(f"offline-games:{name}:v1")
    frames = bytearray()
    for index in range(int(duration * RATE)):
        value = soft_clip(sample(index / RATE, rng))
        frames.extend(struct.pack("<h", int(max(-1.0, min(1.0, value)) * 32767)))
    with wave.open(str(OUTPUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(frames)


def paper_select(time: float, rng: random.Random) -> float:
    body = math.sin(math.tau * 430 * time) * envelope(time, 0.003, 0.045)
    click = rng.uniform(-1, 1) * math.exp(-time / 0.012)
    return body * 0.28 + click * 0.08


def ink_confirm(time: float, rng: random.Random) -> float:
    first = math.sin(math.tau * 610 * time) * envelope(time, 0.004, 0.075)
    second_time = max(0.0, time - 0.055)
    second = math.sin(math.tau * 820 * second_time) * envelope(second_time, 0.003, 0.095) if time >= 0.055 else 0.0
    texture = rng.uniform(-1, 1) * math.exp(-time / 0.026)
    return first * 0.20 + second * 0.24 + texture * 0.045


def correction_scratch(time: float, rng: random.Random) -> float:
    stroke = math.sin(math.tau * (135 + 90 * time) * time) * envelope(time, 0.002, 0.10)
    scratch = rng.uniform(-1, 1) * (0.75 + 0.25 * math.sin(math.tau * 31 * time)) * envelope(time, 0.002, 0.075)
    return stroke * 0.16 + scratch * 0.14


def block_stamp(time: float, rng: random.Random) -> float:
    thump = math.sin(math.tau * 155 * time) * envelope(time, 0.003, 0.09)
    overtone = math.sin(math.tau * 620 * time) * envelope(time, 0.006, 0.14)
    paper = rng.uniform(-1, 1) * math.exp(-time / 0.024)
    return thump * 0.32 + overtone * 0.17 + paper * 0.06


def folio_complete(time: float, rng: random.Random) -> float:
    value = 0.0
    for start, frequency in [(0.00, 523.25), (0.09, 659.25), (0.18, 783.99), (0.29, 1046.50)]:
        if time >= start:
            local = time - start
            value += math.sin(math.tau * frequency * local) * envelope(local, 0.006, 0.20) * 0.18
            value += math.sin(math.tau * frequency * 2.0 * local) * envelope(local, 0.004, 0.12) * 0.045
    value += rng.uniform(-1, 1) * math.exp(-time / 0.035) * 0.025
    return value


def main() -> None:
    write_sound("paper_select.wav", 0.14, paper_select)
    write_sound("ink_confirm.wav", 0.24, ink_confirm)
    write_sound("correction_scratch.wav", 0.24, correction_scratch)
    write_sound("block_stamp.wav", 0.32, block_stamp)
    write_sound("folio_complete.wav", 0.72, folio_complete)
    print(f"LOGIC_SFX_GENERATED={OUTPUT}")


if __name__ == "__main__":
    main()
