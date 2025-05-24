import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/template_model.dart';

class TemplateManagerWidget extends StatefulWidget {
  const TemplateManagerWidget({super.key});
  @override
  _TemplateManagerWidgetState createState() => _TemplateManagerWidgetState();
}

class _TemplateManagerWidgetState extends State<TemplateManagerWidget> {
  List<TemplateModel> _templates = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? templatesJson = prefs.getString('templates');
    if (templatesJson != null) {
      List<dynamic> decoded = jsonDecode(templatesJson);
      _templates = decoded.map((e) => TemplateModel.fromJson(e)).toList();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveTemplates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(_templates.map((t) => t.toJson()).toList());
    await prefs.setString('templates', encoded);
  }

  Future<void> _showAddTemplateDialog() async {
    String? name;
    String? prompt;
    final nameController = TextEditingController();
    final promptController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Добавить новый шаблон",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Название",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: "Промпт",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    promptController.text.trim().isNotEmpty) {
                  name = nameController.text.trim();
                  prompt = promptController.text.trim();
                  Navigator.pop(context);
                }
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );

    if (name != null && prompt != null) {
      setState(() {
        _templates.add(TemplateModel(name: name!, prompt: prompt!));
      });
      await _saveTemplates();
    }
  }

  void _deleteSelectedTemplates() async {
    setState(() {
      List<int> indices =
          _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (var index in indices) {
        _templates.removeAt(index);
      }
      _selectedIndices.clear();
      _selectionMode = false;
    });
    await _saveTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Шаблоны"),
            actions: [
              _selectionMode
                  ? IconButton(
                    icon: const Text(
                      "🗑 Удалить",
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed:
                        _selectedIndices.isEmpty
                            ? null
                            : () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text("Подтвердите удаление"),
                                      content: const Text(
                                        "Удалить выбранные шаблоны?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Отмена"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteSelectedTemplates();
                                          },
                                          child: const Text("Удалить"),
                                        ),
                                      ],
                                    ),
                              );
                            },
                  )
                  : IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showAddTemplateDialog,
                  ),
            ],
          ),
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _templates.isEmpty
                  ? const Center(child: Text("Нет шаблонов"))
                  : ListView.builder(
                    controller: scrollController,
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      final isSelected = _selectedIndices.contains(index);
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            _selectedIndices.add(index);
                          });
                        },
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedIndices.remove(index);
                                if (_selectedIndices.isEmpty) {
                                  _selectionMode = false;
                                }
                              } else {
                                _selectedIndices.add(index);
                              }
                            });
                          } else {
                            Navigator.pop(context, template);
                          }
                        },
                        child: Card(
                          color: isSelected ? Colors.grey[300] : null,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  template.prompt.length > 50
                                      ? "\\${template.prompt.substring(0, 50)}..."
                                      : template.prompt,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }
}