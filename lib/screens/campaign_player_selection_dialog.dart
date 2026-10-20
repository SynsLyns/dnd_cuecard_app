import 'package:flutter/material.dart';

import '../logic/supabase_service.dart';
import '../models/campaign.dart';
import '../models/shared_card_access.dart';

Future<Set<String>?> showCampaignPlayerSelectionDialog(
  BuildContext context, {
  required Campaign campaign,
  required String cardTitle,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (context) =>
        CampaignPlayerSelectionDialog(campaign: campaign, cardTitle: cardTitle),
  );
}

class CampaignPlayerSelectionDialog extends StatefulWidget {
  final Campaign campaign;
  final String cardTitle;

  const CampaignPlayerSelectionDialog({
    super.key,
    required this.campaign,
    required this.cardTitle,
  });

  @override
  State<CampaignPlayerSelectionDialog> createState() =>
      _CampaignPlayerSelectionDialogState();
}

class _CampaignPlayerSelectionDialogState
    extends State<CampaignPlayerSelectionDialog> {
  final _supabaseService = SupabaseService();
  List<CampaignPlayer> _players = [];
  final Set<String> _selectedPlayerIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final players = await _supabaseService.fetchCampaignPlayers(
        widget.campaign.id,
      );
      if (!mounted) return;
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = CloudSharingException.userMessage(error);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share "${widget.cardTitle}" with…'),
      content: SizedBox(
        width: 440,
        height: 360,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadPlayers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _players.isEmpty
            ? const Center(
                child: Text('No players have joined this campaign yet.'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the players who should receive this card.',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        if (_selectedPlayerIds.length == _players.length) {
                          _selectedPlayerIds.clear();
                        } else {
                          _selectedPlayerIds
                            ..clear()
                            ..addAll(_players.map((player) => player.userId));
                        }
                      }),
                      child: Text(
                        _selectedPlayerIds.length == _players.length
                            ? 'Select none'
                            : 'Select all',
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final player in _players)
                          CheckboxListTile(
                            value: _selectedPlayerIds.contains(player.userId),
                            title: Text(player.displayName),
                            onChanged: (selected) => setState(() {
                              if (selected ?? false) {
                                _selectedPlayerIds.add(player.userId);
                              } else {
                                _selectedPlayerIds.remove(player.userId);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || _error != null || _selectedPlayerIds.isEmpty
              ? null
              : () => Navigator.of(
                  context,
                ).pop(Set<String>.from(_selectedPlayerIds)),
          child: Text('Share with ${_selectedPlayerIds.length}'),
        ),
      ],
    );
  }
}
