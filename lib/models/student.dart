class Student {
  final String id;
  final String name;
  final String className;

  Student({required this.id, required this.name, required this.className});

  // Métodos para serialização/deserialização para SharedPreferences
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      className: json['className'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'className': className,
    };
  }
}
