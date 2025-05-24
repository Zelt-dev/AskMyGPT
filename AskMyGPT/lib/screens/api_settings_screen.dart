import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});
  @override
  _ApiSettingsScreenState createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _chatGptController = TextEditingController();
  final TextEditingController _grokController = TextEditingController();
  final TextEditingController _deepSeekController = TextEditingController();
  final TextEditingController _mistralController = TextEditingController();
  final TextEditingController _qwenController =
      TextEditingController(); // Add Qwen controller

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatGptController.text = prefs.getString('chatgpt') ?? '';
      _grokController.text = prefs.getString('grok') ?? '';
      _deepSeekController.text = prefs.getString('deepseek') ?? '';
      _mistralController.text = prefs.getString('mistral') ?? '';
      _qwenController.text = prefs.getString('qwen') ?? ''; // Load Qwen key
    });
  }

  Future<void> _saveKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatgpt', _chatGptController.text);
    await prefs.setString('grok', _grokController.text);
    await prefs.setString('deepseek', _deepSeekController.text);
    await prefs.setString('mistral', _mistralController.text);
    await prefs.setString('qwen', _qwenController.text); // Save Qwen key

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API ключи сохранены')));
  }

  Widget _buildApiInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Введите ключ'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки API')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildApiInput('ChatGPT API ключ', _chatGptController),
            _buildApiInput('Grok AI API ключ', _grokController),
            _buildApiInput('DeepSeek API ключ', _deepSeekController),
            _buildApiInput('Mistral API ключ', _mistralController),
            _buildApiInput(
              'Qwen API ключ',
              _qwenController,
            ), // Add Qwen input field
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveKeys,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}