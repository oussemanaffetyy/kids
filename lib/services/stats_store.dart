import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StatsStore {
  StatsStore._internal();

  static final StatsStore instance = StatsStore._internal();

  static const _key = 'game_stats_v1';

  Future<List<StatRecord>> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(StatRecord.fromJson)
        .toList();
  }

  Future<void> saveStats(List<StatRecord> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final data = stats.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<void> addStat(StatRecord record) async {
    final list = await loadStats();
    list.add(record);
    await saveStats(list);
  }

  Future<void> clearStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class StatRecord {
  final String date; // yyyy-mm-dd
  final String gameKey;
  final int durationSeconds;
  final int errors;
  final int correct;

  const StatRecord({
    required this.date,
    required this.gameKey,
    required this.durationSeconds,
    required this.errors,
    required this.correct,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'gameKey': gameKey,
        'durationSeconds': durationSeconds,
        'errors': errors,
        'correct': correct,
      };

  factory StatRecord.fromJson(Map<String, dynamic> json) {
    return StatRecord(
      date: (json['date'] ?? '').toString(),
      gameKey: (json['gameKey'] ?? '').toString(),
      durationSeconds: (json['durationSeconds'] ?? 0) as int,
      errors: (json['errors'] ?? 0) as int,
      correct: (json['correct'] ?? 0) as int,
    );
  }
}
