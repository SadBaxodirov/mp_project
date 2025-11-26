class Test {
  final int id;
  final String name;
  final String description;
  final String? pdf_link;
  final String? code;
  final int? category;

  Test({
    required this.id,
    required this.name,
    required this.description,
    required this.pdf_link,
    required this.code,
    required this.category,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      pdf_link: json['pdf_link'],
      code: json['code'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'pdf_link': pdf_link,
      'code': code,
      'category': category,
    };
  }
}
