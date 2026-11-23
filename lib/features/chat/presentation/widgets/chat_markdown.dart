import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Jenis blok pada jawaban asisten.
enum ChatBlockKind { paragraph, bullet, numbered, heading }

/// Satu blok hasil parsing markdown ringan.
@immutable
final class ChatBlock {
  const ChatBlock({required this.kind, required this.text, this.marker});

  final ChatBlockKind kind;
  final String text;

  /// Nomor urut untuk [ChatBlockKind.numbered].
  final String? marker;
}

/// Parser markdown ringan untuk jawaban Gemini.
///
/// Hanya mendukung format yang benar-benar dipakai jawaban: tebal, miring,
/// bullet, daftar bernomor, heading, dan baris kosong. Tabel, gambar, dan
/// tautan sengaja ditampilkan sebagai teks biasa - tidak ada HTML, gambar,
/// atau tautan yang dieksekusi dari keluaran model.
abstract final class ChatMarkdownParser {
  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _numbered = RegExp(r'^\s*(\d{1,2})[.)]\s+(.*)$');
  static final RegExp _heading = RegExp(r'^\s*#{1,3}\s+(.*)$');
  static final RegExp _tableSeparator = RegExp(r'^\s*\|?[\s:|-]+\|[\s:|-]*$');
  static final RegExp _horizontalRule = RegExp(r'^\s*([-*_])\1{2,}\s*$');
  static final RegExp _inline = RegExp(
    r'(\*\*|__)(.+?)\1|(\*|_)(.+?)\3|`([^`]+)`',
  );

  /// Pecah teks menjadi blok yang siap dirender.
  static List<ChatBlock> parse(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = <ChatBlock>[];
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      final text = paragraph.join('\n').trim();
      if (text.isNotEmpty) {
        blocks.add(ChatBlock(kind: ChatBlockKind.paragraph, text: text));
      }
      paragraph.clear();
    }

    for (final raw in normalized.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flushParagraph();
        continue;
      }
      // Pagar kode dibuang; isinya tetap tampil sebagai teks biasa.
      if (line.trimLeft().startsWith('```')) {
        flushParagraph();
        continue;
      }
      final heading = _heading.firstMatch(line);
      if (heading != null) {
        flushParagraph();
        blocks.add(
          ChatBlock(
            kind: ChatBlockKind.heading,
            text: heading.group(1)!.trim(),
          ),
        );
        continue;
      }
      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        blocks.add(
          ChatBlock(kind: ChatBlockKind.bullet, text: bullet.group(1)!.trim()),
        );
        continue;
      }
      final numbered = _numbered.firstMatch(line);
      if (numbered != null) {
        flushParagraph();
        blocks.add(
          ChatBlock(
            kind: ChatBlockKind.numbered,
            text: numbered.group(2)!.trim(),
            marker: numbered.group(1),
          ),
        );
        continue;
      }
      if (line.trimLeft().startsWith('|')) {
        flushParagraph();
        if (_tableSeparator.hasMatch(line)) continue;
        final cells = line
            .trim()
            .split('|')
            .map((cell) => cell.trim())
            .where((cell) => cell.isNotEmpty)
            .toList();
        if (cells.isNotEmpty) {
          blocks.add(
            ChatBlock(kind: ChatBlockKind.paragraph, text: cells.join(' · ')),
          );
        }
        continue;
      }
      if (_horizontalRule.hasMatch(line)) {
        flushParagraph();
        continue;
      }
      paragraph.add(line.trim());
    }
    flushParagraph();
    return blocks;
  }

  /// Ubah satu baris teks menjadi span dengan gaya tebal/miring/kode.
  ///
  /// Tautan `[teks](url)` dan gambar `![alt](url)` dirender sebagai teks
  /// saja; URL tidak pernah ditampilkan mentah.
  static List<InlineSpan> inlineSpans(String text, TextStyle style) {
    final cleaned = _stripLinks(text);
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _inline.allMatches(cleaned)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: cleaned.substring(cursor, match.start), style: style),
        );
      }
      if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: style.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(5) != null) {
        spans.add(
          TextSpan(
            text: match.group(5),
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < cleaned.length) {
      spans.add(TextSpan(text: cleaned.substring(cursor), style: style));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: cleaned, style: style));
    }
    return spans;
  }

  static String _stripLinks(String text) => text
      .replaceAllMapped(
        RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]*\)'),
        (match) => match.group(1) ?? '',
      );
}

/// Jawaban asisten yang sudah diformat rapi tanpa karakter markdown mentah.
class ChatMarkdown extends StatelessWidget {
  const ChatMarkdown({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final base = (style ?? AppTextStyles.body).copyWith(
      color: colors.textPrimary,
    );
    final blocks = ChatMarkdownParser.parse(text);
    if (blocks.isEmpty) return Text(text, style: base);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0)
            SizedBox(
              height: blocks[index].kind == ChatBlockKind.heading ? 12 : 8,
            ),
          _buildBlock(blocks[index], base, colors.textSecondary),
        ],
      ],
    );
  }

  Widget _buildBlock(ChatBlock block, TextStyle base, Color secondary) {
    switch (block.kind) {
      case ChatBlockKind.heading:
        final headingStyle = base.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          height: 24 / 17,
        );
        return Text.rich(
          TextSpan(
            children: ChatMarkdownParser.inlineSpans(block.text, headingStyle),
          ),
          style: headingStyle,
        );
      case ChatBlockKind.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•', style: base.copyWith(color: secondary)),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: ChatMarkdownParser.inlineSpans(block.text, base),
                ),
                style: base,
              ),
            ),
          ],
        );
      case ChatBlockKind.numbered:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${block.marker}.',
              style: base.copyWith(
                color: secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: ChatMarkdownParser.inlineSpans(block.text, base),
                ),
                style: base,
              ),
            ),
          ],
        );
      case ChatBlockKind.paragraph:
        return Text.rich(
          TextSpan(children: ChatMarkdownParser.inlineSpans(block.text, base)),
          style: base,
        );
    }
  }
}
