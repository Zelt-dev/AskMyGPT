import 'package:flutter/material.dart';

class CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final bool isDarkTheme;
  const CodeBlock({
    super.key,
    required this.code,
    required this.language,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    final codeBackgroundColor =
        isDarkTheme ? Colors.grey[850] : Colors.grey[200];
    final codeTextColor = isDarkTheme ? Colors.greenAccent : Colors.black87;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: codeBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                language,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                color: codeTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}