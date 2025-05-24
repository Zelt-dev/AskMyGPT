import 'message.dart';
import 'template_model.dart';

class ChatSession {
  String name;
  final List<Message> messages;
  final DateTime creationDate;
  TemplateModel? selectedTemplate;

  ChatSession({
    required this.name,
    required this.messages,
    required this.creationDate,
    this.selectedTemplate,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'messages': messages.map((m) => m.toJson()).toList(),
    'creationDate': creationDate.toIso8601String(),
    'selectedTemplate': selectedTemplate?.toJson(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    DateTime creationDate = DateTime.now();
    if (json.containsKey('creationDate')) {
      creationDate = DateTime.tryParse(json['creationDate']) ?? DateTime.now();
    }
    var msgList = json['messages'] as List;
    return ChatSession(
      name: json['name'],
      messages: msgList
          .map((item) => Message.fromJson(item))
          .toList(growable: true),
      creationDate: creationDate,
      selectedTemplate:
          json["selectedTemplate"] != null
              ? TemplateModel.fromJson(json["selectedTemplate"])
              : null,
    );
  }
}