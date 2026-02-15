#!/usr/bin/env python3
"""
Generate Arabic TTS MP3 assets used by TtsHelper local fallback.

Usage:
  python3 tool/generate_tts_assets.py
  python3 tool/generate_tts_assets.py --force
"""

from __future__ import annotations

import argparse
import asyncio
import re
from pathlib import Path

import edge_tts


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "voices" / "tts"
LIB_DIR = ROOT / "lib"

# Keep voice order; first one that works is used.
VOICE_CANDIDATES = [
    "ar-TN-ReemNeural",
    "ar-EG-SalmaNeural",
    "ar-SA-ZariyahNeural",
    "ar-TN-HediNeural",
]

ARABIC_RE = re.compile(r"[\u0600-\u06FF]")
FIELD_RE = re.compile(r"(?:'name'|'title'|word|label|letter)\s*:\s*'([^']+)'")
SUBIMAGE_RE = re.compile(r"'subImage'\s*:\s*'([^']+)'")
SPEAK_LITERAL_RE = re.compile(r"TtsHelper\.speak\([^,]+,\s*'([^']+)'\)")


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.replace("/", " أو ").replace("_", " ")).strip()


def text_key(text: str) -> str:
    # Must stay in sync with lib/services/tts_helper.dart::_textKey
    data = normalize_text(text).encode("utf-8")
    h = 0x811C9DC5
    for b in data:
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


def collect_texts() -> list[str]:
    collected: set[str] = set()
    source_files = sorted(LIB_DIR.rglob("*.dart"))
    for path in source_files:
        if not path.exists():
            continue
        content = path.read_text(encoding="utf-8")

        for m in FIELD_RE.finditer(content):
            value = normalize_text(m.group(1))
            if value and ARABIC_RE.search(value):
                collected.add(value)

        for m in SUBIMAGE_RE.finditer(content):
            stem = Path(m.group(1)).stem
            value = normalize_text(stem)
            if value and ARABIC_RE.search(value):
                collected.add(value)

        for m in SPEAK_LITERAL_RE.finditer(content):
            value = normalize_text(m.group(1))
            if value and ARABIC_RE.search(value):
                collected.add(value)

    return sorted(collected)


async def synthesize_one(text: str, output_path: Path) -> str:
    last_error: Exception | None = None
    for voice in VOICE_CANDIDATES:
        try:
            communicate = edge_tts.Communicate(text=text, voice=voice, rate="-10%")
            await communicate.save(str(output_path))
            return voice
        except Exception as exc:  # pragma: no cover
            last_error = exc
            continue
    raise RuntimeError(f"Failed to synthesize '{text}': {last_error}")


async def generate(force: bool) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    texts = collect_texts()
    if not texts:
        print("No Arabic texts found.")
        return

    generated = 0
    skipped = 0
    for text in texts:
        key = text_key(text)
        output = OUTPUT_DIR / f"{key}.mp3"
        if output.exists() and not force:
            skipped += 1
            continue

        voice = await synthesize_one(text, output)
        generated += 1
        print(f"[ok] {key}.mp3  <=  {text}  ({voice})")

    print(
        f"Done. texts={len(texts)} generated={generated} skipped={skipped} dir={OUTPUT_DIR}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="Regenerate all files")
    args = parser.parse_args()
    asyncio.run(generate(force=args.force))


if __name__ == "__main__":
    main()
