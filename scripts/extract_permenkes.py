#!/usr/bin/env python3
"""
Konversi tabel SD Permenkes 2/2020 (PDF lampiran) → assets/reference/permenkes_2_2020_sd.json

Sumber: .reference/permenkes_2_2020.pdf (BUKAN bagian data app; file tidak di-commit).
Tidak ada angka yang diketik manual — semuanya dibaca dari PDF.

Cara pakai:
    python scripts/extract_permenkes.py

Output diverifikasi ketat sebelum ditulis (lihat bagian VALIDASI).
"""
import json
import math
import re
import sys
from pypdf import PdfReader

PDF = r".reference/permenkes_2_2020.pdf"
OUT = r"assets/reference/permenkes_2_2020_sd.json"

# Halaman 16–42 memuat seluruh tabel SD yang dibutuhkan (1-based).
FIRST_PAGE, LAST_PAGE = 16, 42

# Tabel yang dibutuhkan → nama internal. Tabel IMT (6,7,8IMT boys / dst.) dilewati.
MARKER_TO_TABLE = {
    1: "waz_male",
    2: "haz_pb_male",
    3: "haz_tb_male",
    4: "whz_pb_male",
    5: "whz_tb_male",
    8: "waz_female",
    9: "haz_pb_female",
    10: "haz_tb_female",
    11: "whz_pb_female",
    12: "whz_tb_female",
    # 6, 7, 13, 14, 15, 16 = tabel IMT → tidak dipakai
}
MARKER_RE = re.compile(r"Tabel\s*(\d+)\s*\.")

NUM = r"-?\d+(?:\.\d+)?|-?\d+\."  # mencakup sel cacat seperti "6." (lihat bawah)

ROW_RE = re.compile(
    rf"^\s*(\d+(?:\.\d+)?)\s+({NUM})\s+({NUM})\s+({NUM})\s+({NUM})\s+({NUM})\s+({NUM})\s+({NUM})\s*$"
)


def parse_row(line: str):
    """Kembalikan (key, values) atau None. Sel yang tercetak tidak lengkap
    di PDF resmi (token berakhiran '.') dibaca sebagai None — BUKAN ditebak."""
    cleaned = line.replace("*", "").rstrip()
    m = ROW_RE.match(cleaned)
    if not m:
        return None
    key = float(m.group(1))
    values: list[float | None] = []
    for i in range(2, 9):
        token = m.group(i)
        if token.endswith("."):
            values.append(None)  # sel cacat di sumber — dilaporkan, tidak ditebak
        else:
            values.append(float(token))
    return key, values


def main() -> int:
    reader = PdfReader(PDF)
    current = None
    blocks: dict[str, list[tuple[float, list[float | None]]]] = {t: [] for t in MARKER_TO_TABLE.values()}
    source_lines: dict[str, list[tuple[int, str]]] = {t: [] for t in MARKER_TO_TABLE.values()}
    page_texts: dict[int, str] = {}

    def normalize(s: str) -> str:
        return " ".join(s.split())

    for p in range(FIRST_PAGE, LAST_PAGE + 1):
        text = reader.pages[p - 1].extract_text(extraction_mode="layout") or ""
        page_texts[p] = normalize(text)
        for raw in text.splitlines():
            marker = MARKER_RE.search(raw)
            if marker:
                current = MARKER_TO_TABLE.get(int(marker.group(1)))  # None → IMT / lain-lain
                continue
            row = parse_row(raw)
            if row and current:
                blocks[current].append(row)
                source_lines[current].append((p, raw))

    # ── VALIDASI ────────────────────────────────────────────────
    expected = {
        "waz_male": (61, 1.0, 0), "waz_female": (61, 1.0, 0),
        "haz_pb_male": (25, 1.0, 0), "haz_tb_male": (37, 1.0, 24),
        "haz_pb_female": (25, 1.0, 0), "haz_tb_female": (37, 1.0, 24),
        "whz_pb_male": (131, 0.5, 45.0), "whz_tb_male": (111, 0.5, 65.0),
        "whz_pb_female": (131, 0.5, 45.0), "whz_tb_female": (111, 0.5, 65.0),
    }
    ok = True

    print("== Row counts & key continuity ==")
    null_cells = []  # (table, key, col_index)
    for name, rows in blocks.items():
        n, step, start = expected[name]
        keys = [k for k, _ in rows]
        dup = len(keys) != len(set(keys))
        gaps = [round(keys[i + 1] - keys[i], 2) for i in range(len(keys) - 1)]
        continuous = all(abs(g - step) < 1e-6 for g in gaps)
        starts_ok = abs(keys[0] - start) < 1e-6 if keys else False
        for k, v in rows:
            for ci, cell in enumerate(v):
                if cell is None:
                    null_cells.append((name, k, ci))
        status = "OK" if (len(rows) == n and not dup and continuous and starts_ok) else "FAIL"
        if status == "FAIL":
            ok = False
        print(f"{name:16s} rows={len(rows):4d} (expect {n}) dup={dup} continuous={continuous} starts={keys[0] if keys else None} [{status}]")
        if status == "FAIL":
            print("   keys:", keys)

    print()
    print("== Sel hilang (PDF resmi cacat) ==")
    if null_cells:
        for name, key, ci in null_cells:
            print(f"  {name} key={key} kolom#{ci} -> null (tercetak tidak lengkap di sumber)")
    else:
        print("  tidak ada")

    print()
    print("== Monotonicity (kolom SD naik; sel null dilewati) ==")
    col_names = ["sdNeg3", "sdNeg2", "sdNeg1", "median", "sdPos1", "sdPos2", "sdPos3"]
    for name, rows in blocks.items():
        mono_violations = 0
        for _, v in rows:
            seq = [c for c in v]
            for i in range(6):
                a, b = seq[i], seq[i + 1]
                if a is None or b is None:
                    continue
                if not a < b:
                    mono_violations += 1
                    break
        if mono_violations:
            ok = False
        print(f"{name:16s} mono_violations={mono_violations}")

    print()
    print("== Verifikasi verbatim terhadap teks PDF ==")
    for name, entries in source_lines.items():
        missing = [raw for p, raw in entries if normalize(raw) not in page_texts[p]]
        if missing:
            ok = False
            print(f"{name:16s} FAIL — {len(missing)} baris tidak ditemukan verbatim di PDF")
            for raw in missing[:5]:
                print("     ", repr(raw))
        else:
            print(f"{name:16s} {len(entries)} baris persis ada di PDF")

    if not ok:
        print("\nVALIDASI GAGAL — JSON tidak ditulis.")
        return 1

    # ── TULIS JSON ───────────────────────────────────────────────
    def row_array(rows):
        return [values for _, values in rows]

    def step_meta(rows, step, start):
        return {"step": step, "start": start, "rows": row_array(rows)}

    doc = {
        "version": "permenkes-2-2020",
        "source": "Peraturan Menteri Kesehatan Republik Indonesia Nomor 2 Tahun 2020 tentang Standar Antropometri Anak (Lampiran, Tabel 1–12)",
        "extractedFrom": "Permenkes Nomor 2 Tahun 2020.pdf (tidak di-commit; lihat .reference/)",
        "extractedOn": "2026-11-11",
        "columnOrder": ["sdNeg3", "sdNeg2", "sdNeg1", "median", "sdPos1", "sdPos2", "sdPos3"],
        "notes": [
            "haz: pb_u (0-23/24 bulan, telentang) dipakai untuk umur < 24 bulan; tb_u (24-60 bulan, berdiri) untuk >= 24 bulan.",
            "whz: pb dipakai untuk 0-23 bulan; tb untuk 24-60 bulan. Panjang/tinggi dibulatkan ke step 0,5 (half-up) sesuai LengthHeightStep.",
            "Nilai apa adanya dari lampiran (1 desimal) — JANGAN diubah tanpa mencocokkan kembali ke PDF resmi.",
            "Girls haz pb_u memiliki baris 24* (telentang) — usia 24 default memakai tb_u (berdiri) per PRD 3.2.",
            "SEL CACAT di PDF resmi: whz_tb_female baris 69.5, kolom sdNeg3 tercetak \"6.\" -> null. SUDAH diverifikasi manual di PDF (bukan salah ekstrak). Kolom sdNeg3 tidak dipakai rumus PRD §3.3. Wajib ditinjau pemilik sebelum rilis (PRD §13).",
        ],
        "tables": {
            "haz": {
                "male": {"pb_u": row_array(blocks["haz_pb_male"]), "tb_u": row_array(blocks["haz_tb_male"])},
                "female": {"pb_u": row_array(blocks["haz_pb_female"]), "tb_u": row_array(blocks["haz_tb_female"])},
            },
            "waz": {
                "male": row_array(blocks["waz_male"]),
                "female": row_array(blocks["waz_female"]),
            },
            "whz": {
                "male": {
                    "pb": step_meta(blocks["whz_pb_male"], 0.5, 45.0),
                    "tb": step_meta(blocks["whz_tb_male"], 0.5, 65.0),
                },
                "female": {
                    "pb": step_meta(blocks["whz_pb_female"], 0.5, 45.0),
                    "tb": step_meta(blocks["whz_tb_female"], 0.5, 65.0),
                },
            },
        },
    }

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)
    print(f"\nOK — ditulis: {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
