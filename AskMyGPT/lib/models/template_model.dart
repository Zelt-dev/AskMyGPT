class TemplateModel {
  final String name;
  final String prompt;

  TemplateModel({required this.name, required this.prompt});

  Map<String, dynamic> toJson() => {"name": name, "prompt": prompt};

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(name: json["name"], prompt: json["prompt"]);
  }
}