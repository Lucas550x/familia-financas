import 'dart:convert';

String monthKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

DateTime monthFromKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

int monthDistance(String from, String to) {
  final a = monthFromKey(from);
  final b = monthFromKey(to);
  return (b.year - a.year) * 12 + b.month - a.month;
}

String makeId() => DateTime.now().microsecondsSinceEpoch.toString();

class FamilyProfile {
  final String id;
  String name;
  String emoji;

  FamilyProfile({required this.id, required this.name, required this.emoji});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};

  factory FamilyProfile.fromJson(Map<String, dynamic> json) => FamilyProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: (json['emoji'] as String?) ?? '👤',
      );
}

class Bill {
  final String id;
  String title;
  double amount;
  int dueDay;
  String category;
  String recurrence; // once, fixed, installments
  String startMonth;
  int? durationMonths;
  String notes;
  Map<String, String> paidByMonth;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDay,
    required this.category,
    required this.recurrence,
    required this.startMonth,
    this.durationMonths,
    this.notes = '',
    Map<String, String>? paidByMonth,
  }) : paidByMonth = paidByMonth ?? {};

  bool appliesTo(String month) {
    final distance = monthDistance(startMonth, month);
    if (distance < 0) return false;
    if (recurrence == 'once') return distance == 0;
    if (recurrence == 'fixed') return true;
    if (recurrence == 'installments') {
      return durationMonths != null && distance < durationMonths!;
    }
    return false;
  }

  bool isPaid(String month) => paidByMonth.containsKey(month);
  String? paidBy(String month) => paidByMonth[month];

  int? installmentNumber(String month) {
    if (recurrence != 'installments' || durationMonths == null) return null;
    final distance = monthDistance(startMonth, month);
    if (distance < 0 || distance >= durationMonths!) return null;
    return distance + 1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'dueDay': dueDay,
        'category': category,
        'recurrence': recurrence,
        'startMonth': startMonth,
        'durationMonths': durationMonths,
        'notes': notes,
        'paidByMonth': paidByMonth,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        dueDay: (json['dueDay'] as num).toInt(),
        category: (json['category'] as String?) ?? 'Outros',
        recurrence: (json['recurrence'] as String?) ?? 'once',
        startMonth: json['startMonth'] as String,
        durationMonths: (json['durationMonths'] as num?)?.toInt(),
        notes: (json['notes'] as String?) ?? '',
        paidByMonth: Map<String, String>.from((json['paidByMonth'] as Map?) ?? {}),
      );
}

class Income {
  final String id;
  String title;
  double amount;
  String profileId;
  String category;
  String recurrence; // once, fixed
  String startMonth;

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.profileId,
    required this.category,
    required this.recurrence,
    required this.startMonth,
  });

  bool appliesTo(String month) {
    final distance = monthDistance(startMonth, month);
    if (distance < 0) return false;
    return recurrence == 'fixed' || distance == 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'profileId': profileId,
        'category': category,
        'recurrence': recurrence,
        'startMonth': startMonth,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        profileId: json['profileId'] as String,
        category: (json['category'] as String?) ?? 'Renda',
        recurrence: (json['recurrence'] as String?) ?? 'once',
        startMonth: json['startMonth'] as String,
      );
}

class Goal {
  final String id;
  String title;
  double target;
  double saved;
  String emoji;

  Goal({
    required this.id,
    required this.title,
    required this.target,
    required this.saved,
    required this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target': target,
        'saved': saved,
        'emoji': emoji,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        target: (json['target'] as num).toDouble(),
        saved: (json['saved'] as num).toDouble(),
        emoji: (json['emoji'] as String?) ?? '🎯',
      );
}

String encodeBackup({
  required List<FamilyProfile> profiles,
  required List<Bill> bills,
  required List<Income> incomes,
  required List<Goal> goals,
  required String themeMode,
  required bool soundEnabled,
  required bool updateChecks,
  required double monthlyBudget,
}) {
  return jsonEncode({
    'schema': 2,
    'createdAt': DateTime.now().toIso8601String(),
    'profiles': profiles.map((e) => e.toJson()).toList(),
    'bills': bills.map((e) => e.toJson()).toList(),
    'incomes': incomes.map((e) => e.toJson()).toList(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'themeMode': themeMode,
    'soundEnabled': soundEnabled,
    'updateChecks': updateChecks,
    'monthlyBudget': monthlyBudget,
  });
}
