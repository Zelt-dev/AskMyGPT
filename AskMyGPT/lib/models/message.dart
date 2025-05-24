class Message {
  String text;
  String? reasoningContent;
  final bool isUser;
  bool isNew;
  String? modelName;
  List<String>? alternativeAnswers;
  List<String>? alternativeReasonings;
  List<String>? alternativeModelNames;
  int currentAnswerIndex;

  Message({
    required this.text,
    required this.isUser,
    this.reasoningContent,
    this.isNew = false,
    this.modelName,
    this.alternativeAnswers,
    this.alternativeReasonings,
    this.alternativeModelNames,
    this.currentAnswerIndex = 0,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'reasoningContent': reasoningContent,
    'isUser': isUser,
    'isNew': isNew,
    'alternativeAnswers': alternativeAnswers,
    'alternativeReasonings': alternativeReasonings,
    'currentAnswerIndex': currentAnswerIndex,
    'modelName': modelName,
    'alternativeModelNames': alternativeModelNames,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    final msg = Message(
      text: json['text'],
      reasoningContent: json['reasoningContent'],
      isUser: json['isUser'],
      isNew: json['isNew'] ?? false,
      alternativeAnswers:
          json['alternativeAnswers'] != null
              ? List<String>.from(json['alternativeAnswers'])
              : null,
      alternativeReasonings:
          json['alternativeReasonings'] != null
              ? List<String>.from(json['alternativeReasonings'])
              : null,
      alternativeModelNames:
          json['alternativeModelNames'] != null
              ? List<String>.from(json['alternativeModelNames'])
              : null,
      currentAnswerIndex: json['currentAnswerIndex'] ?? 0,
      modelName: json['modelName'],
    );

    if (msg.alternativeAnswers != null) {
      msg.alternativeModelNames ??= List<String>.filled(
        msg.alternativeAnswers!.length,
        msg.modelName ?? 'Unknown',
        growable: true,
      );
    }

    return msg;
  }
}