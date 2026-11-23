#!/usr/bin/env python3
"""Optimalkan foto resep menjadi aset Flutter yang ringan dan bernama standar.

Sumber   : ``assets/recipes/recipes_image/<rentang>/<nama bebas>.jpg``
           (arsip kerja, TIDAK dibundel ke APK dan tidak masuk git).
Keluaran : ``assets/recipes/images/<id-resep>.jpg``
           (dibundel ke APK, nama = ``id`` di ``recipes.json``).

Konvensi nama keluaran sengaja memakai ``id`` resep supaya aplikasi tidak
perlu menebak nama berkas (lihat ``RecipeImage.assetFor`` di sisi Flutter).

Jalankan dari akar repo::

    python tool/optimize_recipe_images.py

Butuh Pillow (perkakas dev saja - bukan dependency Flutter).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "recipes" / "recipes_image"
OUTPUT_DIR = ROOT / "assets" / "recipes" / "images"
RECIPES_JSON = ROOT / "assets" / "recipes" / "recipes.json"

# 1280 px cukup tajam untuk hero 390dp @3x (1170 px), tetapi tetap ringan.
MAX_WIDTH = 1280
JPEG_QUALITY = 82
MAX_BYTES = 300 * 1024

# Nama sumber dinormalisasi (huruf kecil, semua pemisah -> satu spasi) supaya
# garis bawah, spasi ganda, koma, dan spasi sebelum ekstensi tidak membuat
# pemetaan rapuh. Nilai = id resep di recipes.json.
NAME_TO_ID = {
    # 6-8 bulan
    "bubur saring hati ayam dan wortel": "bubur-saring-hati-ayam-wortel",
    "bubur saring ikan kembung dan bayam": "bubur-saring-ikan-kembung-bayam",
    "pure tempe labu kuning dan beras": "puree-tempe-labu-kuning-beras",
    "bubur ubijalar telur dan wortel": "bubur-ubi-jalar-telur-wortel",
    "pure tahu brokoli dan kentang": "puree-tahu-brokoli-kentang",
    "pure ayam kentang labu siam": "puree-ayam-kentang-labu-siam",
    # 9-11 bulan
    "nasi tim daging sapi wortel dan buncis": "nasi-tim-sapi-wortel-buncis",
    "bubur beras kacang hijau dan pisang": "bubur-beras-kacang-hijau-pisang",
    "nasi tim telur orak arik dan bayam": "nasi-tim-telur-orak-arik-bayam",
    "nasi tim ikan nila tomat dan labu siam": "nasi-tim-ikan-nila-tomat-labu-siam",
    "nasi tim hati ayam tahu dan wortel": "nasi-tim-hati-ayam-tahu-wortel",
    "bubur oat pisang dan yogurt plain": "bubur-oat-pisang-yogurt-plain",
    # 12-23 bulan
    "perkedel ayam dan tahu panggang": "perkedel-ayam-tahu-panggang",
    "omelet gulung nasi wortel dan bayam": "omelet-gulung-nasi-wortel-bayam",
    "nugget ikan kembung dan brokoli panggang": "nugget-ikan-kembung-brokoli-panggang",
    "bola nasi tempe dan labu kuning": "bola-nasi-tempe-labu-kuning",
    "sup ayam sayur dengan nasi lembut": "sup-ayam-sayur-nasi-lembut",
    "pancake pisang telur dan oat dengan dip yogurt": "pancake-pisang-telur-oat-dip-yogurt",
    # 24+ bulan
    "pepes ikan kembung dengan sayur bening bayam dan nasi": "pepes-ikan-kembung-sayur-bening-bayam",
    "ayam bumbu kuning kentang dan wortel": "ayam-bumbu-kuning-kentang-wortel",
    "tumis tempe tahu dan sayuran dengan nasi": "tumis-tempe-tahu-sayuran-nasi",
    "soto ayam bening dengan telur dan nasi": "soto-ayam-bening-telur-nasi",
    "gado gado mini bumbu kacang ringan": "gado-gado-mini-bumbu-kacang-ringan",
    "sup daging sapi kentang wortel dan buncis": "sup-daging-sapi-kentang-wortel-buncis",
}


def normalize(stem: str) -> str:
    """Normalisasi nama berkas: huruf kecil, semua pemisah jadi satu spasi."""
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", stem.lower())).strip()


def main() -> int:
    if not RECIPES_JSON.exists():
        print(f"recipes.json tidak ditemukan: {RECIPES_JSON}")
        return 1
    if not SOURCE_DIR.exists():
        print(f"Folder foto sumber tidak ditemukan: {SOURCE_DIR}")
        return 1

    recipes = json.loads(RECIPES_JSON.read_text(encoding="utf-8"))
    known_ids = {item["id"] for item in recipes}

    missing = sorted(known_ids - set(NAME_TO_ID.values()))
    unknown = sorted(set(NAME_TO_ID.values()) - known_ids)
    if missing or unknown:
        if missing:
            print("Resep tanpa foto sumber:", ", ".join(missing))
        if unknown:
            print("Pemetaan menunjuk id yang tidak ada:", ", ".join(unknown))
        return 1

    sources: dict[str, Path] = {}
    for path in SOURCE_DIR.rglob("*.jpg"):
        key = normalize(path.stem)
        if key in sources:
            print(f"Nama sumber ambigu: {path.name} vs {sources[key].name}")
            return 1
        sources[key] = path

    unmapped = sorted(set(sources) - set(NAME_TO_ID))
    if unmapped:
        print("Berkas sumber tanpa pemetaan:")
        for key in unmapped:
            print(f"  - {sources[key].relative_to(ROOT)}")
        return 1

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    total = 0
    oversized: list[str] = []
    for name, recipe_id in sorted(NAME_TO_ID.items()):
        source = sources[name]
        with Image.open(source) as image:
            image = image.convert("RGB")
            if image.width > MAX_WIDTH:
                height = round(image.height * MAX_WIDTH / image.width)
                image = image.resize((MAX_WIDTH, height), Image.LANCZOS)
            target = OUTPUT_DIR / f"{recipe_id}.jpg"
            # EXIF (termasuk GPS) tidak ikut tersimpan.
            image.save(
                target,
                "JPEG",
                quality=JPEG_QUALITY,
                optimize=True,
                progressive=True,
            )
        size = target.stat().st_size
        total += size
        if size > MAX_BYTES:
            oversized.append(target.name)
        print(f"{size / 1024:7.1f} KB  {target.name}")

    print(
        f"\n{len(NAME_TO_ID)} foto, total {total / 1024 / 1024:.2f} MB "
        f"-> {OUTPUT_DIR.relative_to(ROOT)}"
    )
    if oversized:
        print("Melebihi batas 300 KB:", ", ".join(oversized))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
