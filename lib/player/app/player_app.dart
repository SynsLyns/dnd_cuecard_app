import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../models/player_shared_card.dart';
import '../models/player_initiative.dart';
import '../player_link.dart';
import '../state/player_app_state.dart';
import '../widgets/player_shared_card_tile.dart';

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
  final _cardSearchController = TextEditingController();
  final _preferences = SharedPreferencesAsync();
  String? _formError;
  String? _authMessage;
  bool _isCreatingAccount = false;
  bool _isAuthenticating = false;
  bool _isResumingSignIn = false;
  int _mobileSelectedTab = 0;

  @override
  void initState() {
    super.initState();
    _joinCodeController.text = _initialJoinCode() ?? '';
    _client = widget.initializationError == null
        ? Supabase.instance.client
        : null;
    _cardSearchController.addListener(_onCardSearchChanged);
    _state = PlayerAppState(_client)..addListener(_onStateChanged);
    _authSubscription = _client?.auth.onAuthStateChange.listen(
      _onAuthStateChanged,
    );
    if (widget.initializationError == null) {
      unawaited(_initializePlayer());
    }
  }

  void _onAuthStateChanged(AuthState state) {
    if (state.event == AuthChangeEvent.signedOut) {
      unawaited(_state.handleSignedOut());
    } else if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.initialSession) {
      final metadataName = _client?.auth.currentUser?.userMetadata?['name'];
      if (_displayNameController.text.trim().isEmpty &&
          metadataName is String) {
        _displayNameController.text = metadataName;
      }
      unawaited(_resumeSignedInPlayer());
    }
    if (mounted) setState(() {});
  }

  Future<void> _initializePlayer() async {
    await _restorePendingJoinFields();
    if (!mounted) return;
    await _resumeSignedInPlayer();
  }

  Future<void> _resumeSignedInPlayer() async {
    if (_isResumingSignIn ||
        _state.campaignId != null ||
        _client?.auth.currentUser == null) {
      return;
    }
    _isResumingSignIn = true;
    try {
      await _restorePendingJoinFields();
      if (!mounted) return;

      final pendingCode = _joinCodeController.text.trim();
      final pendingName = _displayNameController.text.trim();
      if (pendingCode.isNotEmpty && pendingName.isNotEmpty) {
        await _state.join(pendingCode, pendingName);
        if (_state.campaignId != null) {
          await _clearPendingJoinFields();
        }
      } else {
        await _state.initialize(null);
      }
    } finally {
      _isResumingSignIn = false;
    }
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
    return campaignJoinCodeFromUri(Uri.base);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onCardSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state
      ..removeListener(_onStateChanged)
      ..dispose();
    unawaited(_authSubscription?.cancel());
    _cardSearchController.removeListener(_onCardSearchChanged);
    _joinCodeController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cardSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DnD Shared Cards',
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.ground,
        appBar: _state.campaignId == null
            ? AppBar(
                title: const Text('Shared Cue Cards'),
                backgroundColor: AppColors.panel,
              )
            : null,
        body: _buildContent(),
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
    if (_client?.auth.currentUser == null || _state.campaignId == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildJoinForm(),
          ),
        ),
      );
    }
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
      await _clearPendingJoinFields();
    }
  }

  Future<void> _clearPendingJoinFields() async {
    await _preferences.remove('player_pending_join_code');
    await _preferences.remove('player_pending_display_name');
  }

  Widget _buildCampaign() {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 800
          ? _buildMobileCampaign()
          : _buildDesktopCampaign(constraints.maxWidth),
    );
  }

  Widget _buildDesktopCampaign(double availableWidth) {
    final sidebarWidth = (availableWidth * 0.3).clamp(300.0, 380.0);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCampaignHeader(compact: false),
                if (_state.error != null)
                  _errorPanel(_state.error!, retry: _state.retry),
                Expanded(
                  child:
                      _state.isLoading &&
                          _state.cards.isEmpty &&
                          _state.initiativeEncounter == null
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: AppColors.ground,
                                child: _buildCardsSection(
                                  _filteredCards,
                                  compact: false,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: sidebarWidth,
                              child: Container(
                                color: AppColors.sidebar,
                                child: _buildInitiativeSection(
                                  _state.initiativeEncounter,
                                  compact: false,
                                ),
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
    );
  }

  Widget _buildMobileCampaign() {
    return SafeArea(
      child: Column(
        children: [
          _buildCampaignHeader(compact: true),
          if (_state.error != null)
            _errorPanel(_state.error!, retry: _state.retry),
          Expanded(
            child:
                _state.isLoading &&
                    _state.cards.isEmpty &&
                    _state.initiativeEncounter == null
                ? const Center(child: CircularProgressIndicator())
                : _mobileSelectedTab == 0
                ? _buildCardsSection(_filteredCards, compact: true)
                : _buildInitiativeSection(
                    _state.initiativeEncounter,
                    compact: true,
                  ),
          ),
          NavigationBar(
            selectedIndex: _mobileSelectedTab,
            onDestinationSelected: (index) {
              setState(() => _mobileSelectedTab = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.style_outlined),
                selectedIcon: Icon(Icons.style),
                label: 'Cards',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_numbered),
                label: 'Initiative',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PlayerSharedCard> get _filteredCards {
    return _state.cards
        .where((card) => card.matchesSearch(_cardSearchController.text))
        .toList();
  }

  Widget _buildCampaignHeader({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(bottom: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _state.campaignName ?? 'Campaign',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Fraunces',
                    fontSize: compact ? 18 : 20,
                  ),
                ),
                Text(
                  'Playing as ${_state.displayName ?? 'Player'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (compact)
            PopupMenuButton<String>(
              tooltip: 'Campaign options',
              onSelected: (action) {
                if (action == 'leave') _state.leaveCampaign();
                if (action == 'sign_out') _signOut();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'leave', child: Text('Leave campaign')),
                PopupMenuItem(value: 'sign_out', child: Text('Sign out')),
              ],
            )
          else ...[
            TextButton(
              onPressed: _state.leaveCampaign,
              child: const Text('Leave campaign'),
            ),
            TextButton(onPressed: _signOut, child: const Text('Sign out')),
          ],
        ],
      ),
    );
  }

  Widget _buildCardsSection(
    List<PlayerSharedCard> cards, {
    required bool compact,
  }) {
    final count = _cardSearchController.text.trim().isEmpty
        ? '${_state.cards.length} cards'
        : '${cards.length} of ${_state.cards.length} cards';
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 28,
        vertical: compact ? 16 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Shared cards',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontFamily: 'Fraunces'),
              ),
              const SizedBox(width: 8),
              Text(count, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          _buildCardSearchField(),
          const SizedBox(height: 8),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Text(
                      _state.cards.isEmpty
                          ? 'No cards have been shared yet.'
                          : 'No cards match your search.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: cards.length,
                    itemBuilder: (context, index) => _buildCard(cards[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSearchField() {
    return TextField(
      key: const ValueKey('player-card-search'),
      controller: _cardSearchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by title or tag',
        prefixIcon: const Icon(Icons.search, color: AppColors.muted),
        suffixIcon: _cardSearchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _cardSearchController.clear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }

  Widget _buildInitiativeSection(
    PlayerInitiativeEncounter? encounter, {
    required bool compact,
  }) {
    final hasCombatants = encounter?.combatants.isNotEmpty ?? false;
    return Container(
      color: compact ? AppColors.ground : AppColors.sidebar,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Text(
                'Initiative',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontFamily: 'Fraunces'),
              ),
            if (!compact && !hasCombatants)
              Text(
                'Initiative',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontFamily: 'Fraunces'),
              ),
            if (compact) const SizedBox(height: 12),
            if (hasCombatants)
              _buildInitiative(encounter!, compact: compact)
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Text(
                  'No active initiative encounter.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitiative(
    PlayerInitiativeEncounter encounter, {
    required bool compact,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.rule),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            Text(
              'Initiative',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontFamily: 'Fraunces'),
            ),
            const SizedBox(height: 8),
          ],
          for (final combatant in encounter.combatants)
            _buildCombatant(combatant),
        ],
      ),
    );
  }

  Widget _buildCombatant(PlayerInitiativeCombatant combatant) {
    final details = <String>[
      combatant.visibility == 'full' &&
              combatant.hp != null &&
              combatant.maxHp != null
          ? '${combatant.healthStatus} · ${combatant.hp}/${combatant.maxHp} HP'
          : combatant.healthStatus,
      if (combatant.exhaustion != null) 'Exhaustion ${combatant.exhaustion}',
      if (combatant.concentration != null)
        combatant.concentration! ? 'Concentrating' : 'Not concentrating',
      if (combatant.reactionUsed != null)
        combatant.reactionUsed! ? 'Reaction used' : 'Reaction ready',
      if (combatant.capacity != null) 'Capacity ${combatant.capacity}',
      if (combatant.cooldownTimers != null)
        'Charges ${combatant.cooldownTimers!.join('/')}',
      if (combatant.cooldown != null) 'Cooldown ${combatant.cooldown} turns',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: combatant.isCurrent ? AppColors.paper : Colors.transparent,
        border: Border.all(
          color: combatant.isCurrent ? AppColors.matcha : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: combatant.isCurrent
                ? AppColors.matcha
                : AppColors.sage,
            foregroundColor: combatant.isCurrent
                ? AppColors.ground
                : AppColors.matcha,
            child: Text(
              combatant.initiative.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      combatant.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (combatant.isCurrent)
                      _initiativeChip('Current turn', highlighted: true),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: details.map(_initiativeChip).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initiativeChip(String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.matcha : AppColors.sage,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.ground : AppColors.matcha,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCard(PlayerSharedCard card) {
    return PlayerSharedCardTile(
      card: card,
      hasUpdated: _state.hasUnseenUpdate(card),
      onExpanded: () => _state.markViewed(card),
    );
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
