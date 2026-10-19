import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _joinCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  String? _formError;

  @override
  void initState() {
    super.initState();
    _joinCodeController.text = _initialJoinCode() ?? '';
    final client = widget.initializationError == null
        ? Supabase.instance.client
        : null;
    _state = PlayerAppState(client)..addListener(_onStateChanged);
    if (widget.initializationError == null) {
      _state.initialize(_initialJoinCode());
    }
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
    _joinCodeController.dispose();
    _displayNameController.dispose();
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
    if (_state.campaignId == null) return _buildJoinForm();
    return _buildCampaign();
  }

  Widget _buildJoinForm() {
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join your campaign',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Enter the invite code from your DM.'),
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
              if (_state.error != null) ...[
                const SizedBox(height: 12),
                _errorPanel(_state.error!, retry: _state.retry),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _state.isLoading ? null : _join,
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
    );
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
                TextButton(
                  onPressed: _state.leaveCampaign,
                  child: const Text('Leave'),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: rarityColor.withValues(alpha: 0.9)),
      ),
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
          _detail('Requirements', card.requirements),
          _detail('Description', card.description),
          _detail('Notes', card.notes),
          _detail('Box 1', card.box1),
          _detail('Box 2', card.box2),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _detail(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
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
