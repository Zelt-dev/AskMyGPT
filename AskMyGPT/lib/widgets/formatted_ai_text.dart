import 'package:flutter/material.dart';
import 'code_block.dart';

class FormattedAIText extends StatelessWidget {
  final String text;
  final Color? textColor;
  final bool isDarkTheme;
  const FormattedAIText({
    super.key,
    required this.text,
    required this.textColor,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = [];
    final lines = text.split('\n');

    bool inCodeBlock = false;
    String codeLanguage = '';
    List<String> codeLines = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.trim().startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeLanguage = line.trim().substring(3).trim();
          codeLines = [];
        } else {
          inCodeBlock = false;
          spans.add(
            WidgetSpan(
              child: CodeBlock(
                code: codeLines.join('\n'),
                language: codeLanguage,
                isDarkTheme: true,
              ),
            ),
          );
          spans.add(const TextSpan(text: '\n'));
        }
        continue;
      }
      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      if (line.startsWith('### ') || line.startsWith('#### ')) {
        int headerLevel = '#'.allMatches(line).length;
        String headerText = line.substring(headerLevel + 1);
        List<InlineSpan> headerSpans = _processLine(headerText, textColor);
        spans.add(
          TextSpan(
            children: headerSpans,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      if (line.trim() == '---') {
        spans.add(
          WidgetSpan(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 1,
              color: textColor?.withOpacity(0.5),
            ),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      List<InlineSpan> lineSpans = _processLine(line, textColor);
      spans.addAll(lineSpans);
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(color: textColor),
    );
  }

  List<InlineSpan> _processLine(String line, Color? textColor) {
    List<InlineSpan> spans = [];

    if (line.trim().startsWith('- ')) {
      spans.add(
        TextSpan(
          text: '   • ',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      );
      line = line.trim().substring(2);
    }

    RegExp pattern = RegExp(r'(`([^`]+)`)|\*\*(.+?)\*\*');
    int lastIndex = 0;

    for (final match in pattern.allMatches(line)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: line.substring(lastIndex, match.start),
            style: TextStyle(color: textColor),
          ),
        );
      }
      if (match.group(2) != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                match.group(2)!,
                style: TextStyle(fontFamily: 'monospace', color: textColor),
              ),
            ),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      spans.add(
        TextSpan(
          text: line.substring(lastIndex),
          style: TextStyle(color: textColor),
        ),
      );
    }

    return spans;
  }
}