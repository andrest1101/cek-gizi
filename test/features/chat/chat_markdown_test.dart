import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/chat/presentation/widgets/chat_markdown.dart';

void main() {
  group('ChatMarkdownParser.parse', () {
    test('paragraf, tebal, dan bullet', () {
      final blocks = ChatMarkdownParser.parse(
        '**Coba cara ini:**\n- Sajikan sayur berwarna cerah.\n- Makan bersama anak.',
      );

      expect(blocks, hasLength(3));
      expect(blocks[0].kind, ChatBlockKind.paragraph);
      expect(blocks[0].text, '**Coba cara ini:**');
      expect(blocks[1].kind, ChatBlockKind.bullet);
      expect(blocks[1].text, 'Sajikan sayur berwarna cerah.');
      expect(blocks[2].kind, ChatBlockKind.bullet);
      expect(blocks[2].text, 'Makan bersama anak.');
    });

    test('daftar bernomor dan heading', () {
      final blocks = ChatMarkdownParser.parse(
        '## Langkah\n1. Mulai porsi kecil.\n2) Jangan memaksa.',
      );

      expect(blocks, hasLength(3));
      expect(blocks[0].kind, ChatBlockKind.heading);
      expect(blocks[0].text, 'Langkah');
      expect(blocks[1].kind, ChatBlockKind.numbered);
      expect(blocks[1].marker, '1');
      expect(blocks[1].text, 'Mulai porsi kecil.');
      expect(blocks[2].marker, '2');
    });

    test('tabel diubah menjadi teks tanpa garis pemisah', () {
      final blocks = ChatMarkdownParser.parse(
        '| Bahan | Porsi |\n|---|---|\n| Nasi | 1 mangkuk |',
      );

      expect(blocks, hasLength(2));
      expect(blocks[0].text, 'Bahan · Porsi');
      expect(blocks[1].text, 'Nasi · 1 mangkuk');
    });

    test('baris kosong tidak menghasilkan blok kosong', () {
      final blocks = ChatMarkdownParser.parse('\n\nHalo\n\n\nDunia\n\n');
      expect(blocks, hasLength(2));
      expect(blocks[0].text, 'Halo');
      expect(blocks[1].text, 'Dunia');
    });
  });

  group('ChatMarkdownParser.inlineSpans', () {
    test('tebal, miring, dan kode mempertahankan teks asli', () {
      final spans = ChatMarkdownParser.inlineSpans(
        'Halo **Bunda**, *sayur* dan `nasi`.',
        const TextStyle(),
      );

      expect(
        spans.map((span) => span.toPlainText()).join(),
        'Halo Bunda, sayur dan nasi.',
      );

      final bold = spans.whereType<TextSpan>().firstWhere(
        (span) => span.style?.fontWeight == FontWeight.w700,
      );
      expect(bold.text, 'Bunda');

      final italic = spans.whereType<TextSpan>().firstWhere(
        (span) => span.style?.fontStyle == FontStyle.italic,
      );
      expect(italic.text, 'sayur');
    });

    test('tautan dirender sebagai teks tanpa URL', () {
      final spans = ChatMarkdownParser.inlineSpans(
        'Lihat [Buku KIA](https://example.com) untuk panduan.',
        const TextStyle(),
      );

      expect(
        spans.map((span) => span.toPlainText()).join(),
        'Lihat Buku KIA untuk panduan.',
      );
    });

    test('penanda tidak lengkap dibiarkan apa adanya', () {
      final spans = ChatMarkdownParser.inlineSpans(
        'Halo **Bunda',
        const TextStyle(),
      );

      expect(spans.map((span) => span.toPlainText()).join(), 'Halo **Bunda');
    });

    test('teks tanpa markdown tetap utuh', () {
      final spans = ChatMarkdownParser.inlineSpans(
        'Jawaban biasa tanpa format.',
        const TextStyle(),
      );

      expect(spans, hasLength(1));
      expect(spans.single.toPlainText(), 'Jawaban biasa tanpa format.');
    });
  });
}
