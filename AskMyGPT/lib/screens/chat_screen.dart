import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'api_settings_screen.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../models/template_model.dart';
import '../widgets/formatted_ai_text.dart';
import '../widgets/answer_with_reasoning.dart';
import 'template_manager_widget.dart';
import '../config.dart';

class ChatScreen extends StatefulWidget {
  final Function toggleTheme;
  final int chatIndex;
  final String? initialSelectedModel;

  const ChatScreen({
    super.key,
    required this.toggleTheme,
    this.chatIndex = 0,
    this.initialSelectedModel,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatSession> _chatSessions = [];
  int _currentChatIndex = 0;
  bool _isLoadingChats = true;
  bool _autoScrollEnabled = true;
  bool _isSending = false;
  int _currentRequestId = 0;
  bool _isSnackbarVisible = false;

  final TextEditingController _textController = TextEditingController();
  String _selectedModel = 'DeepSeek';
  final List<String> _models = [
    'ChatGPT',
    'Grok AI',
    'DeepSeek',
    'Mistral',
    'Qwen',
  ];
  int? _reloadingMessageIndex;

  late ScrollController _scrollController;
  final ValueNotifier<bool> _showScrollDownBtnNotifier = ValueNotifier(false);
  final Map<int, GlobalKey> _messageKeys = {};

  final Set<int> _selectedChatsForDeletion = {};

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.initialSelectedModel ?? 'DeepSeek';
    _loadChatSessions();
    _scrollController = ScrollController();
  }

  void _uploadFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция загрузки файлов пока не реализована'),
      ),
    );
  }

  void _showModelSelection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _models.map((model) {
                  return ListTile(
                    title: Text(
                      model,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedModel = model;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _smoothScrollToBottom() {
    if (!_scrollController.hasClients) return;
    const double speed = 30000.0;
    const Duration frameDuration = Duration(milliseconds: 7);
    Timer.periodic(frameDuration, (Timer timer) {
      if (!_scrollController.hasClients) {
        timer.cancel();
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      final delta = speed * (frameDuration.inMilliseconds / 1000.0);
      if (currentOffset + delta < maxScroll) {
        _scrollController.jumpTo(currentOffset + delta);
      } else {
        _scrollController.jumpTo(maxScroll);
        timer.cancel();
      }
    });

    // Re-enable auto-scrolling
    setState(() {
      _autoScrollEnabled = true;
    });
  }

  void _scrollToMessage(int index) {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      RenderObject? renderObject =
          _messageKeys[index]?.currentContext?.findRenderObject();
      if (renderObject is RenderBox) {
        _scrollController.position.ensureVisible(
          renderObject,
          alignment: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadChatSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionsJson = prefs.getString('chat_sessions');
    if (sessionsJson == null) {
      _chatSessions = [
        ChatSession(name: "Чат 1", messages: [], creationDate: DateTime.now()),
      ];
      _currentChatIndex = 0;
      await _saveChatSessions();
    } else {
      List<dynamic> decoded = jsonDecode(sessionsJson);
      _chatSessions = decoded
          .map((e) => ChatSession.fromJson(e))
          .toList(growable: true);
    }

    for (var session in _chatSessions) {
      for (var msg in session.messages) {
        if (msg.text.trim().isNotEmpty) {
          msg.isNew = false;
        }
      }
    }

    _chatSessions.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    _currentChatIndex =
        (widget.chatIndex < _chatSessions.length) ? widget.chatIndex : 0;
    setState(() {
      _isLoadingChats = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _smoothScrollToBottom();
    });
  }

  Future<void> _saveChatSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(
      _chatSessions.map((chat) => chat.toJson()).toList(),
    );
    await prefs.setString('chat_sessions', encoded);
  }

  void _cancelMessageRequest() {
    setState(() {
      _currentRequestId++;
      _isSending = false;
      _reloadingMessageIndex = null;
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty || _isSending) return;

    final String text = _textController.text.trim();

    setState(() {
      _chatSessions[_currentChatIndex].messages.add(
        Message(text: text, isUser: true),
      );
      _isSending = true;
    });

    final int requestId = ++_currentRequestId;
    await _saveChatSessions();
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _smoothScrollToBottom();
    });

    setState(() {
      _chatSessions[_currentChatIndex].messages.add(
        Message(text: '', isUser: false, isNew: true),
      );
    });

    try {
      String reply = '';

      if (_selectedModel == 'Qwen') {
        reply = await _getQwenResponse(chatIndex: _currentChatIndex);
      } else if (_selectedModel == 'DeepSeek') {
        final replyData = await _getDeepSeekResponse(text);
        reply = replyData['content'] ?? '';
        if (requestId == _currentRequestId) {
          setState(() {
            final last = _chatSessions[_currentChatIndex].messages.length - 1;
            final msg = _chatSessions[_currentChatIndex].messages[last];
            msg.text = reply;
            msg.reasoningContent = replyData['reasoningContent'] ?? '';
            msg.alternativeAnswers = [msg.text];
            msg.alternativeReasonings = [msg.reasoningContent ?? ''];
            msg.alternativeModelNames = [_selectedModel];
            msg.currentAnswerIndex = 0;
            msg.isNew = false;
            msg.modelName = _selectedModel;
            _isSending = false;
          });
          await _saveChatSessions();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _smoothScrollToBottom();
          });

          // Generate chat name using DeepSeek immediately after the first message is sent
          await _generateChatName();
        }
        return;
      } else if (_selectedModel == 'Mistral') {
        reply = await _getMistralResponse(chatIndex: _currentChatIndex);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        reply = 'Ответ от $_selectedModel';
      }

      if (requestId == _currentRequestId) {
        setState(() {
          final last = _chatSessions[_currentChatIndex].messages.length - 1;
          final msg = _chatSessions[_currentChatIndex].messages[last];
          msg.text = reply;
          msg.alternativeAnswers = [msg.text];
          msg.alternativeReasonings = [''];
          msg.currentAnswerIndex = 0;
          msg.isNew = false;
          msg.modelName = _selectedModel;
          msg.alternativeModelNames = [_selectedModel];
          _isSending = false;
        });

        // Generate chat name using DeepSeek immediately after the first message is sent
        await _generateChatName();
      }
    } catch (e) {
      if (requestId == _currentRequestId) {
        setState(() {
          _chatSessions[_currentChatIndex].messages.add(
            Message(text: 'Ошибка: $e', isUser: false),
          );
          _isSending = false;
        });
      }
    }

    await _saveChatSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _smoothScrollToBottom();
    });
  }

  Future<void> _generateChatName() async {
    final chatHistory =
        _chatSessions[_currentChatIndex].messages
            .map(
              (msg) => {
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.text,
              },
            )
            .toList();

    final prompt = """
  {
    "messages": $chatHistory
  }
  """;

    final chatNamePrompt =
        "твоя задача дать название чату исходя из контекста сообщений: $prompt, не больше 5 слов и без смайлов обязательно и без кавычек и без примечаний, просто дай в своем ответе лишь название чата НА РУССКОМ ЯЗЫКЕ и пожалуйста старайся не использовать слово 'помощь' и все похожие слова в ответе";

    try {
      final response = await _getMistralResponseForChatName(chatNamePrompt);
      if (!mounted) return; // Check if the widget is still mounted

      final chatName = response.trim();

      setState(() {
        _chatSessions[_currentChatIndex].name = chatName;
      });

      await _saveChatSessions();
    } catch (e) {
      print("Ошибка при генерации названия чата: $e");
    }
  }

  Future<String> _getMistralResponseForChatName(String prompt) async {
    final url = Uri.parse(MISTRAL_API_URL);
    await Future.delayed(Duration(seconds: 2));

    final body = jsonEncode({
      "model": "mistral-large-latest",
      "stream": false,
      "presence_penalty": 0,
      "frequency_penalty": 0,
      "n": 1,
      "parallel_tool_calls": true,
      "safe_prompt": false,
      "messages": [
        {"role": "user", "content": prompt},
      ],
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $MISTRAL_API_KEY",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      final content = data['choices'][0]['message']['content'] as String;
      return content;
    } else {
      throw Exception("Ошибка API: ${response.statusCode}");
    }
  }

  Future<Map<String, String>> _getDeepSeekResponse(
    String userMessage, {
    bool useFullConversation = true,
    int? reloadMessageIndex,
  }) async {
    final url = Uri.parse("$BASE_URL/chat/completions");
    final headers = {
      "Authorization": "Bearer $DEEPSEEK_API_KEY",
      "Content-Type": "application/json",
    };

    String systemPrompt =
        _chatSessions[_currentChatIndex].selectedTemplate?.prompt ??
        "You are a helpful assistant.";

    List<Map<String, String>> conversation = [
      {"role": "system", "content": systemPrompt},
    ];

    if (!useFullConversation && reloadMessageIndex != null) {
      for (int i = 0; i < reloadMessageIndex; i++) {
        final msg = _chatSessions[_currentChatIndex].messages[i];
        if (!msg.isUser && msg.text.trim().isEmpty) continue;
        conversation.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }
    } else {
      for (var msg in _chatSessions[_currentChatIndex].messages) {
        if (!msg.isUser && msg.text.trim().isEmpty) continue;
        conversation.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }
    }

    final body = jsonEncode({
      "model": DEEPSEEK_MODEL,
      "messages": conversation,
      "stream": true,
    });

    final request =
        http.Request("POST", url)
          ..headers.addAll(headers)
          ..body = body;

    final client = http.Client();
    final streamedResponse = await client.send(request);

    StringBuffer reasoningBuffer = StringBuffer();
    StringBuffer contentBuffer = StringBuffer();

    if (streamedResponse.statusCode == 200) {
      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
        if (chunk.trim() == "[DONE]") break;
        for (var line in chunk.split("\n")) {
          if (line.trim().isEmpty) continue;
          if (line.startsWith("data:")) {
            line = line.substring(5).trim();
          }
          if (line == "[DONE]") break;
          try {
            final Map<String, dynamic> jsonData = jsonDecode(line);
            final delta = jsonData["choices"]?[0]?["delta"];
            if (delta != null) {
              bool updated = false;
              if (delta.containsKey("reasoning_content")) {
                String? newReasoning = delta["reasoning_content"];
                if (newReasoning != null) {
                  reasoningBuffer.write(newReasoning);
                  updated = true;
                }
              }
              if (delta.containsKey("content")) {
                String? newContent = delta["content"];
                if (newContent != null) {
                  contentBuffer.write(newContent);
                  updated = true;
                }
              }
              if (updated) {
                setState(() {
                  _chatSessions[_currentChatIndex].messages.last.text =
                      contentBuffer.toString();
                  _chatSessions[_currentChatIndex]
                      .messages
                      .last
                      .reasoningContent = reasoningBuffer.toString();
                });
              }
            }
            if (jsonData["choices"]?[0]?["finish_reason"] == "stop") break;
          } catch (e) {
            print("Ошибка парсинга чанка: $e");
          }
        }
      }
      client.close();
      return {
        "reasoningContent": reasoningBuffer.toString(),
        "content": contentBuffer.toString(),
      };
    } else {
      client.close();
      throw Exception("Ошибка API: ${streamedResponse.statusCode}");
    }
  }

  Future<String> _getQwenResponse({
    required int chatIndex,
    bool useFullConversation = true,
    int? reloadMessageIndex,
  }) async {
    final url = Uri.parse(QWEN_API_URL);

    List<Map<String, String>> messages = [];

    final selectedTemplate = _chatSessions[chatIndex].selectedTemplate;
    if (selectedTemplate != null) {
      messages.add({"role": "system", "content": selectedTemplate.prompt});
    }

    if (!useFullConversation && reloadMessageIndex != null) {
      for (int i = 0; i < reloadMessageIndex; i++) {
        final msg = _chatSessions[chatIndex].messages[i];
        if (!msg.isUser && msg.text.trim().isEmpty) continue;
        messages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }
    } else {
      for (var msg in _chatSessions[chatIndex].messages) {
        if (!msg.isUser && msg.text.trim().isEmpty) continue;
        messages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }
    }

    final body = jsonEncode({
      "model": "qwen-max-latest",
      "input": {"messages": messages},
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $QWEN_API_KEY",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      final output = data['output']['text'] as String;
      return output;
    } else {
      throw Exception(
        "Ошибка Qwen API: ${response.statusCode}: ${response.body}",
      );
    }
  }

  Future<String> _getMistralResponse({
    required int chatIndex,
    bool useFullConversation = true,
    int? reloadMessageIndex,
  }) async {
    final url = Uri.parse(MISTRAL_API_URL);

    List<Map<String, String>> messages = [];

    final selectedTemplate = _chatSessions[chatIndex].selectedTemplate;
    if (selectedTemplate != null) {
      messages.add({"role": "system", "content": selectedTemplate.prompt});
    }

    if (!useFullConversation && reloadMessageIndex != null) {
      for (int i = 0; i < reloadMessageIndex; i++) {
        final msg = _chatSessions[chatIndex].messages[i];
        if (!msg.isUser && msg.text.trim().isEmpty) continue;
        messages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }
    } else {
      for (var msg in _chatSessions[chatIndex].messages) {
        if (!msg.isUser && msg.text.trim().isEmpty) continue;
        messages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }
    }

    final body = jsonEncode({
      "model": "mistral-large-latest",
      "stream": true,
      "presence_penalty": 0,
      "frequency_penalty": 0,
      "n": 1,
      "parallel_tool_calls": true,
      "safe_prompt": false,
      "messages": messages,
    });

    final request =
        http.Request("POST", url)
          ..headers.addAll({
            "Content-Type": "application/json",
            "Authorization": "Bearer $MISTRAL_API_KEY",
          })
          ..body = body;

    final client = http.Client();
    final streamedResponse = await client.send(request);

    if (streamedResponse.statusCode == 200) {
      StringBuffer contentBuffer = StringBuffer();

      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
        if (chunk.trim().isEmpty) continue;
        for (var line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          if (line.startsWith("data:")) {
            line = line.substring(5).trim();
          }
          if (line == "[DONE]") break;
          try {
            final Map<String, dynamic> jsonData = jsonDecode(line);
            final delta = jsonData["choices"]?[0]?["delta"];
            if (delta != null && delta.containsKey("content")) {
              String? newContent = delta["content"];
              if (newContent != null) {
                contentBuffer.write(newContent);
                setState(() {
                  _chatSessions[_currentChatIndex].messages.last.text =
                      contentBuffer.toString();
                });
              }
            }
            if (jsonData["choices"]?[0]?["finish_reason"] == "stop") break;
          } catch (e) {
            print("Ошибка парсинга чанка: $e");
          }
        }
      }
      client.close();
      return contentBuffer.toString();
    } else {
      client.close();
      throw Exception("Ошибка API: ${streamedResponse.statusCode}");
    }
  }

  void _reloadAIMessageForIndex(int index) async {
    if (index <= 0 ||
        !_chatSessions[_currentChatIndex].messages[index - 1].isUser) {
      return;
    }

    // Remove all messages after the selected message
    setState(() {
      _chatSessions[_currentChatIndex].messages.removeRange(
        index + 1,
        _chatSessions[_currentChatIndex].messages.length,
      );
    });

    final int requestId = ++_currentRequestId;
    setState(() {
      _isSending = true;
      _reloadingMessageIndex = index;
    });

    final String userText =
        _chatSessions[_currentChatIndex].messages[index - 1].text;

    try {
      String reply = '';
      String? newReasoning;

      if (_selectedModel == 'Qwen') {
        reply = await _getQwenResponse(
          chatIndex: _currentChatIndex,
          useFullConversation: false,
          reloadMessageIndex: index,
        );
        newReasoning = null;
      } else if (_selectedModel == 'DeepSeek') {
        final replyData = await _getDeepSeekResponse(
          userText,
          useFullConversation: false,
          reloadMessageIndex: index,
        );
        reply = replyData['content'] ?? '';
        newReasoning = replyData['reasoningContent'];
      } else if (_selectedModel == 'Mistral') {
        reply = await _getMistralResponse(
          chatIndex: _currentChatIndex,
          useFullConversation: false,
          reloadMessageIndex: index,
        );
        newReasoning = null;
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        reply = 'Ответ от $_selectedModel';
        newReasoning = null;
      }

      if (requestId == _currentRequestId) {
        setState(() {
          final msg = _chatSessions[_currentChatIndex].messages[index];

          msg.alternativeAnswers ??= [msg.text];
          msg.alternativeReasonings ??= [msg.reasoningContent ?? ''];
          msg.alternativeModelNames ??= [msg.modelName ?? 'Unknown'];

          msg.alternativeAnswers!.add(reply);
          msg.alternativeReasonings!.add(newReasoning ?? '');
          msg.alternativeModelNames!.add(_selectedModel);

          msg.currentAnswerIndex = msg.alternativeAnswers!.length - 1;
          msg.text = msg.alternativeAnswers![msg.currentAnswerIndex];
          msg.reasoningContent =
              msg.alternativeReasonings![msg.currentAnswerIndex];
          msg.modelName = msg.alternativeModelNames![msg.currentAnswerIndex];

          msg.isNew = false;
          msg.modelName = _selectedModel;
          _isSending = false;
          _reloadingMessageIndex = null;
        });
      }
    } catch (e) {
      if (requestId == _currentRequestId) {
        setState(() {
          _chatSessions[_currentChatIndex].messages[index] = Message(
            text: 'Ошибка: $e',
            isUser: false,
          );
          _isSending = false;
          _reloadingMessageIndex = null;
        });
      }
    }

    await _saveChatSessions();
  }

  void _onTemplatesPressed() async {
    if (_chatSessions[_currentChatIndex].messages.isNotEmpty &&
        _chatSessions[_currentChatIndex].selectedTemplate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Создайте новый чат, чтобы изменить шаблон.'),
        ),
      );
      return;
    }
    TemplateModel? selected = await showModalBottomSheet<TemplateModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TemplateManagerWidget(),
    );
    if (selected != null) {
      setState(() {
        _chatSessions[_currentChatIndex].selectedTemplate = selected;
      });
      _saveChatSessions();
    }
  }

  Widget _buildMessage(Message message, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    _messageKeys[index] = GlobalKey();

    if (message.isUser) {
      return Container(
        key: _messageKeys[index],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: SelectableText(
                message.text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 120,
                      left: 85,
                      right: 85,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    content: const Text(
                      'Сообщение скопировано',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.copy, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        key: _messageKeys[index],
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.reasoningContent != null &&
                message.reasoningContent!.trim().isNotEmpty)
              AnswerWithReasoning(
                answerText: message.text,
                reasoningText: message.reasoningContent!,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                },
                onReload:
                    _isSending ? () {} : () => _reloadAIMessageForIndex(index),
                onSwitchAlternative:
                    _isSending
                        ? null
                        : () {
                          setState(() {
                            final answers = message.alternativeAnswers!;
                            final reasonings = message.alternativeReasonings!;

                            message.currentAnswerIndex =
                                (message.currentAnswerIndex + 1) %
                                answers.length;

                            message.text = answers[message.currentAnswerIndex];
                            message.reasoningContent =
                                reasonings[message.currentAnswerIndex];
                            message.modelName =
                                message.alternativeModelNames![message
                                    .currentAnswerIndex];

                            _scrollToMessage(index);
                          });
                        },
                currentAlternativeIndex: message.currentAnswerIndex,
                alternativeCount: message.alternativeAnswers?.length ?? 0,
                textColor: textColor,
                isDarkTheme: isDark,
                disableAnimation: !message.isNew,
                isReload: _reloadingMessageIndex == index,
                isAIMessage: true,
                modelName: message.modelName,
                scrollController: _scrollController,
                autoScrollEnabled:
                    _autoScrollEnabled, // Pass the autoScrollEnabled state
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: FormattedAIText(
                      text: message.text,
                      textColor: textColor,
                      isDarkTheme: isDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                    120,
                                left: 85,
                                right: 85,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              content: const Text(
                                'Сообщение скопировано',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.copy, size: 18, color: textColor),
                        ),
                      ),
                      InkWell(
                        onTap:
                            _isSending
                                ? null
                                : () => _reloadAIMessageForIndex(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.refresh,
                            size: 18,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (message.alternativeAnswers != null &&
                          message.alternativeAnswers!.length > 1)
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (message.alternativeAnswers == null ||
                                  message.alternativeAnswers!.isEmpty) {
                                return;
                              }

                              message.currentAnswerIndex =
                                  (message.currentAnswerIndex + 1) %
                                  message.alternativeAnswers!.length;
                              message.text =
                                  message.alternativeAnswers![message
                                      .currentAnswerIndex];
                              message.reasoningContent =
                                  (message.alternativeReasonings?.length ?? 0) >
                                          message.currentAnswerIndex
                                      ? message.alternativeReasonings![message
                                          .currentAnswerIndex]
                                      : '';
                              message.modelName =
                                  (message.alternativeModelNames?.length ?? 0) >
                                          message.currentAnswerIndex
                                      ? message.alternativeModelNames![message
                                          .currentAnswerIndex]
                                      : 'Unknown';
                            });

                            _scrollToMessage(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              "< ${message.currentAnswerIndex + 1} / ${message.alternativeAnswers?.length ?? 0} >",
                              style: TextStyle(color: textColor, fontSize: 14),
                            ),
                          ),
                        ),
                      if (message.modelName != null &&
                          message.modelName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            message.modelName!,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );
    }
  }


  String _getChatGroup(DateTime creationDate) {
    final now = DateTime.now();
    final difference = now.difference(creationDate).inDays;
    if (difference == 0) {
      return "Сегодня";
    } else if (difference == 1) {
      return "Вчера";
    } else {
      return "Предыдущие 7 дней";
    }
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    List<MapEntry<int, ChatSession>> indexedChats =
        _chatSessions.asMap().entries.toList();
    Map<String, List<MapEntry<int, ChatSession>>> groupedChats = {};
    for (var entry in indexedChats) {
      if (entry.value.messages.isEmpty) continue;
      String group = _getChatGroup(entry.value.creationDate);
      groupedChats.putIfAbsent(group, () => []).add(entry);
    }
    List<String> groupOrder = ["Сегодня", "Вчера", "Предыдущие 7 дней"];
    List<Widget> chatListWidgets = [];
    for (String group in groupOrder) {
      if (groupedChats.containsKey(group)) {
        chatListWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 4),
            child: Text(
              group,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 16,
              ),
            ),
          ),
        );
        for (var entry in groupedChats[group]!) {
          int i = entry.key;
          ChatSession chat = entry.value;
          bool isSelectionMode = _selectedChatsForDeletion.isNotEmpty;
          bool isSelected = _selectedChatsForDeletion.contains(i);
          chatListWidgets.add(
            ListTile(
              tileColor:
                  isSelected
                      ? (isDark ? Colors.grey[800] : Colors.grey[300])
                      : null,
              leading:
                  isSelectionMode
                      ? Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: textColor,
                      )
                      : Icon(Icons.chat, color: textColor),
              title: Text(chat.name, style: TextStyle(color: textColor)),
              onLongPress: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedChatsForDeletion.add(i);
                });
              },
              onTap: () {
                if (isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedChatsForDeletion.remove(i);
                    } else {
                      _selectedChatsForDeletion.add(i);
                    }
                  });
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
                            toggleTheme: widget.toggleTheme,
                            chatIndex: i,
                          ),
                    ),
                  );
                }
              },
            ),
          );
        }
        chatListWidgets.add(const SizedBox(height: 70.0));
      }
    }
    if (chatListWidgets.isNotEmpty && chatListWidgets.last is SizedBox) {
      chatListWidgets.removeLast();
    }

    const double staticPanelHeight = 220.0;
    return Drawer(
      backgroundColor: drawerBg,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: staticPanelHeight),
            children: chatListWidgets,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: drawerBg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedChatsForDeletion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(40),
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Удалить выбранные чаты",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            setState(() {
                              List<int> indices =
                                  _selectedChatsForDeletion.toList()
                                    ..sort((a, b) => b.compareTo(a));
                              bool isCurrentChatDeleted = indices.contains(
                                _currentChatIndex,
                              );
                              for (var index in indices) {
                                _chatSessions.removeAt(index);
                              }
                              _selectedChatsForDeletion.clear();
                              if (_chatSessions.isEmpty) {
                                _chatSessions.add(
                                  ChatSession(
                                    name: "Чат 1",
                                    messages: [],
                                    creationDate: DateTime.now(),
                                  ),
                                );
                                Navigator.pop(context);
                              } else if (isCurrentChatDeleted) {
                                _chatSessions.sort(
                                  (a, b) =>
                                      b.creationDate.compareTo(a.creationDate),
                                );
                                _currentChatIndex = 0;
                              }
                            });
                            await _saveChatSessions();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.settings, color: textColor),
                    title: Text(
                      'Настройки API',
                      style: TextStyle(color: textColor),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApiSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  SwitchListTile(
                    secondary: Icon(Icons.dark_mode, color: textColor),
                    title: Text(
                      'Темная тема',
                      style: TextStyle(color: textColor),
                    ),
                    value: isDark,
                    onChanged: (value) => widget.toggleTheme(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final inputBackgroundColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    final inputBorderColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;

    return Column(
      children: [
        // Строка ввода
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: inputBackgroundColor, // Цвет фона
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: inputBorderColor), // Цвет рамки
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    enabled: !_isSending,
                    maxLines: 6, // Максимум 6 строк
                    minLines: 1, // Минимум 1 строка
                    style: TextStyle(color: textColor), // Цвет текста
                    decoration: InputDecoration(
                      hintText:
                          _isSending
                              ? 'Ожидание ответа...'
                              : 'Введите сообщение...',
                      hintStyle: TextStyle(
                        color: textColor.withOpacity(0.5),
                      ), // Цвет подсказки
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: InputBorder.none, // Убираем стандартную рамку
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Панель с кнопками
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Кнопка добавления файла
              InkWell(
                onTap:
                    _uploadFile, // Логика загрузки файла (пока не реализована)
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: inputBackgroundColor, // Цвет фона
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.attach_file, color: Colors.blue)],
                  ),
                ),
              ),
              const SizedBox(width: 8), // Отступ между кнопками
              // Кнопка выбора нейросети
              InkWell(
                onTap: _isSending ? null : () => _showModelSelection(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: inputBackgroundColor, // Цвет фона
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.memory, color: Colors.purple[500]),
                      const SizedBox(width: 8),
                      Text(
                        _selectedModel,
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8), // Отступ между кнопками
              // Кнопка "Шаблон"
              InkWell(
                onTap: _isSending ? null : _onTemplatesPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: inputBackgroundColor, // Цвет фона
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        "Шаблон",
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(), // Перемещает следующую кнопку вправо
              // Кнопка отправки
              FloatingActionButton(
                elevation: 0, // Убирает тень
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                onPressed: _isSending ? _cancelMessageRequest : _sendMessage,
                backgroundColor: Colors.blue,
                mini: true,
                shape: CircleBorder(), // Явно задаем круглую форму
                child: Icon(
                  _isSending ? Icons.close : Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getNextChatNumber() {
    int maxNumber = 0;
    RegExp regex = RegExp(r'Чат (\d+)');
    for (var chat in _chatSessions) {
      if (chat.messages.isNotEmpty) {
        var match = regex.firstMatch(chat.name);
        if (match != null) {
          int number = int.tryParse(match.group(1)!) ?? 0;
          if (number > maxNumber) {
            maxNumber = number;
          }
        }
      }
    }
    return maxNumber + 1;
  }

  void _showCustomSnackbar(String message) {
    if (_isSnackbarVisible) return;
    _isSnackbarVisible = true;

    OverlayEntry overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 70,
            right: 70,
            child: Material(
              color: const Color.fromARGB(0, 20, 20, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
      _isSnackbarVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color chatBgColor = Theme.of(context).scaffoldBackgroundColor;
    if (_isLoadingChats) {
      return Scaffold(
        backgroundColor: chatBgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: chatBgColor,
      drawer: _buildDrawer(),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: chatBgColor,
        elevation: 0,
        surfaceTintColor: chatBgColor,
        title: Text(
          _chatSessions[_currentChatIndex].name,
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        iconTheme: IconThemeData(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () async {
              if (_chatSessions[_currentChatIndex].messages.isEmpty) {
                _showCustomSnackbar("Уже в новом чате");
                return;
              }
              int newChatNumber = _getNextChatNumber();
              String currentModel = _selectedModel;

              setState(() {
                _chatSessions.insert(
                  0,
                  ChatSession(
                    name: "Чат $newChatNumber",
                    messages: [],
                    creationDate: DateTime.now(),
                  ),
                );
              });
              await _saveChatSessions();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatScreen(
                        toggleTheme: widget.toggleTheme,
                        chatIndex: 0,
                        initialSelectedModel: currentModel,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [Expanded(child: _buildChatList()), _buildInputArea()],
          ),
          Positioned(
            right: 16,
            bottom: 120,
            child: ValueListenableBuilder<bool>(
              valueListenable: _showScrollDownBtnNotifier,
              builder: (context, show, child) {
                return AnimatedOpacity(
                  opacity: show ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !show,
                    //  child: FloatingActionButton(
                    //    onPressed: _smoothScrollToBottom,
                    //    child: const Icon(Icons.expand_more, size: 25),
                    //  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    List<Message> msgs = _chatSessions[_currentChatIndex].messages;
    if (msgs.isEmpty) {
      return Center(
        child: Text(
          'Начните чат, отправив сообщение...',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 10),
      itemCount: msgs.length,
      itemBuilder: (context, index) {
        return _buildMessage(msgs[index], index);
      },
    );
  }
}