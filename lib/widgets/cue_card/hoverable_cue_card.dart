import 'dart:io';
import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/supabase_service.dart';
import 'package:dnd_cuecard_app/screens/campaign_player_selection_dialog.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HoverableCueCard extends StatefulWidget {
  const HoverableCueCard({
    super.key,
    required this.cueCard,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final CueCard cueCard;
  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  State<HoverableCueCard> createState() => _HoverableCueCardState();
}

class _HoverableCueCardState extends State<HoverableCueCard> {
  bool _isHovered = false;
  bool _isSharing = false;

  Widget _buildShareBadge(CardShareStatus status) {
    Color badgeColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case CardShareStatus.upToDate:
        badgeColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        label = 'Shared (up to date)';
        icon = Icons.check_circle_outline;
        break;
      case CardShareStatus.changesNotPushed:
        badgeColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        label = 'Shared (changes not pushed)';
        icon = Icons.sync_problem;
        break;
      case CardShareStatus.notShared:
        badgeColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Not shared';
        icon = Icons.cloud_off_outlined;
        break;
    }

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              status == CardShareStatus.upToDate
                  ? 'Shared'
                  : status == CardShareStatus.changesNotPushed
                  ? 'Outdated'
                  : 'Not shared',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCard(AppState appState) async {
    setState(() => _isSharing = true);
    try {
      final campaign = appState.activeCampaign;
      if (campaign == null) return;
      final recipientIds = await showCampaignPlayerSelectionDialog(
        context,
        campaign: campaign,
        cardTitle: widget.cueCard.title ?? 'Untitled',
      );
      if (recipientIds == null) return;
      await appState.shareCard(widget.cueCard, recipientIds: recipientIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card shared to campaign!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sharing failed: ${CloudSharingException.userMessage(e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _pushUpdate(AppState appState) async {
    setState(() => _isSharing = true);
    try {
      await appState.pushCardUpdate(widget.cueCard);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card update pushed to players!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Push failed: ${CloudSharingException.userMessage(e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _unshareCard(AppState appState) async {
    setState(() => _isSharing = true);
    try {
      await appState.unshareCard(widget.cueCard);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card unshared from campaign.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unshare failed: ${CloudSharingException.userMessage(e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final borderRadius = BorderRadius.circular(8.0);
    final hasActiveCampaign = appState.activeCampaignId != null;
    final shareStatus = appState.getCardShareStatus(widget.cueCard);
    final cardIcon = widget.cueCard.iconFilePath != null
        ? SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(widget.cueCard.iconFilePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          )
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          if (widget.selectionMode) {
            widget.onSelectionChanged?.call(!widget.isSelected);
          } else {
            appState.selectCard(widget.cueCard);
          }
        },
        onHover: (hovering) => setState(() => _isHovered = hovering),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.cueCard.title ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (hasActiveCampaign) _buildShareBadge(shareStatus),
            ],
          ),
          subtitle: Text(
            widget.cueCard.description ?? 'No description',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          leading: widget.selectionMode
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) =>
                          widget.onSelectionChanged?.call(value ?? false),
                    ),
                  ],
                )
              : cardIcon,
          trailing: _isSharing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.selectionMode &&
                        hasActiveCampaign &&
                        shareStatus == CardShareStatus.changesNotPushed)
                      IconButton(
                        icon: const Icon(
                          Icons.cloud_upload,
                          color: Colors.orange,
                          size: 20,
                        ),
                        tooltip: 'Push update to players',
                        onPressed: () => _pushUpdate(appState),
                      ),
                    if (!widget.selectionMode &&
                        hasActiveCampaign &&
                        shareStatus == CardShareStatus.notShared &&
                        _isHovered)
                      IconButton(
                        icon: const Icon(
                          Icons.share,
                          color: Colors.blue,
                          size: 20,
                        ),
                        tooltip: 'Share to campaign',
                        onPressed: () => _shareCard(appState),
                      ),
                    if (!widget.selectionMode &&
                        hasActiveCampaign &&
                        shareStatus != CardShareStatus.notShared &&
                        _isHovered)
                      IconButton(
                        icon: const Icon(
                          Icons.cloud_off_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        tooltip: 'Unshare from campaign',
                        onPressed: () => _unshareCard(appState),
                      ),
                    if (!widget.selectionMode && _isHovered)
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Delete card',
                        onPressed: () =>
                            appState.removeCueCard(widget.cueCard.id!),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
