"""Generate the game's original swing loop and cartoon effects. Requires numpy."""
from pathlib import Path
import math
import wave
import numpy as np

OUT = Path(__file__).resolve().parents[1] / "game/assets/audio"
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
rng = np.random.default_rng(1929)


def save(name, samples):
    samples = np.tanh(samples * 1.1)
    with wave.open(str(OUT / (name + ".wav")), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((samples * 24000).astype("<i2").tobytes())


def tone(freq, duration, kind="piano"):
    t = np.arange(int(duration * RATE)) / RATE
    if kind == "bass":
        sound = np.sin(2 * np.pi * freq * t) + .3 * np.sin(4 * np.pi * freq * t)
        envelope = np.minimum(1, t / .008) * np.exp(-t * 9)
    elif kind == "reed":
        sound = sum(np.sin(2 * np.pi * freq * (1 + .002 * np.sin(t * 32)) * t * k) / k**1.7 for k in [1, 2, 3, 5])
        envelope = np.minimum(1, t / .025) * np.minimum(1, (duration - t) / .08)
    else:
        sound = sum(np.cos(2 * np.pi * freq * k * t) / k**2 for k in range(1, 5))
        envelope = np.minimum(1, t / .004) * np.exp(-t * 7) * np.minimum(1, (duration - t) / .03)
    return sound * envelope


def midi(n):
    return 440 * 2 ** ((n - 69) / 12)


beat = 60 / 116
length = 32 * beat
song = np.zeros(int(length * RATE))


def mix(samples, at, gain):
    start = int(at * RATE)
    end = min(len(song), start + len(samples))
    song[start:end] += samples[:end-start] * gain


# A jaunty eight-bar C / A7 / Dm / G7 progression, with swung eighths.
chords = [[60, 64, 67], [60, 64, 69], [62, 65, 69], [59, 62, 67],
          [60, 64, 67], [61, 64, 69], [62, 65, 69], [59, 62, 67]]
basses = [[36, 43, 40, 43], [33, 40, 37, 40], [38, 45, 41, 45], [31, 38, 35, 38]]
melody = [[76, 79, 81, 79, 76, 74], [73, 76, 79, 81, 79, 76],
          [77, 81, 84, 81, 77, 74], [74, 77, 79, 77, 74, 71],
          [76, 79, 84, 83, 81, 79], [76, 73, 69, 73, 76, 79],
          [77, 81, 79, 77, 76, 74], [71, 74, 77, 79, 74, 72]]
for bar in range(8):
    base = bar * 4 * beat
    for pulse in range(4):
        mix(tone(midi(basses[bar % 4][pulse]), .42, "bass"), base + pulse * beat, .21)
        if pulse in (1, 3):
            for note in chords[bar]:
                mix(tone(midi(note), .24), base + pulse * beat, .075)
        # Soft brush and hi-hat, with a muted kick on the downbeat.
        t = np.arange(int(.11 * RATE)) / RATE
        brush = rng.normal(0, 1, len(t)) * np.exp(-t * 65)
        brush = np.concatenate([[0], np.diff(brush)])
        mix(brush, base + pulse * beat, .025 if pulse % 2 == 0 else .05)
        if pulse % 2 == 0:
            kick = np.sin(2 * np.pi * (65*t - 18*t*t)) * np.exp(-t * 34)
            mix(kick, base + pulse * beat, .12)
    for note, offset in zip(melody[bar], [0, 2/3, 1, 1+2/3, 2.5, 3+2/3]):
        mix(tone(midi(note), .23, "reed"), base + offset * beat, .14)
save("breakfast_swing", song)

for name, duration, f0, f1 in [("shoot", .075, 1000, 360), ("jump", .18, 280, 850),
                             ("dash", .16, 550, 100), ("hit", .23, 210, 55),
                             ("parry", .33, 650, 1600), ("pop", .16, 120, 500),
                             ("super", .55, 180, 1100)]:
    t = np.arange(int(duration * RATE)) / RATE
    phase = 2 * np.pi * (f0 * t + (f1 - f0) / (2 * duration) * t*t)
    env = np.sin(np.pi * t / duration) ** .65
    signal = np.sin(phase) * env * .4
    if name in ("hit", "dash", "super"):
        signal += rng.normal(0, .09, len(t)) * env
    save(name, signal)
win = np.zeros(int(1.4 * RATE))
for index, note in enumerate([72, 76, 79, 84]):
    samples = tone(midi(note), .65, "reed")
    start = int(index * .17 * RATE)
    win[start:start+len(samples)] += samples * .26
save("win", win)
print("Created original swing music and eight effects in", OUT)
