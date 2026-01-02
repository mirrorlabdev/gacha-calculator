import 'package:flutter/material.dart';

class ChunkedText extends StatelessWidget {
  final List<String> chunks;
  final TextStyle? style;
  final int fallbackBreakEvery;

  const ChunkedText({
    super.key,
    required this.chunks,
    this.style,
    this.fallbackBreakEvery = 5,
  });

  static const _wj = '\u2060';
  static const _zwsp = '\u200B';
  static const _nbsp = '\u00A0';

  bool _isNumericHeavy(String s) {
    // 숫자 하나라도 있으면 숫자형 취급
    return RegExp(r'\d').hasMatch(s);
  }

  String _lockChunk(String chunk) {
    final lockedSpaces = chunk.replaceAll(' ', _nbsp);
    final chars = lockedSpaces.characters.toList();
    final b = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      b.write(chars[i]);
      if (i == chars.length - 1) break;

      final allowBreakHere = ((i + 1) % fallbackBreakEvery == 0);
      b.write(allowBreakHere ? _zwsp : _wj);
    }
    return b.toString();
  }

  InlineSpan _spanForChunk(String c, TextStyle s) {
    if (_isNumericHeavy(c)) {
      // 숫자 포함 청크 = WidgetSpan = 절대 안 쪼개짐
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Text(c, style: s, textScaler: TextScaler.noScaling),
      );
    }
    // 순수 한글 청크 = TextSpan + WJ/ZWSP
    return TextSpan(text: _lockChunk(c), style: s);
  }

  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style;

    final spans = <InlineSpan>[];
    for (int i = 0; i < chunks.length; i++) {
      spans.add(_spanForChunk(chunks[i], s));
      if (i != chunks.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans, style: s),
      softWrap: true,
    );
  }
}
