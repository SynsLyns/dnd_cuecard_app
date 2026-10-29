import 'dart:io';
import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/supabase_service.dart';
import 'package:dnd_cuecard_app/screens/campaign_player_selection_dialog.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HoverableCueCard extends StatefulWidget {
  const HoverableCueCard({super.key, required this.cueCard});

  final CueCard cueCard;

  @override
  State<HoverableCueCard> createState() => _HoverableCueCardState();
}

class _HoverableCueCardState extends State<HoverableCueCard> {
  bool _isHovered = false;
  bool _isFocused = false;
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
    final borderRadius = BorderRadius.circular(14);
    final hasActiveCampaign = appState.activeCampaignId != null;
    final shareStatus = appState.getCardShareStatus(widget.cueCard);
    final isCurrentCard =
        widget.cueCard.id != null &&
        appState.selectedCard?.id == widget.cueCard.id;
    final showActions = _isHovered || _isFocused;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isCurrentCard ? AppColors.paper : Colors.transparent,
        borderRadius: borderRadius,
        border: Border.all(
          color: isCurrentCard ? AppColors.matcha : Colors.transparent,
          width: isCurrentCard ? 1.5 : 1,
        ),
        boxShadow: isCurrentCard
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () => appState.selectCard(widget.cueCard),
          onHover: (hovering) => setState(() => _isHovered = hovering),
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildCardIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.cueCard.title ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.cueCard.description ?? 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasActiveCampaign) ...[
                  const SizedBox(width: 4),
                  _buildShareBadge(shareStatus),
                ],
                if (_isSharing)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  _buildRowActions(
                    appState,
                    hasActiveCampaign,
                    shareStatus,
                    showActions,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.cueCard.iconFilePath == null
          ? const Icon(
              Icons.water_drop_outlined,
              size: 22,
              color: AppColors.matcha,
            )
          : Image.file(
              File(widget.cueCard.iconFilePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.water_drop_outlined,
                size: 22,
                color: AppColors.matcha,
              ),
            ),
    );
  }

  Widget _buildRowActions(
    AppState appState,
    bool hasActiveCampaign,
    CardShareStatus shareStatus,
    bool showActions,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasActiveCampaign &&
            shareStatus == CardShareStatus.changesNotPushed)
          IconButton(
            icon: const Icon(
              Icons.cloud_upload,
              color: AppColors.matcha,
              size: 20,
            ),
            tooltip: 'Push update to players',
            onPressed: () => _pushUpdate(appState),
          ),
        if (hasActiveCampaign &&
            shareStatus == CardShareStatus.notShared &&
            showActions)
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.matcha, size: 20),
            tooltip: 'Share to campaign',
            onPressed: () => _shareCard(appState),
          ),
        if (hasActiveCampaign &&
            shareStatus != CardShareStatus.notShared &&
            showActions)
          IconButton(
            icon: const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.muted,
              size: 20,
            ),
            tooltip: 'Unshare from campaign',
            onPressed: () => _unshareCard(appState),
          ),
        if (showActions)
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.muted, size: 20),
            tooltip: 'Delete card',
            onPressed: () => appState.removeCueCard(widget.cueCard.id!),
          ),
      ],
    );
  }
}
