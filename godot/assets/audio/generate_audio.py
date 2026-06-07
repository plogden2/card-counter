#!/usr/bin/env python3
"""Generate cozy life-sim BGM and SFX (Animal Crossing / Stardew-inspired) as OGG."""
from __future__ import annotations

import json
import math
import os
import struct
import subprocess
import wave
from pathlib import Path

import numpy as np

SAMPLE_RATE = 44100
OUT_DIR = Path(__file__).resolve().parent
FFMPEG = os.environ.get(
    "FFMPEG",
    r"C:\Users\gener\AppData\Local\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe",
)


def _find_ffmpeg() -> str:
    if Path(FFMPEG).exists():
        return FFMPEG
    import shutil

    found = shutil.which("ffmpeg")
    if found:
        return found
    raise FileNotFoundError("ffmpeg not found — install via winget Gyan.FFmpeg")


def _write_wav(path: Path, samples: np.ndarray) -> None:
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm.tobytes())


def _to_ogg(wav_path: Path, ogg_path: Path) -> None:
    ffmpeg = _find_ffmpeg()
    subprocess.run(
        [
            ffmpeg,
            "-y",
            "-i",
            str(wav_path),
            "-c:a",
            "libvorbis",
            "-q:a",
            "5",
            str(ogg_path),
        ],
        check=True,
        capture_output=True,
    )
    wav_path.unlink(missing_ok=True)


def _save_ogg(name: str, samples: np.ndarray, subdir: str = "sfx") -> Path:
    wav = OUT_DIR / "_tmp" / f"{name}.wav"
    wav.parent.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / subdir / f"{name}.ogg"
    out.parent.mkdir(parents=True, exist_ok=True)
    _write_wav(wav, samples)
    _to_ogg(wav, out)
    return out


def _t(length_sec: float) -> np.ndarray:
    return np.linspace(0, length_sec, int(SAMPLE_RATE * length_sec), endpoint=False)


def _adsr(
    length: int,
    attack: float = 0.01,
    decay: float = 0.05,
    sustain: float = 0.6,
    release: float = 0.12,
) -> np.ndarray:
    if length <= 0:
        return np.array([])
    env = np.zeros(length)
    a = min(int(attack * SAMPLE_RATE), length)
    d = min(int(decay * SAMPLE_RATE), max(0, length - a))
    r = min(int(release * SAMPLE_RATE), max(0, length - a - d))
    idx = 0
    if a > 0:
        env[idx : idx + a] = np.linspace(0, 1, a)
        idx += a
    if d > 0:
        env[idx : idx + d] = np.linspace(1, sustain, d)
        idx += d
    s = max(0, length - idx - r)
    if s > 0:
        env[idx : idx + s] = sustain
        idx += s
    if r > 0 and idx < length:
        env[idx:] = np.linspace(sustain, 0, length - idx)
    return env


def _tone(freq: float, dur: float, vol: float = 0.3, wave_type: str = "sine") -> np.ndarray:
    t = _t(dur)
    if wave_type == "sine":
        sig = np.sin(2 * math.pi * freq * t)
    elif wave_type == "triangle":
        sig = 2 * np.abs(2 * (freq * t - np.floor(freq * t + 0.5))) - 1
    else:
        sig = np.sign(np.sin(2 * math.pi * freq * t))
    env = _adsr(len(sig), attack=0.005, decay=0.08, sustain=0.4, release=0.15)
    return sig * env * vol


def _marimba(freq: float, dur: float, vol: float = 0.25) -> np.ndarray:
    t = _t(dur)
    sig = (
        np.sin(2 * math.pi * freq * t) * 0.7
        + np.sin(2 * math.pi * freq * 2.0 * t) * 0.2
        + np.sin(2 * math.pi * freq * 3.5 * t) * 0.08
    )
    env = _adsr(len(sig), 0.002, 0.12, 0.15, 0.2)
    return sig * env * vol


def _noise_burst(dur: float, vol: float = 0.15, hp: float = 0.0) -> np.ndarray:
    n = int(SAMPLE_RATE * dur)
    sig = np.random.uniform(-1, 1, n)
    if hp > 0:
        sig = sig - np.roll(sig, 1) * hp
    env = _adsr(n, 0.001, 0.02, 0.3, 0.08)
    return sig * env * vol


def _mix(*tracks: np.ndarray) -> np.ndarray:
    max_len = max(len(t) for t in tracks)
    out = np.zeros(max_len)
    for tr in tracks:
        out[: len(tr)] += tr
    peak = np.max(np.abs(out)) or 1.0
    return out / max(peak, 1.0) * 0.85


def gen_bgm() -> np.ndarray:
    """Soft looping village evening — pentatonic marimba + pad."""
    bpm = 88
    beat = 60.0 / bpm
    bars = 8
    length = bars * 4 * beat
    t = _t(length)
    out = np.zeros(len(t))

    # Pad (warm synth)
    pad_freqs = [110.0, 164.81, 196.0]
    for f in pad_freqs:
        out += np.sin(2 * math.pi * f * t) * 0.04
        out += np.sin(2 * math.pi * f * 1.01 * t) * 0.02
    pad_env = 0.5 + 0.5 * np.sin(2 * math.pi * t / length)
    out *= pad_env

    # Melody — C major pentatonic
    notes = [261.63, 293.66, 329.63, 392.0, 440.0, 392.0, 329.63, 293.66]
    step = beat
    for i, freq in enumerate(notes * 4):
        start = int(i * step * SAMPLE_RATE)
        note = _marimba(freq, beat * 0.9, 0.18)
        end = min(start + len(note), len(out))
        out[start:end] += note[: end - start]

    # Light shaker percussion
    for i in range(int(length / (beat / 2))):
        start = int(i * (beat / 2) * SAMPLE_RATE)
        if i % 2 == 0:
            tick = _noise_burst(0.03, 0.06)
            end = min(start + len(tick), len(out))
            out[start:end] += tick[: end - start]

    # Seamless loop crossfade tail
    fade = int(0.5 * SAMPLE_RATE)
    if fade < len(out):
        out[-fade:] *= np.linspace(1, 0.85, fade)
        out[:fade] += out[-fade:] * np.linspace(0.15, 0, fade)

    return _mix(out)


def gen_bet() -> np.ndarray:
    return _mix(_tone(880, 0.06, 0.2), _tone(1320, 0.04, 0.12), _noise_burst(0.05, 0.08))


def gen_deal() -> np.ndarray:
    return _mix(_noise_burst(0.08, 0.2), _tone(420, 0.05, 0.15, "triangle"))


def gen_hit() -> np.ndarray:
    return _mix(_noise_burst(0.06, 0.18), _tone(520, 0.04, 0.1))


def gen_stand() -> np.ndarray:
    return _marimba(392.0, 0.12, 0.22)


def gen_double() -> np.ndarray:
    return _mix(gen_bet(), gen_deal()[: int(0.08 * SAMPLE_RATE)])


def gen_split() -> np.ndarray:
    d = gen_deal()
    gap = int(0.04 * SAMPLE_RATE)
    return _mix(d, np.pad(d[: int(0.06 * SAMPLE_RATE)], (gap, 0)))


def gen_insurance_yes() -> np.ndarray:
    return _mix(_marimba(523.25, 0.1, 0.2), _marimba(659.25, 0.12, 0.18))


def gen_insurance_no() -> np.ndarray:
    return _mix(_marimba(392.0, 0.1, 0.18), _tone(311.13, 0.15, 0.12))


def gen_win() -> np.ndarray:
    freqs = [523.25, 659.25, 783.99, 1046.5]
    parts = []
    for i, f in enumerate(freqs):
        parts.append(np.pad(_marimba(f, 0.2, 0.2), (int(i * 0.06 * SAMPLE_RATE), 0)))
    return _mix(*parts)


def gen_lose() -> np.ndarray:
    return _mix(
        _tone(349.23, 0.2, 0.15),
        np.pad(_tone(293.66, 0.25, 0.12), (int(0.1 * SAMPLE_RATE), 0)),
    )


def gen_push() -> np.ndarray:
    return _marimba(440.0, 0.14, 0.16)


def gen_blackjack() -> np.ndarray:
    freqs = [659.25, 783.99, 987.77, 1174.66]
    parts = [_marimba(f, 0.18, 0.22) for f in freqs]
    spaced = [np.pad(p, (int(i * 0.05 * SAMPLE_RATE), 0)) for i, p in enumerate(parts)]
    return _mix(*spaced)


def gen_shuffle() -> np.ndarray:
    parts = [_noise_burst(0.04, 0.12) for _ in range(8)]
    out = np.array([])
    gap = int(0.035 * SAMPLE_RATE)
    for p in parts:
        out = np.concatenate([out, p, np.zeros(gap)])
    return out * 0.9


def gen_chip() -> np.ndarray:
    return _mix(_tone(1200, 0.05, 0.25), _tone(1800, 0.03, 0.15), _noise_burst(0.04, 0.06))


def gen_ui_confirm() -> np.ndarray:
    return _mix(_marimba(587.33, 0.08, 0.25), _tone(880, 0.05, 0.1))


SFX_BUILDERS = {
    "bet_confirm": gen_bet,
    "deal": gen_deal,
    "hit": gen_hit,
    "stand": gen_stand,
    "double": gen_double,
    "split": gen_split,
    "insurance_yes": gen_insurance_yes,
    "insurance_no": gen_insurance_no,
    "win": gen_win,
    "lose": gen_lose,
    "push": gen_push,
    "blackjack": gen_blackjack,
    "shuffle": gen_shuffle,
    "chip": gen_chip,
    "ui_confirm": gen_ui_confirm,
}


def main() -> None:
    np.random.seed(42)
    manifest = {"generated": [], "sample_rate": SAMPLE_RATE, "style": "cozy-life-sim"}
    print("Generating BGM...")
    bgm_path = _save_ogg("table_loop", gen_bgm(), "bgm")
    manifest["generated"].append(str(bgm_path.relative_to(OUT_DIR.parent.parent)))

    for name, builder in SFX_BUILDERS.items():
        print(f"  SFX: {name}")
        path = _save_ogg(name, builder())
        manifest["generated"].append(str(path.relative_to(OUT_DIR.parent.parent)))

    meta = OUT_DIR / "audio_manifest.json"
    meta.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    tmp = OUT_DIR / "_tmp"
    if tmp.exists():
        for f in tmp.glob("*"):
            f.unlink()
        tmp.rmdir()
    print(f"Done — {len(manifest['generated'])} OGG files written.")


if __name__ == "__main__":
    main()
