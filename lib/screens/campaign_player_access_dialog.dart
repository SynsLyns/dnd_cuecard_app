import 'package:flutter/material.dart';

import '../logic/supabase_service.dart';
import '../models/campaign.dart';
import '../models/shared_card_access.dart';

class CampaignPlayerAccessDialog extends StatefulWidget {
  final Campaign campaign;
  final String? sourceCardUuid;

  const CampaignPlayerAccessDialog({
    super.key,
    required this.campaign,
    this.sourceCardUuid,
  });

  @override
  State<CampaignPlayerAccessDialog> createState() =>
      _CampaignPlayerAccessDialogState();
}

class _CampaignPlayerAccessDialogState
    extends State<CampaignPlayerAccessDialog> {
  final _supabaseService = SupabaseService();
  List<CampaignPlayer> _players = [];
  List<SharedCardAccess> _cards = [];
  final Set<String> _busyAccessKeys = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _supabaseService.fetchCampaignPlayers(widget.campaign.id),
        _supabaseService.fetchSharedCardAccess(widget.campaign.id),
      ]);
      if (!mounted) return;
      setState(() {
        _players = results[0] as List<CampaignPlayer>;
        final cards = results[1] as List<SharedCardAccess>;
        _cards = widget.sourceCardUuid == null
            ? cards
            : cards
                  .where((card) => card.sourceCardUuid == widget.sourceCardUuid)
                  .toList();
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

  Future<void> _setAccess(
    SharedCardAccess card,
    CampaignPlayer player,
    bool isShared,
  ) async {
    final key = '${card.id}_${player.userId}';
    final previous = card.playerIds.contains(player.userId);
    setState(() {
      _busyAccessKeys.add(key);
      if (isShared) {
        card.playerIds.add(player.userId);
      } else {
        card.playerIds.remove(player.userId);
      }
    });
    try {
      await _supabaseService.setCardSharedWithPlayer(
        campaignId: widget.campaign.id,
        sharedCardId: card.id,
        playerId: player.userId,
        isShared: isShared,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          if (previous) {
            card.playerIds.add(player.userId);
          } else {
            card.playerIds.remove(player.userId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(CloudSharingException.userMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAccessKeys.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.sourceCardUuid == null
            ? 'Player card access — ${widget.campaign.name}'
            : 'Player access — ${_cards.firstOrNull?.title ?? widget.campaign.name}',
      ),
      content: SizedBox(
        width: 620,
        height: 480,
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
                      onPressed: _loadAccess,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _players.isEmpty
            ? const Center(
                child: Text('Players who join this campaign will appear here.'),
              )
            : _cards.isEmpty
            ? const Center(
                child: Text(
                  'Share this card to the campaign before choosing its players.',
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose which connected players can see each shared card.',
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return ExpansionTile(
                          key: ValueKey(card.id),
                          title: Text(card.title),
                          subtitle: Text(
                            '${card.playerIds.length} of ${_players.length} players can see this card',
                          ),
                          children: [
                            for (final player in _players)
                              CheckboxListTile(
                                value: card.playerIds.contains(player.userId),
                                title: Text(player.displayName),
                                subtitle: Text(
                                  '${player.userId.substring(0, 8)}…',
                                ),
                                secondary:
                                    _busyAccessKeys.contains(
                                      '${card.id}_${player.userId}',
                                    )
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : null,
                                onChanged:
                                    _busyAccessKeys.contains(
                                      '${card.id}_${player.userId}',
                                    )
                                    ? null
                                    : (value) => _setAccess(
                                        card,
                                        player,
                                        value ?? false,
                                      ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
