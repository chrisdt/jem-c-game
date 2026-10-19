"""Generate Buddy's original, short cartoon double bark (optional authoring tool)."""
from pathlib import Path
import wave

import numpy as np
from scipy import signal


def bark(duration, pitch, seed):
    rate = 44100
    t = np.arange(round(duration * rate)) / rate
    rng = np.random.default_rng(seed)
    frequency = pitch * (0.58 + 0.42 * np.exp(-t * 20))
    frequency *= 1 + 0.035 * np.sin(t * 2 * np.pi * 37)
    phase = np.cumsum(frequency) / rate
    voice = signal.sawtooth(2 * np.pi * phase, width=0.2)
    source = voice * 0.8 + rng.standard_normal(len(t)) * 0.3
    resonant = np.zeros_like(source)
    for centre, weight in [(580, 1.0), (1100, 0.55), (2350, 0.2)]:
        b, a = signal.iirpeak(centre, 2.2, fs=rate)
        resonant += signal.lfilter(b, a, source) * weight
    body = np.sin(2 * np.pi * phase) * 0.18
    attack = np.minimum(t / 0.009, 1) ** 2
    release = np.minimum((duration - t) / 0.05, 1) ** 2
    envelope = attack * release * np.exp(-t * 7)
    return np.tanh((resonant + body) * 1.8) * envelope


def main():
    rate = 44100
    samples = np.zeros(round(rate * 0.62))
    for start, duration, pitch, seed in [(0.035, 0.19, 205, 17), (0.31, 0.22, 185, 29)]:
        clip = bark(duration, pitch, seed)
        offset = round(start * rate)
        samples[offset:offset + len(clip)] += clip
    samples *= 0.72 / np.max(np.abs(samples))
    destination = Path(__file__).resolve().parents[1] / "assets/audio/buddy_bark.wav"
    destination.parent.mkdir(exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes((samples * 32767).astype("<i2").tobytes())
    print(f"Wrote {destination.name}: {len(samples) / rate:.2f}s, mono 44.1kHz")


if __name__ == "__main__":
    main()
