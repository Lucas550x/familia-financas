import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class AuthGate extends StatelessWidget {
  final AppState state;
  final Widget Function() homeBuilder;

  const AuthGate({super.key, required this.state, required this.homeBuilder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? _supabase.auth.currentSession;
        if (session == null) return const AuthPage();
        return FamilyGate(state: state, user: session.user, homeBuilder: homeBuilder);
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isRegistering = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.length < 6) {
      _message('Informe um e-mail válido e uma senha com pelo menos 6 caracteres.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isRegistering) {
        await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {'display_name': _name.text.trim()},
        );
        if (mounted) {
          _message('Cadastro criado. Confirme seu e-mail e depois entre no aplicativo.');
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Não foi possível concluir agora. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 20),
                  Text('Família Finanças', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(_isRegistering ? 'Crie sua conta para compartilhar a organização financeira.' : 'Entre para acessar a sua família.', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  if (_isRegistering) ...[
                    TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Seu nome', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.alternate_email_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: true, autofillHints: _isRegistering ? const [AutofillHints.newPassword] : const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _loading ? null : _submit, child: Padding(padding: const EdgeInsets.all(14), child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isRegistering ? 'Criar conta' : 'Entrar'))),
                  TextButton(onPressed: _loading ? null : () => setState(() => _isRegistering = !_isRegistering), child: Text(_isRegistering ? 'Já tenho conta' : 'Criar uma conta')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FamilyGate extends StatefulWidget {
  final AppState state;
  final User user;
  final Widget Function() homeBuilder;

  const FamilyGate({super.key, required this.state, required this.user, required this.homeBuilder});

  @override
  State<FamilyGate> createState() => _FamilyGateState();
}

class _FamilyGateState extends State<FamilyGate> {
  late Future<bool> _hasFamily;

  @override
  void initState() {
    super.initState();
    _hasFamily = _loadFamily();
  }

  Future<bool> _loadFamily() async {
    final rows = await _supabase.from('family_members').select('family_id').eq('user_id', widget.user.id).limit(1);
    return (rows as List).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasFamily,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return _FamilyError(onRetry: () => setState(() => _hasFamily = _loadFamily()));
        if (snapshot.data == true) return widget.homeBuilder();
        return FamilySetupPage(onDone: () => setState(() => _hasFamily = _loadFamily()));
      },
    );
  }
}

class FamilySetupPage extends StatefulWidget {
  final VoidCallback onDone;

  const FamilySetupPage({super.key, required this.onDone});

  @override
  State<FamilySetupPage> createState() => _FamilySetupPageState();
}

class _FamilySetupPageState extends State<FamilySetupPage> {
  final _name = TextEditingController();
  final _inviteCode = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (_name.text.trim().isEmpty) return _message('Informe o nome da família.');
    await _run(() => _supabase.from('families').insert({'name': _name.text.trim(), 'created_by': _supabase.auth.currentUser!.id}));
  }

  Future<void> _acceptInvite() async {
    if (_inviteCode.text.trim().isEmpty) return _message('Informe o código do convite.');
    await _run(() => _supabase.rpc('accept_family_invite', params: {'p_code': _inviteCode.text.trim()}));
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      widget.onDone();
    } on PostgrestException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Não foi possível concluir agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [TextButton(onPressed: () => _supabase.auth.signOut(), child: const Text('Sair'))]),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.groups_2_rounded, size: 58),
        const SizedBox(height: 16),
        const Text('Vamos organizar a sua família', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Crie uma família ou entre com um código de convite.', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome da família', hintText: 'Ex.: Família Marques')),
        const SizedBox(height: 10),
        FilledButton(onPressed: _loading ? null : _createFamily, child: const Text('Criar minha família')),
        const Padding(padding: EdgeInsets.symmetric(vertical: 22), child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou')), Expanded(child: Divider())])),
        TextField(controller: _inviteCode, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código de convite')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: _loading ? null : _acceptInvite, child: const Text('Entrar em uma família')),
      ]),
    );
  }
}

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  Future<Map<String, dynamic>> _membership() async {
    final rows = await _supabase.from('family_members').select('family_id, role, families(name)').eq('user_id', _supabase.auth.currentUser!.id).limit(1);
    return Map<String, dynamic>.from((rows as List).first as Map);
  }

  Future<void> _showInvite(Map<String, dynamic> membership) async {
    if (membership['role'] != 'admin') return;
    try {
      final result = await _supabase.rpc('create_family_invite', params: {'p_family_id': membership['family_id']}) as Map;
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Convite criado'), content: SelectableText('Envie este código para a pessoa entrar na família:\n\n${result['code']}\n\nVálido até ${result['expires_at']}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))]));
    } on PostgrestException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _membership(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final membership = snapshot.data!;
        final family = Map<String, dynamic>.from(membership['families'] as Map);
        final isAdmin = membership['role'] == 'admin';
        return Scaffold(
          appBar: AppBar(title: const Text('Minha família')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  family['name'] as String,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(isAdmin ? 'Você administra esta família.' : 'Você participa desta família.'),
                const SizedBox(height: 24),
                if (isAdmin)
                  FilledButton.icon(
                    onPressed: () => _showInvite(membership),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Criar convite'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FamilyError extends StatelessWidget {
  final VoidCallback onRetry;

  const _FamilyError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 16),
                const Text('Não foi possível acessar a sua família agora.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
              ],
            ),
          ),
        ),
      );
}
