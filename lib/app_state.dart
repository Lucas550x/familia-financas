import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  static const _profilesKey = 'profiles_v2';
  static const _billsKey = 'bills_v2';
  static const _incomesKey = 'incomes_v2';
  static const _goalsKey = 'goals_v2';

  List<FamilyProfile> profiles = [];
  List<Bill> bills = [];
  List<Income> incomes = [];
  List<Goal> goals = [];

  String themeMode = 'system';
  bool soundEnabled = true;
  bool updateChecks = true;
  double monthlyBudget = 0;
  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedProfiles = _tryDecodeList(
      prefs.getString(_profilesKey),
      FamilyProfile.fromJson,
    );
    final storedBills = _tryDecodeList(
      prefs.getString(_billsKey),
      Bill.fromJson,
    );
    final storedIncomes = _tryDecodeList(
      prefs.getString(_incomesKey),
      Income.fromJson,
    );
    final storedGoals = _tryDecodeList(
      prefs.getString(_goalsKey),
      Goal.fromJson,
    );

    // A bad value in one preference must not erase the other collections.
    final hasCorruptedData =
        storedProfiles == null ||
        storedBills == null ||
        storedIncomes == null ||
        storedGoals == null;
    profiles = storedProfiles ?? [];
    bills = storedBills ?? [];
    incomes = storedIncomes ?? [];
    goals = storedGoals ?? [];

    themeMode = prefs.getString('themeMode') ?? 'system';
    soundEnabled = prefs.getBool('soundEnabled') ?? true;
    updateChecks = prefs.getBool('updateChecks') ?? true;
    monthlyBudget = prefs.getDouble('monthlyBudget') ?? 0;

    if (profiles.isEmpty) {
      profiles = [
        FamilyProfile(id: 'lucas', name: 'Lucas', emoji: '👨'),
        FamilyProfile(id: 'esposa', name: 'Esposa', emoji: '👩'),
      ];
    }
    loaded = true;
    notifyListeners();
    if (!hasCorruptedData) await save();
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => factory(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<T>? _tryDecodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) factory,
  ) {
    try {
      return _decodeList(raw, factory);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  List<T> _decodeBackupList<T>(
    Object? value,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (value == null) return [];
    if (value is! List) throw const FormatException('Lista de backup inválida.');
    try {
      return value.map((item) {
        if (item is! Map) {
          throw const FormatException('Item de backup inválido.');
        }
        return factory(Map<String, dynamic>.from(item));
      }).toList();
    } on TypeError {
      throw const FormatException('Item de backup inválido.');
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_profilesKey, jsonEncode(profiles.map((e) => e.toJson()).toList())),
      prefs.setString(_billsKey, jsonEncode(bills.map((e) => e.toJson()).toList())),
      prefs.setString(_incomesKey, jsonEncode(incomes.map((e) => e.toJson()).toList())),
      prefs.setString(_goalsKey, jsonEncode(goals.map((e) => e.toJson()).toList())),
      prefs.setString('themeMode', themeMode),
      prefs.setBool('soundEnabled', soundEnabled),
      prefs.setBool('updateChecks', updateChecks),
      prefs.setDouble('monthlyBudget', monthlyBudget),
    ]);
  }

  List<Bill> billsFor(String month) => bills.where((e) => e.appliesTo(month)).toList();
  List<Income> incomesFor(String month) => incomes.where((e) => e.appliesTo(month)).toList();

  double totalBills(String month) => billsFor(month).fold(0, (sum, e) => sum + e.amount);
  double totalPaid(String month) => billsFor(month).where((e) => e.isPaid(month)).fold(0, (sum, e) => sum + e.amount);
  double totalIncome(String month) => incomesFor(month).fold(0, (sum, e) => sum + e.amount);

  FamilyProfile? profileById(String? id) {
    if (id == null) return null;
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  Future<void> addBill(Bill bill) async { bills.add(bill); notifyListeners(); await save(); }
  Future<void> updateBill(Bill bill) async { notifyListeners(); await save(); }
  Future<void> deleteBill(Bill bill) async { bills.removeWhere((e) => e.id == bill.id); notifyListeners(); await save(); }

  Future<void> setBillPaid(Bill bill, String month, String? profileId) async {
    if (profileId == null) {
      bill.paidByMonth.remove(month);
    } else {
      bill.paidByMonth[month] = profileId;
    }
    notifyListeners();
    await save();
  }

  Future<void> addIncome(Income income) async { incomes.add(income); notifyListeners(); await save(); }
  Future<void> deleteIncome(Income income) async { incomes.removeWhere((e) => e.id == income.id); notifyListeners(); await save(); }

  Future<void> addProfile(FamilyProfile profile) async { profiles.add(profile); notifyListeners(); await save(); }
  Future<void> deleteProfile(FamilyProfile profile) async {
    if (profiles.length <= 1) return;
    profiles.removeWhere((e) => e.id == profile.id);
    notifyListeners();
    await save();
  }

  Future<void> addGoal(Goal goal) async { goals.add(goal); notifyListeners(); await save(); }
  Future<void> deleteGoal(Goal goal) async { goals.removeWhere((e) => e.id == goal.id); notifyListeners(); await save(); }
  Future<void> contributeGoal(Goal goal, double value) async {
    goal.saved = (goal.saved + value).clamp(0, double.infinity).toDouble();
    notifyListeners();
    await save();
  }

  Future<void> setTheme(String value) async { themeMode = value; notifyListeners(); await save(); }
  Future<void> setSound(bool value) async { soundEnabled = value; notifyListeners(); await save(); }
  Future<void> setUpdateChecks(bool value) async { updateChecks = value; notifyListeners(); await save(); }
  Future<void> setMonthlyBudget(double value) async { monthlyBudget = value; notifyListeners(); await save(); }

  String backup() => encodeBackup(
        profiles: profiles,
        bills: bills,
        incomes: incomes,
        goals: goals,
        themeMode: themeMode,
        soundEnabled: soundEnabled,
        updateChecks: updateChecks,
        monthlyBudget: monthlyBudget,
      );

  Future<void> restore(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Backup inválido.');
    final data = Map<String, dynamic>.from(decoded);

    // Parse every value first so an invalid backup cannot partially replace data.
    var restoredProfiles = _decodeBackupList(
      data['profiles'],
      FamilyProfile.fromJson,
    );
    final restoredBills = _decodeBackupList(data['bills'], Bill.fromJson);
    final restoredIncomes = _decodeBackupList(data['incomes'], Income.fromJson);
    final restoredGoals = _decodeBackupList(data['goals'], Goal.fromJson);
    final restoredThemeMode = (data['themeMode'] as String?) ?? themeMode;
    final restoredSoundEnabled = (data['soundEnabled'] as bool?) ?? soundEnabled;
    final restoredUpdateChecks = (data['updateChecks'] as bool?) ?? updateChecks;
    final restoredMonthlyBudget =
        (data['monthlyBudget'] as num?)?.toDouble() ?? monthlyBudget;
    if (restoredProfiles.isEmpty) {
      restoredProfiles = [FamilyProfile(id: makeId(), name: 'Perfil', emoji: '👤')];
    }
    profiles = restoredProfiles;
    bills = restoredBills;
    incomes = restoredIncomes;
    goals = restoredGoals;
    themeMode = restoredThemeMode;
    soundEnabled = restoredSoundEnabled;
    updateChecks = restoredUpdateChecks;
    monthlyBudget = restoredMonthlyBudget;
    notifyListeners();
    await save();
  }
}
