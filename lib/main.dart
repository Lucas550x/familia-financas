import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'auth_gate.dart';
import 'models.dart';
import 'supabase_config.dart';
import 'update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const FamiliaFinancasApp());
}

class FamiliaFinancasApp extends StatefulWidget {
  const FamiliaFinancasApp({super.key});

  @override
  State<FamiliaFinancasApp> createState() => _FamiliaFinancasAppState();
}

class _FamiliaFinancasAppState extends State<FamiliaFinancasApp> {
  final AppState state = AppState();

  @override
  void initState() {
    super.initState();
    state.load();
  }

  ThemeMode _mode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const seed = Color(0xFF6C63FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: dark ? const Color(0xFF111319) : const Color(0xFFF8F9FD),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: dark ? const Color(0xFF191C24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF20232C) : const Color(0xFFF1F3F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: dark ? const Color(0xFF151820) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Família Finanças',
          themeMode: _mode(state.themeMode),
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: state.loaded ? AuthGate(state: state, homeBuilder: () => HomeShell(state: state)) : const _Splash(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomeShell extends StatefulWidget {
  final AppState state;
  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  AppUpdateInfo? availableUpdate;
  bool checkingUpdate = false;
  bool alertedDue = false;

  AppState get state => widget.state;
  String get selectedKey => monthKey(selectedMonth);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDueAlerts();
      if (state.updateChecks) _checkUpdate(silent: true);
    });
  }

  void _sound() {
    if (state.soundEnabled) SystemSound.play(SystemSoundType.alert);
  }

  void _checkDueAlerts() {
    if (alertedDue || !mounted) return;
    final today = DateTime.now();
    final current = monthKey(today);
    final urgent = state.billsFor(current).where((bill) => !bill.isPaid(current) && bill.dueDay <= today.day).length;
    if (urgent > 0) {
      alertedDue = true;
      _sound();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(urgent == 1 ? 'Você tem 1 conta vencendo ou vencida.' : 'Você tem $urgent contas vencendo ou vencidas.'),
        action: SnackBarAction(label: 'Ver', onPressed: () => setState(() => index = 1)),
      ));
    }
  }

  Future<void> _checkUpdate({bool silent = false}) async {
    if (checkingUpdate) return;
    setState(() => checkingUpdate = true);
    try {
      final info = await UpdateService().check();
      if (!mounted) return;
      setState(() => availableUpdate = info);
      if (info != null) {
        await _showUpdate(info);
      } else if (info == null && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seu aplicativo já está atualizado.')));
      }
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível verificar atualizações agora.')));
      }
    } finally {
      if (mounted) setState(() => checkingUpdate = false);
    }
  }

  Future<void> _showUpdate(AppUpdateInfo info) async {
    _sound();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.system_update_alt_rounded), SizedBox(width: 10), Text('Atualização disponível')]),
        content: Text('Existe uma nova versão do Família Finanças (build ${info.build}).\n\nToque em Atualizar para baixar o APK mais recente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Depois')),
          FilledButton.icon(
            onPressed: () async {
              final url = info.downloadUrl.isNotEmpty ? info.downloadUrl : info.pageUrl;
              if (url.isNotEmpty) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _previousMonth() => setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1));
  void _nextMonth() => setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final screens = [
          DashboardScreen(state: state, month: selectedMonth, onPrevious: _previousMonth, onNext: _nextMonth, update: availableUpdate, onUpdate: () => availableUpdate == null ? _checkUpdate() : _showUpdate(availableUpdate!)),
          BillsScreen(state: state, month: selectedMonth, onPrevious: _previousMonth, onNext: _nextMonth),
          IncomeScreen(state: state, month: selectedMonth),
          ReportsScreen(state: state, month: selectedMonth),
          MoreScreen(state: state, checkingUpdate: checkingUpdate, onCheckUpdate: () => _checkUpdate()),
        ];

        return Scaffold(
          body: SafeArea(child: IndexedStack(index: index, children: screens)),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Início'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Contas'),
              NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings_rounded), label: 'Entradas'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Relatórios'),
              NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Mais'),
            ],
          ),
        );
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final AppUpdateInfo? update;
  final VoidCallback onUpdate;

  const DashboardScreen({super.key, required this.state, required this.month, required this.onPrevious, required this.onNext, required this.update, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final key = monthKey(month);
    final bills = state.billsFor(key);
    final income = state.totalIncome(key);
    final expenses = state.totalBills(key);
    final paid = state.totalPaid(key);
    final remaining = expenses - paid;
    final balance = income - expenses;
    final monthNow = key == monthKey(DateTime.now());
    final urgent = monthNow ? bills.where((e) => !e.isPaid(key) && e.dueDay <= DateTime.now().day).length : 0;
    final sorted = [...bills]..sort((a, b) => a.dueDay.compareTo(b.dueDay));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Row(
          children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Família Finanças', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('Seu dinheiro, sem complicação', style: TextStyle(fontSize: 12, color: Colors.grey))])),
            IconButton.filledTonal(onPressed: onUpdate, icon: Badge(isLabelVisible: update != null, child: const Icon(Icons.notifications_none_rounded))),
          ],
        ),
        const SizedBox(height: 18),
        MonthSelector(month: month, onPrevious: onPrevious, onNext: onNext),
        if (update != null) ...[
          const SizedBox(height: 14),
          _UpdateBanner(buildNumber: update!.build, onTap: onUpdate),
        ],
        if (urgent > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer), const SizedBox(width: 10), Expanded(child: Text('$urgent ${urgent == 1 ? 'conta precisa' : 'contas precisam'} da sua atenção hoje.', style: const TextStyle(fontWeight: FontWeight.w700)))]),
          ),
        ],
        const SizedBox(height: 16),
        _HeroBalance(balance: balance, income: income, expenses: expenses),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: MetricCard(icon: Icons.check_circle_outline_rounded, label: 'Já pago', value: money(paid), color: Colors.green)),
          const SizedBox(width: 10),
          Expanded(child: MetricCard(icon: Icons.schedule_rounded, label: 'Falta pagar', value: money(remaining), color: Colors.orange)),
        ]),
        if (state.monthlyBudget > 0) ...[
          const SizedBox(height: 14),
          _BudgetCard(spent: expenses, budget: state.monthlyBudget),
        ],
        const SizedBox(height: 22),
        SectionHeader(title: 'Contribuição da família', subtitle: 'Entradas e pagamentos do mês'),
        const SizedBox(height: 10),
        SizedBox(height: 110, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: state.profiles.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) {
          final p = state.profiles[i];
          final contributed = state.incomesFor(key).where((e) => e.profileId == p.id).fold<double>(0, (s, e) => s + e.amount);
          final paidBy = bills.where((e) => e.paidBy(key) == p.id).fold<double>(0, (s, e) => s + e.amount);
          return _ProfileSummary(profile: p, contributed: contributed, paid: paidBy);
        })),
        const SizedBox(height: 22),
        SectionHeader(title: 'Próximas contas', subtitle: '${bills.where((e) => !e.isPaid(key)).length} pendentes'),
        const SizedBox(height: 10),
        if (sorted.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, title: 'Nenhuma conta neste mês', text: 'Cadastre contas fixas, únicas ou parceladas.')
        else
          ...sorted.take(5).map((bill) => Padding(padding: const EdgeInsets.only(bottom: 10), child: BillTile(state: state, bill: bill, month: month))),
        const SizedBox(height: 18),
        SectionHeader(title: 'Metas', subtitle: state.goals.isEmpty ? 'Crie sua primeira meta' : '${state.goals.length} em andamento'),
        const SizedBox(height: 10),
        if (state.goals.isEmpty)
          const EmptyState(icon: Icons.flag_outlined, title: 'Planeje junto', text: 'Viagem, reserva de emergência, reforma ou qualquer objetivo da família.')
        else
          ...state.goals.take(3).map((goal) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GoalTile(state: state, goal: goal))),
      ],
    );
  }
}

class BillsScreen extends StatefulWidget {
  final AppState state;
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const BillsScreen({super.key, required this.state, required this.month, required this.onPrevious, required this.onNext});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String filter = 'Todas';

  @override
  Widget build(BuildContext context) {
    final key = monthKey(widget.month);
    var bills = widget.state.billsFor(key);
    if (filter == 'Pendentes') bills = bills.where((e) => !e.isPaid(key)).toList();
    if (filter == 'Pagas') bills = bills.where((e) => e.isPaid(key)).toList();
    bills.sort((a, b) => a.dueDay.compareTo(b.dueDay));
    return Scaffold(
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), children: [
        PageTitle(title: 'Contas', subtitle: 'Controle vencimentos e recorrências', action: IconButton.filled(onPressed: () => showBillForm(context, widget.state, widget.month), icon: const Icon(Icons.add_rounded))),
        const SizedBox(height: 16),
        MonthSelector(month: widget.month, onPrevious: widget.onPrevious, onNext: widget.onNext),
        const SizedBox(height: 14),
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'Todas', label: Text('Todas')), ButtonSegment(value: 'Pendentes', label: Text('Pendentes')), ButtonSegment(value: 'Pagas', label: Text('Pagas'))], selected: {filter}, onSelectionChanged: (value) => setState(() => filter = value.first)),
        const SizedBox(height: 16),
        if (bills.isEmpty)
          const EmptyState(icon: Icons.task_alt_rounded, title: 'Nada por aqui', text: 'Adicione uma conta ou altere o filtro.')
        else
          ...bills.map((bill) => Padding(padding: const EdgeInsets.only(bottom: 10), child: BillTile(state: widget.state, bill: bill, month: widget.month, editable: true))),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showBillForm(context, widget.state, widget.month), icon: const Icon(Icons.add_rounded), label: const Text('Nova conta')),
    );
  }
}

class IncomeScreen extends StatelessWidget {
  final AppState state;
  final DateTime month;
  const IncomeScreen({super.key, required this.state, required this.month});

  @override
  Widget build(BuildContext context) {
    final key = monthKey(month);
    final items = state.incomesFor(key);
    return Scaffold(
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), children: [
        PageTitle(title: 'Entradas', subtitle: 'Salários e rendas da família', action: IconButton.filled(onPressed: () => showIncomeForm(context, state, month), icon: const Icon(Icons.add_rounded))),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]), borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total de entradas', style: TextStyle(color: Colors.white70)), const SizedBox(height: 5), Text(money(state.totalIncome(key)), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(monthName(month), style: const TextStyle(color: Colors.white70))]),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const EmptyState(icon: Icons.savings_outlined, title: 'Nenhuma entrada cadastrada', text: 'Adicione salários, comissões, vendas ou outras rendas.')
        else
          ...items.map((income) {
            final p = state.profileById(income.profileId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(child: Text(p?.emoji ?? '💰')),
                title: Text(income.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${p?.name ?? 'Perfil'} • ${income.recurrence == 'fixed' ? 'Mensal' : 'Única'}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(income.amount), style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)), PopupMenuButton<String>(onSelected: (value) { if (value == 'delete') confirmDelete(context, 'Excluir entrada?', () => state.deleteIncome(income)); }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Excluir'))])]),
              )),
            );
          }),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showIncomeForm(context, state, month), icon: const Icon(Icons.add_rounded), label: const Text('Nova entrada')),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final AppState state;
  final DateTime month;
  const ReportsScreen({super.key, required this.state, required this.month});

  @override
  Widget build(BuildContext context) {
    final key = monthKey(month);
    final bills = state.billsFor(key);
    final total = state.totalBills(key);
    final categories = <String, double>{};
    for (final bill in bills) {
      categories[bill.category] = (categories[bill.category] ?? 0) + bill.amount;
    }
    final sortedCategories = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final income = state.totalIncome(key);
    return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
      const PageTitle(title: 'Relatórios', subtitle: 'Entenda para onde o dinheiro está indo'),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: MetricCard(icon: Icons.trending_up_rounded, label: 'Entradas', value: money(income), color: Colors.green)), const SizedBox(width: 10), Expanded(child: MetricCard(icon: Icons.trending_down_rounded, label: 'Despesas', value: money(total), color: Colors.redAccent))]),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Despesas por categoria', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (sortedCategories.isEmpty) const Text('Sem dados neste mês.') else ...sortedCategories.map((entry) {
          final ratio = total == 0 ? 0.0 : entry.value / total;
          return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600))), Text(money(entry.value), style: const TextStyle(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: ratio, minHeight: 9)),
          ]));
        }),
      ]))),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quem colocou e quem pagou', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ...state.profiles.map((p) {
          final contributed = state.incomesFor(key).where((e) => e.profileId == p.id).fold<double>(0, (s, e) => s + e.amount);
          final paid = bills.where((e) => e.paidBy(key) == p.id).fold<double>(0, (s, e) => s + e.amount);
          return ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text(p.emoji)), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Entrou ${money(contributed)}'), trailing: Text('Pagou\n${money(paid)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)));
        }),
      ]))),
      const SizedBox(height: 18),
      _ProjectionCard(state: state, month: month),
    ]);
  }
}

class MoreScreen extends StatelessWidget {
  final AppState state;
  final bool checkingUpdate;
  final VoidCallback onCheckUpdate;
  const MoreScreen({super.key, required this.state, required this.checkingUpdate, required this.onCheckUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
      const PageTitle(title: 'Mais', subtitle: 'Perfis, metas e configurações'),
      const SizedBox(height: 18),
      _MenuCard(icon: Icons.people_alt_outlined, title: 'Perfis da família', subtitle: '${state.profiles.length} perfis', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilesPage(state: state)))),
      const SizedBox(height: 10),
      _MenuCard(icon: Icons.groups_2_outlined, title: 'Minha família', subtitle: 'Convide pessoas para compartilhar', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPage()))),
      const SizedBox(height: 10),
      _MenuCard(icon: Icons.flag_outlined, title: 'Metas', subtitle: '${state.goals.length} metas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalsPage(state: state)))),
      const SizedBox(height: 10),
      _MenuCard(icon: Icons.settings_outlined, title: 'Configurações', subtitle: 'Tema, sons, orçamento e backup', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(state: state, checkingUpdate: checkingUpdate, onCheckUpdate: onCheckUpdate)))),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Versão do aplicativo', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Família Finanças 2.0 • build ${UpdateService.currentBuild}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: checkingUpdate ? null : onCheckUpdate, icon: checkingUpdate ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.system_update_rounded), label: const Text('Verificar atualização')),
      ]))),
    ]);
  }
}

class ProfilesPage extends StatelessWidget {
  final AppState state;
  const ProfilesPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: state, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Perfis da família')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        ...state.profiles.map((p) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), leading: CircleAvatar(child: Text(p.emoji)), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Membro da família'), trailing: state.profiles.length > 1 ? IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => confirmDelete(context, 'Excluir ${p.name}?', () => state.deleteProfile(p))) : null)))),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showProfileForm(context, state), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Adicionar perfil')),
    ));
  }
}

class GoalsPage extends StatelessWidget {
  final AppState state;
  const GoalsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: state, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Metas da família')),
      body: ListView(padding: const EdgeInsets.all(18), children: state.goals.isEmpty ? [const EmptyState(icon: Icons.flag_outlined, title: 'Nenhuma meta ainda', text: 'Crie um objetivo e acompanhe o progresso juntos.')] : state.goals.map((g) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GoalTile(state: state, goal: g, removable: true))).toList()),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showGoalForm(context, state), icon: const Icon(Icons.add_rounded), label: const Text('Nova meta')),
    ));
  }
}

class SettingsPage extends StatefulWidget {
  final AppState state;
  final bool checkingUpdate;
  final VoidCallback onCheckUpdate;
  const SettingsPage({super.key, required this.state, required this.checkingUpdate, required this.onCheckUpdate});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AnimatedBuilder(animation: state, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const SectionHeader(title: 'Aparência', subtitle: 'Escolha como o aplicativo deve aparecer'),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'system', icon: Icon(Icons.phone_android_rounded), label: Text('Auto')), ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_outlined), label: Text('Claro')), ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro'))], selected: {state.themeMode}, onSelectionChanged: (v) => state.setTheme(v.first)))),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Alertas', subtitle: 'Controle sons e atualizações'),
        const SizedBox(height: 10),
        Card(child: Column(children: [
          SwitchListTile(title: const Text('Sons do aplicativo', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Tocar alerta em avisos importantes'), value: state.soundEnabled, onChanged: state.setSound),
          const Divider(height: 1),
          SwitchListTile(title: const Text('Buscar atualizações', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Verificar nova versão ao abrir'), value: state.updateChecks, onChanged: state.setUpdateChecks),
          const Divider(height: 1),
          ListTile(title: const Text('Verificar agora', style: TextStyle(fontWeight: FontWeight.w700)), trailing: widget.checkingUpdate ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right_rounded), onTap: widget.checkingUpdate ? null : widget.onCheckUpdate),
        ])),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Orçamento mensal', subtitle: 'Um limite opcional para acompanhar os gastos'),
        const SizedBox(height: 10),
        Card(child: ListTile(title: Text(state.monthlyBudget <= 0 ? 'Sem limite definido' : money(state.monthlyBudget), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Toque para definir'), trailing: const Icon(Icons.edit_outlined), onTap: () => showBudgetDialog(context, state))),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Backup', subtitle: 'Copie seus dados para guardar ou restaurar'),
        const SizedBox(height: 10),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.copy_all_outlined), title: const Text('Copiar backup', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Copia os dados em formato seguro de texto'), onTap: () async { await Clipboard.setData(ClipboardData(text: state.backup())); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup copiado. Guarde esse texto em local seguro.'))); }),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.restore_rounded), title: const Text('Restaurar backup', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Substitui os dados atuais'), onTap: () => showRestoreDialog(context, state)),
        ])),
      ]),
    ));
  }
}

class BillTile extends StatelessWidget {
  final AppState state;
  final Bill bill;
  final DateTime month;
  final bool editable;
  const BillTile({super.key, required this.state, required this.bill, required this.month, this.editable = false});

  @override
  Widget build(BuildContext context) {
    final key = monthKey(month);
    final paid = bill.isPaid(key);
    final profile = state.profileById(bill.paidBy(key));
    final now = DateTime.now();
    final current = key == monthKey(now);
    final overdue = current && !paid && bill.dueDay < now.day;
    final dueToday = current && !paid && bill.dueDay == now.day;
    final installment = bill.installmentNumber(key);
    final accent = paid ? Colors.green : overdue ? Colors.redAccent : dueToday ? Colors.orange : Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => showPaymentSheet(context, state, bill, key),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: Icon(paid ? Icons.check_rounded : categoryIcon(bill.category), color: accent)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bill.title, style: TextStyle(fontWeight: FontWeight.w800, decoration: paid ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 3),
              Text(paid ? 'Pago por ${profile?.name ?? 'perfil'}' : overdue ? 'Atrasada • venceu dia ${bill.dueDay}' : dueToday ? 'Vence hoje' : 'Vence dia ${bill.dueDay}${installment != null ? ' • $installment/${bill.durationMonths}' : ''}', style: TextStyle(fontSize: 12, color: paid ? Colors.green : overdue ? Colors.redAccent : Colors.grey, fontWeight: overdue || dueToday ? FontWeight.w700 : FontWeight.w500)),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(bill.amount), style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(bill.category, style: const TextStyle(fontSize: 11, color: Colors.grey))]),
            if (editable) PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') showBillForm(context, state, month, bill: bill); if (v == 'delete') confirmDelete(context, 'Excluir ${bill.title}?', () => state.deleteBill(bill)); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))]),
          ]),
        ),
      ),
    );
  }
}

class GoalTile extends StatelessWidget {
  final AppState state;
  final Goal goal;
  final bool removable;
  const GoalTile({super.key, required this.state, required this.goal, this.removable = false});

  @override
  Widget build(BuildContext context) {
    final progress = goal.target <= 0 ? 0.0 : (goal.saved / goal.target).clamp(0, 1).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(goal.emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 10), Expanded(child: Text(goal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), if (removable) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => confirmDelete(context, 'Excluir meta?', () => state.deleteGoal(goal)))]),
      const SizedBox(height: 10),
      LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(20)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: Text('${money(goal.saved)} de ${money(goal.target)}', style: const TextStyle(fontSize: 12, color: Colors.grey))), Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 8), IconButton.filledTonal(icon: const Icon(Icons.add_rounded), onPressed: () => showGoalContribution(context, state, goal))]),
    ])));
  }
}

class MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const MonthSelector({super.key, required this.month, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18)), child: Row(children: [IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded)), Expanded(child: Column(children: [Text(monthName(month), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text('${month.year}', style: const TextStyle(fontSize: 11, color: Colors.grey))])), IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded))]));
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const MetricCard({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19, color: color)), const SizedBox(height: 10), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 3), FittedBox(child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))])));
}

class PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const PageTitle({super.key, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: Colors.grey))])), if (action != null) action!]);
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionHeader({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const EmptyState({super.key, required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12))])));
}

class _HeroBalance extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  const _HeroBalance({required this.balance, required this.income, required this.expenses});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: .18), blurRadius: 28, offset: const Offset(0, 12))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sobra prevista', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)), const SizedBox(height: 4), FittedBox(child: Text(money(balance), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))), const SizedBox(height: 18), Row(children: [Expanded(child: _HeroMini(label: 'Entradas', value: money(income), icon: Icons.south_west_rounded)), Container(width: 1, height: 38, color: Colors.white24), const SizedBox(width: 14), Expanded(child: _HeroMini(label: 'Contas', value: money(expenses), icon: Icons.north_east_rounded))])]),
  );
}

class _HeroMini extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _HeroMini({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                FittedBox(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ProfileSummary extends StatelessWidget {
  final FamilyProfile profile;
  final double contributed, paid;
  const _ProfileSummary({required this.profile, required this.contributed, required this.paid});
  @override
  Widget build(BuildContext context) => SizedBox(width: 190, child: Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [CircleAvatar(radius: 24, child: Text(profile.emoji, style: const TextStyle(fontSize: 22))), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('Entrou ${money(contributed)}', style: const TextStyle(fontSize: 10, color: Colors.grey)), Text('Pagou ${money(paid)}', style: const TextStyle(fontSize: 10, color: Colors.grey))]))]))));
}

class _BudgetCard extends StatelessWidget {
  final double spent, budget;
  const _BudgetCard({required this.spent, required this.budget});
  @override
  Widget build(BuildContext context) {
    final ratio = budget <= 0 ? 0.0 : (spent / budget).clamp(0, 1.0).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Text('Orçamento do mês', style: TextStyle(fontWeight: FontWeight.w800))), Text('${(ratio * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900))]), const SizedBox(height: 9), LinearProgressIndicator(value: ratio, minHeight: 9, borderRadius: BorderRadius.circular(20)), const SizedBox(height: 7), Text('${money(spent)} de ${money(budget)}', style: const TextStyle(fontSize: 11, color: Colors.grey))])));
  }
}

class _UpdateBanner extends StatelessWidget {
  final int buildNumber;
  final VoidCallback onTap;
  const _UpdateBanner({required this.buildNumber, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(Icons.system_update_alt_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer), const SizedBox(width: 10), Expanded(child: Text('Nova versão disponível • build $buildNumber', style: const TextStyle(fontWeight: FontWeight.w800))), const Icon(Icons.chevron_right_rounded)]))));
}

class _ProjectionCard extends StatelessWidget {
  final AppState state;
  final DateTime month;
  const _ProjectionCard({required this.state, required this.month});
  @override
  Widget build(BuildContext context) {
    final next = DateTime(month.year, month.month + 1);
    final key = monthKey(next);
    final income = state.totalIncome(key);
    final expenses = state.totalBills(key);
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Próximo mês', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('Com base nas recorrências cadastradas para ${monthName(next)}.', style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 14), Row(children: [Expanded(child: Text('Entradas\n${money(income)}', style: const TextStyle(fontWeight: FontWeight.w700))), Expanded(child: Text('Contas\n${money(expenses)}', style: const TextStyle(fontWeight: FontWeight.w700))), Expanded(child: Text('Previsão\n${money(income - expenses)}', style: const TextStyle(fontWeight: FontWeight.w900)))])])));
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap));
}

Future<void> showPaymentSheet(BuildContext context, AppState state, Bill bill, String month) async {
  if (bill.isPaid(month)) {
    final result = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 18), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Conta paga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('${bill.title} • ${money(bill.amount)}'), const SizedBox(height: 18), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.pop(context, 'undo'), icon: const Icon(Icons.undo_rounded), label: const Text('Marcar como pendente')))]))));
    if (result == 'undo') await state.setBillPaid(bill, month, null);
    return;
  }
  String selected = state.profiles.first.id;
  final result = await showModalBottomSheet<String>(context: context, showDragHandle: true, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setLocal) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Registrar pagamento', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('${bill.title} • ${money(bill.amount)}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 16), const Text('Quem pagou?', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), ...state.profiles.map((p) => RadioListTile<String>(value: p.id, groupValue: selected, title: Text('${p.emoji}  ${p.name}'), onChanged: (v) { if (v != null) setLocal(() => selected = v); })), const SizedBox(height: 8), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context, selected), icon: const Icon(Icons.check_rounded), label: const Text('Confirmar pagamento'))),
  ])))));
  if (result != null) {
    await state.setBillPaid(bill, month, result);
    if (state.soundEnabled) SystemSound.play(SystemSoundType.click);
  }
}

Future<void> showBillForm(BuildContext context, AppState state, DateTime month, {Bill? bill}) async {
  final title = TextEditingController(text: bill?.title ?? '');
  final amount = TextEditingController(text: bill == null ? '' : bill.amount.toStringAsFixed(2).replaceAll('.', ','));
  final day = TextEditingController(text: (bill?.dueDay ?? DateTime.now().day).toString());
  final duration = TextEditingController(text: bill?.durationMonths?.toString() ?? '');
  final notes = TextEditingController(text: bill?.notes ?? '');
  String category = bill?.category ?? 'Casa';
  String recurrence = bill?.recurrence ?? 'once';
  final formKey = GlobalKey<FormState>();
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setLocal) {
    return Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(bill == null ? 'Nova conta' : 'Editar conta', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 16),
      TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Nome da conta', prefixIcon: Icon(Icons.receipt_long_outlined)), validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '), validator: (v) => parseMoney(v) == null ? 'Valor inválido' : null)), const SizedBox(width: 10), Expanded(child: TextFormField(controller: day, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dia vencimento'), validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 1 || n > 31 ? 'Dia inválido' : null; }))]), const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Categoria'), items: billCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { if (v != null) setLocal(() => category = v); }), const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: recurrence, decoration: const InputDecoration(labelText: 'Repetição'), items: const [DropdownMenuItem(value: 'once', child: Text('Somente este mês')), DropdownMenuItem(value: 'fixed', child: Text('Fixa todo mês')), DropdownMenuItem(value: 'installments', child: Text('Por quantidade de meses'))], onChanged: (v) { if (v != null) setLocal(() => recurrence = v); }),
      if (recurrence == 'installments') ...[const SizedBox(height: 10), TextFormField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade de meses', prefixIcon: Icon(Icons.calendar_month_outlined)), validator: (v) { if (recurrence != 'installments') return null; final n = int.tryParse(v ?? ''); return n == null || n <= 0 ? 'Informe quantos meses' : null; })],
      const SizedBox(height: 10), TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Observação (opcional)', prefixIcon: Icon(Icons.notes_rounded))), const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () async { if (!(formKey.currentState?.validate() ?? false)) return; final parsed = parseMoney(amount.text)!; final due = int.parse(day.text); if (bill == null) { await state.addBill(Bill(id: makeId(), title: title.text.trim(), amount: parsed, dueDay: due, category: category, recurrence: recurrence, startMonth: monthKey(month), durationMonths: recurrence == 'installments' ? int.parse(duration.text) : null, notes: notes.text.trim())); } else { bill.title = title.text.trim(); bill.amount = parsed; bill.dueDay = due; bill.category = category; bill.recurrence = recurrence; bill.durationMonths = recurrence == 'installments' ? int.parse(duration.text) : null; bill.notes = notes.text.trim(); await state.updateBill(bill); } if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.save_rounded), label: Text(bill == null ? 'Adicionar conta' : 'Salvar alterações'))),
    ]))));
  }));
}

Future<void> showIncomeForm(BuildContext context, AppState state, DateTime month) async {
  if (state.profiles.isEmpty) return;
  final title = TextEditingController();
  final amount = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String profile = state.profiles.first.id;
  String recurrence = 'once';
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setLocal) => Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Nova entrada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 16),
    TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Descrição', prefixIcon: Icon(Icons.edit_outlined)), validator: (v) => v == null || v.trim().isEmpty ? 'Informe uma descrição' : null), const SizedBox(height: 10),
    TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '), validator: (v) => parseMoney(v) == null ? 'Valor inválido' : null), const SizedBox(height: 10),
    DropdownButtonFormField<String>(initialValue: profile, decoration: const InputDecoration(labelText: 'De quem é essa entrada?'), items: state.profiles.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.emoji}  ${p.name}'))).toList(), onChanged: (v) { if (v != null) setLocal(() => profile = v); }), const SizedBox(height: 10),
    DropdownButtonFormField<String>(initialValue: recurrence, decoration: const InputDecoration(labelText: 'Repetição'), items: const [DropdownMenuItem(value: 'once', child: Text('Somente este mês')), DropdownMenuItem(value: 'fixed', child: Text('Todo mês'))], onChanged: (v) { if (v != null) setLocal(() => recurrence = v); }), const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () async { if (!(formKey.currentState?.validate() ?? false)) return; await state.addIncome(Income(id: makeId(), title: title.text.trim(), amount: parseMoney(amount.text)!, profileId: profile, category: 'Renda', recurrence: recurrence, startMonth: monthKey(month))); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.add_rounded), label: const Text('Adicionar entrada'))),
  ])))));
}

Future<void> showProfileForm(BuildContext context, AppState state) async {
  final name = TextEditingController();
  final emoji = TextEditingController(text: '👤');
  await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Novo perfil'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')), const SizedBox(height: 10), TextField(controller: emoji, decoration: const InputDecoration(labelText: 'Emoji'), maxLength: 3)]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) return; await state.addProfile(FamilyProfile(id: makeId(), name: name.text.trim(), emoji: emoji.text.trim().isEmpty ? '👤' : emoji.text.trim())); if (context.mounted) Navigator.pop(context); }, child: const Text('Adicionar'))]));
}

Future<void> showGoalForm(BuildContext context, AppState state) async {
  final name = TextEditingController();
  final target = TextEditingController();
  final emoji = TextEditingController(text: '🎯');
  await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Nova meta'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Objetivo')), const SizedBox(height: 10), TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor da meta', prefixText: 'R\$ ')), const SizedBox(height: 10), TextField(controller: emoji, decoration: const InputDecoration(labelText: 'Emoji'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () async { final value = parseMoney(target.text); if (name.text.trim().isEmpty || value == null || value <= 0) return; await state.addGoal(Goal(id: makeId(), title: name.text.trim(), target: value, saved: 0, emoji: emoji.text.trim().isEmpty ? '🎯' : emoji.text.trim())); if (context.mounted) Navigator.pop(context); }, child: const Text('Criar'))]));
}

Future<void> showGoalContribution(BuildContext context, AppState state, Goal goal) async {
  final amount = TextEditingController();
  await showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text('Guardar para ${goal.title}'), content: TextField(controller: amount, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ ')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () async { final value = parseMoney(amount.text); if (value == null || value <= 0) return; await state.contributeGoal(goal, value); if (context.mounted) Navigator.pop(context); }, child: const Text('Adicionar'))]));
}

Future<void> showBudgetDialog(BuildContext context, AppState state) async {
  final controller = TextEditingController(text: state.monthlyBudget > 0 ? state.monthlyBudget.toStringAsFixed(2).replaceAll('.', ',') : '');
  await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Orçamento mensal'), content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Limite', prefixText: 'R\$ ')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), TextButton(onPressed: () async { await state.setMonthlyBudget(0); if (context.mounted) Navigator.pop(context); }, child: const Text('Remover limite')), FilledButton(onPressed: () async { final value = parseMoney(controller.text); if (value == null || value < 0) return; await state.setMonthlyBudget(value); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))]));
}

Future<void> showRestoreDialog(BuildContext context, AppState state) async {
  final controller = TextEditingController();
  await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Restaurar backup'), content: TextField(controller: controller, minLines: 4, maxLines: 8, decoration: const InputDecoration(hintText: 'Cole aqui o texto do backup')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () async { try { await state.restore(controller.text.trim()); if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restaurado com sucesso.'))); } } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup inválido.'))); } }, child: const Text('Restaurar'))]));
}

Future<void> confirmDelete(BuildContext context, String title, Future<void> Function() action) async {
  final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(title), content: const Text('Essa ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
  if (confirmed == true) await action();
}

double? parseMoney(String? text) {
  if (text == null) return null;
  var value = text.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (value.contains(',') && value.contains('.')) value = value.replaceAll('.', '').replaceAll(',', '.');
  else value = value.replaceAll(',', '.');
  return double.tryParse(value);
}

String money(double value) {
  final negative = value < 0;
  final abs = value.abs().toStringAsFixed(2).split('.');
  final digits = abs[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}R\$ ${buffer.toString()},${abs[1]}';
}

String monthName(DateTime date) {
  const months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
  return months[date.month - 1];
}

const billCategories = ['Casa', 'Alimentação', 'Transporte', 'Assinaturas', 'Saúde', 'Educação', 'Filhos', 'Lazer', 'Compras', 'Impostos', 'Outros'];

IconData categoryIcon(String category) {
  switch (category) {
    case 'Casa': return Icons.home_outlined;
    case 'Alimentação': return Icons.shopping_cart_outlined;
    case 'Transporte': return Icons.directions_car_outlined;
    case 'Assinaturas': return Icons.subscriptions_outlined;
    case 'Saúde': return Icons.medical_services_outlined;
    case 'Educação': return Icons.school_outlined;
    case 'Filhos': return Icons.child_care_outlined;
    case 'Lazer': return Icons.sports_esports_outlined;
    case 'Compras': return Icons.shopping_bag_outlined;
    case 'Impostos': return Icons.account_balance_outlined;
    default: return Icons.receipt_long_outlined;
  }
}
