import 'package:flutter/material.dart';
import 'formatted_ai_text.dart';

class AnswerWithReasoning extends StatefulWidget {
  final String answerText;
  final String reasoningText;
  final VoidCallback onCopy;
  final VoidCallback onReload;
  final VoidCallback? onSwitchAlternative;
  final int? currentAlternativeIndex;
  final int? alternativeCount;
  final Color textColor;
  final bool isDarkTheme;
  final bool disableAnimation;
  final bool isReload;
  final bool isAIMessage;
  final String? modelName;
  final ScrollController scrollController;
  final bool autoScrollEnabled;

  const AnswerWithReasoning({
    super.key,
    required this.answerText,
    required this.reasoningText,
    required this.onCopy,
    required this.onReload,
    this.onSwitchAlternative,
    this.currentAlternativeIndex,
    this.alternativeCount,
    required this.textColor,
    required this.isDarkTheme,
    this.disableAnimation = false,
    this.isReload = false,
    required this.isAIMessage,
    this.modelName,
    required this.scrollController,
    required this.autoScrollEnabled,
  });

  @override
  _AnswerWithReasoningState createState() => _AnswerWithReasoningState();
}

class _AnswerWithReasoningState extends State<AnswerWithReasoning> {
  late String _fullReasoningText;
  late String _fullAnswerText;
  String _typedReasoningText = "";
  String _typedAnswerText = "";
  bool _expanded = false;
  final int _maxCollapsedLength = 60;
  late bool _isNew;

  @override
  void initState() {
    super.initState();
    _fullReasoningText = widget.reasoningText;
    _fullAnswerText = widget.answerText;

    _isNew = !(widget.disableAnimation && !widget.isReload);

    if ((widget.isAIMessage && _isNew) || widget.isReload) {
      _expanded = true;
      _typedReasoningText = "";
      _typedAnswerText = "";
      _startReasoningAnimation();
    } else {
      _expanded = false;
      _typedReasoningText = _fullReasoningText;
      _typedAnswerText = _fullAnswerText;
    }
  }

  @override
  void didUpdateWidget(covariant AnswerWithReasoning oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isReload && widget.isReload) {
      setState(() {
        _expanded = true;
        _typedReasoningText = "";
        _typedAnswerText = "";
        _startReasoningAnimation();
      });
    }

    if (widget.isAIMessage &&
        !oldWidget.disableAnimation &&
        widget.disableAnimation &&
        _expanded) {
      setState(() {
        _expanded = false;
      });
    }
  }

  Future<void> _startReasoningAnimation() async {
    for (int i = 0; i <= _fullReasoningText.length; i++) {
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _typedReasoningText = _fullReasoningText.substring(0, i);
      });
      if (widget.autoScrollEnabled) {
        widget.scrollController.jumpTo(
          widget.scrollController.position.maxScrollExtent,
        ); // Auto-scroll to bottom
      }
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      _expanded = false;
    });

    for (int i = 0; i <= _fullAnswerText.length; i++) {
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _typedAnswerText = _fullAnswerText.substring(0, i);
      });
      if (widget.autoScrollEnabled) {
        widget.scrollController.jumpTo(
          widget.scrollController.position.maxScrollExtent,
        ); // Auto-scroll to bottom
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayedReasoning;
    if (_expanded) {
      displayedReasoning = _typedReasoningText;
    } else {
      if (_typedReasoningText.length > _maxCollapsedLength) {
        displayedReasoning =
            "${_typedReasoningText.substring(0, _maxCollapsedLength)}...";
      } else {
        displayedReasoning = _typedReasoningText;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 2,
                    color: Colors.grey,
                    indent: 4,
                    endIndent: 4,
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.centerLeft,
          child: Text(
            displayedReasoning,
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDarkTheme ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(25),
          ),
          child: FormattedAIText(
            text: _typedAnswerText,
            textColor: widget.textColor,
            isDarkTheme: widget.isDarkTheme,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.onCopy,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.copy, size: 18, color: widget.textColor),
              ),
            ),
            InkWell(
              onTap: widget.onReload,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.refresh, size: 18, color: widget.textColor),
              ),
            ),
            if (widget.alternativeCount != null && widget.alternativeCount! > 1)
              InkWell(
                onTap: widget.onSwitchAlternative,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    "< ${widget.currentAlternativeIndex! + 1} / ${widget.alternativeCount!} >",
                    style: TextStyle(color: widget.textColor, fontSize: 14),
                  ),
                ),
              ),
            if (widget.modelName != null && widget.modelName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  widget.modelName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color:
                        widget.isDarkTheme
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}