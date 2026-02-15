import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StudentStore {
  StudentStore._internal();

  static final StudentStore instance = StudentStore._internal();

  static const _key = 'students_list_v1';

  Future<List<Student>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Student.fromJson)
        .toList();
  }

  Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final data = students.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<bool> hasStudents() async {
    final list = await loadStudents();
    return list.isNotEmpty;
  }
}

class Student {
  final String name;
  final String birthDate;

  const Student({
    required this.name,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthDate': birthDate,
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: (json['name'] ?? '').toString(),
      birthDate: (json['birthDate'] ?? '').toString(),
    );
  }
}
