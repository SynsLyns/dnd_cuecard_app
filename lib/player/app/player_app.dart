import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_shared_card.dart';
import '../state/player_app_state.dart';

class PlayerApp extends StatefulWidget {
  final String? initializationError;

  const PlayerApp({super.key, this.initializationError});

  @override
  State<PlayerApp> createState() => _PlayerAppState();
}

class _PlayerAppState extends State<PlayerApp> {
  late final PlayerAppState _state;
  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  final _joinCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _preferences = SharedPreferencesAsync();
  String? _formError;
  String? _authMessage;
  bool _isCreatingAccount = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _joinCodeController.text = _initialJoinCode() ?? '';
    _client = widget.initializationError == null
        ? Supabase.instance.client
        : null;
    _state = PlayerAppState(_client)..addListener(_onStateChanged);
    _authSubscription = _client?.auth.onAuthStateChange.listen(
      _onAuthStateChanged,
    );
    unawaited(_restorePendingJoinFields());
    if (widget.initializationError == null) {
      _state.initialize(_initialJoinCode());
    }
  }

  void _onAuthStateChanged(AuthState state) {
    if (state.event == AuthChangeEvent.signedOut) {
      unawaited(_state.handleSignedOut());
    } else if (state.event == AuthChangeEvent.signedIn &&
        _state.campaignId == null) {
      unawaited(_state.initialize(_joinCodeController.text));
      final metadataName = _client?.auth.currentUser?.userMetadata?['name'];
      if (_displayNameController.text.trim().isEmpty &&
          metadataName is String) {
        _displayNameController.text = metadataName;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _restorePendingJoinFields() async {
    final code = await _preferences.getString('player_pending_join_code');
    final name = await _preferences.getString('player_pending_display_name');
    if (!mounted) return;
    if (_joinCodeController.text.isEmpty && code != null) {
      _joinCodeController.text = code;
    }
    if (_displayNameController.text.isEmpty && name != null) {
      _displayNameController.text = name;
    }
    setState(() {});
  }

  String? _initialJoinCode() {
    final fragment = Uri.tryParse(Uri.base.fragment);
    return fragment?.queryParameters['code'] ??
        Uri.base.queryParameters['code'];
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state
      ..removeListener(_onStateChanged)
      ..dispose();
    unawaited(_authSubscription?.cancel());
    _joinCodeController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF237A70),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'DnD Shared Cards',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Shared Cue Cards'),
          backgroundColor: colorScheme.surface,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.initializationError != null) {
      return _buildError(widget.initializationError!);
    }
    if (_state.isLoading && _state.campaignId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_client?.auth.currentUser == null) return _buildJoinForm();
    if (_state.campaignId == null) return _buildJoinForm();
    return _buildCampaign();
  }

  Widget _buildJoinForm() {
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _client?.auth.currentUser == null
                      ? 'Sign in to join your campaign'
                      : 'Join your campaign',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Use an account to view cards shared with you.'),
                if (_client?.auth.currentUser == null) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _authenticateWithPassword(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _isAuthenticating
                              ? null
                              : _authenticateWithPassword,
                          child: Text(
                            _isCreatingAccount ? 'Create account' : 'Sign in',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _isAuthenticating
                            ? null
                            : () => setState(() {
                                _isCreatingAccount = !_isCreatingAccount;
                                _authMessage = null;
                              }),
                        child: Text(
                          _isCreatingAccount ? 'I have an account' : 'Register',
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _isAuthenticating ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ] else ...[
                  Text(
                    'Signed in as ${_client!.auth.currentUser!.email ?? 'Google account'}',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _signOut,
                      child: const Text('Sign out'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Join code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _join(),
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  _errorPanel(_formError!),
                ],
                if (_authMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_authMessage!),
                ],
                if (_state.error != null) ...[
                  const SizedBox(height: 12),
                  _errorPanel(_state.error!, retry: _state.retry),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      _state.isLoading || _client?.auth.currentUser == null
                      ? null
                      : _join,
                  child: _state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join campaign'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authenticateWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _authMessage = 'Enter your email and password.');
      return;
    }
    setState(() {
      _isAuthenticating = true;
      _authMessage = null;
    });
    try {
      if (_isCreatingAccount) {
        final response = await _client!.auth.signUp(
          email: email,
          password: password,
        );
        if (response.session == null) {
          _authMessage =
              'Check your email to confirm your account, then sign in.';
        }
      } else {
        await _client!.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } catch (error) {
      _authMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isAuthenticating = true;
      _authMessage = null;
    });
    try {
      await _preferences.setString(
        'player_pending_join_code',
        _joinCodeController.text.trim(),
      );
      await _preferences.setString(
        'player_pending_display_name',
        _displayNameController.text.trim(),
      );
      final launched = await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
      if (!launched) {
        throw const AuthException(
          'The Google sign-in page could not be opened.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _authMessage = error.toString();
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isAuthenticating = true);
    try {
      await _state.signOut();
    } catch (error) {
      if (mounted) {
        setState(() => _authMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _join() async {
    final code = _joinCodeController.text.trim();
    final name = _displayNameController.text.trim();
    if (code.isEmpty || name.isEmpty) {
      setState(() => _formError = 'Enter both the join code and your name.');
      return;
    }
    setState(() => _formError = null);
    await _state.join(code, name);
    if (_state.campaignId != null) {
      await _preferences.remove('player_pending_join_code');
      await _preferences.remove('player_pending_display_name');
    }
  }

  Widget _buildCampaign() {
    final campaignName = _state.campaignName ?? 'Campaign';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaignName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text('Playing as ${_state.displayName ?? 'Player'}'),
                    ],
                  ),
                ),
                Column(
                  children: [
                    TextButton(
                      onPressed: _state.leaveCampaign,
                      child: const Text('Leave campaign'),
                    ),
                    TextButton(
                      onPressed: _signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_state.error != null)
          _errorPanel(_state.error!, retry: _state.retry),
        Expanded(
          child: _state.isLoading && _state.cards.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _state.cards.isEmpty
              ? const Center(child: Text('No cards have been shared yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _state.cards.length,
                  itemBuilder: (context, index) =>
                      _buildCard(_state.cards[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCard(PlayerSharedCard card) {
    final typeColor = _colorFromArgb(card.typeColor, Colors.white);
    final rarityColor = _colorFromArgb(card.rarityColor, Colors.white);
    final hasUpdated = _state.hasUnseenUpdate(card);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) _state.markViewed(card);
        },
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black26),
                ),
                child: Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (hasUpdated) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('Updated'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (card.typeName != null)
                _metadataChip(card.typeName!, typeColor),
              if (card.rarityName != null)
                _metadataChip(card.rarityName!, rarityColor),
              for (final tag in card.tags) _metadataChip(tag, null),
            ],
          ),
        ),
        children: [
          if (card.schemaVersion > 1)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'This card uses a newer format. Some details may not be shown.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: LayoutBuilder(
              builder: (context, constraints) => AspectRatio(
                aspectRatio: constraints.maxWidth < 500 ? 4 / 3 : 16 / 9,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _cardIcon(card.iconBytes)),
                          Expanded(
                            flex: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: rarityColor,
                                border: Border.all(color: Colors.black),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) => Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.all(
                                      Radius.elliptical(
                                        constraints.maxWidth / 2,
                                        constraints.maxHeight / 2,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    card.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: (constraints.maxHeight * 0.32)
                                          .clamp(12, 28),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(child: _cardSection(card.requirements)),
                        ],
                      ),
                    ),
                    Expanded(flex: 3, child: _cardSection(card.description)),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(flex: 7, child: _cardSection(card.notes)),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(child: _cardSection(card.box1)),
                                Expanded(child: _cardSection(card.box2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSection(String? value) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: SelectableText(
              value ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (constraints.maxHeight * 0.14).clamp(10, 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardIcon(Uint8List? bytes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? const SizedBox.expand()
          : Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  Widget _metadataChip(String label, Color? color) => Chip(
    label: Text(label),
    backgroundColor: color?.withValues(alpha: 0.45),
    visualDensity: VisualDensity.compact,
  );

  Color _colorFromArgb(int? value, Color fallback) {
    if (value == null) return fallback;
    return Color(value & 0xFFFFFFFF);
  }

  Widget _buildError(String message) => Center(child: _errorPanel(message));

  Widget _errorPanel(String message, {VoidCallback? retry}) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          if (retry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: retry, child: const Text('Retry')),
            ),
        ],
      ),
    ),
  );
}
