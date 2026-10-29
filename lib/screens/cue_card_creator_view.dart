import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/supabase_service.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/screens/management_modal_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'relationship_view.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';

import '../models/card_type.dart';
import '../models/rarity.dart';
import '../widgets/card_options.dart';
import '../widgets/cue_card/cue_card_view.dart';
import 'campaign_player_access_dialog.dart';
import 'campaign_player_selection_dialog.dart';

class CueCardCreatorView extends StatefulWidget {
  const CueCardCreatorView({super.key});

  @override
  State<CueCardCreatorView> createState() => _CueCardCreatorViewState();
}

class _CueCardCreatorViewState extends State<CueCardCreatorView> {
  int _selectedTab = 0; // 0 = Create, 1 = Relationships
  final _formKey = GlobalKey<FormState>();
  final CueCardFormControllers _controllers = CueCardFormControllers();
  XFile? image;
  CardType? _currentSelectedCardType;
  Rarity? _currentSelectedRarity;
  CueCard? _selectedCard;
  bool _isEditMode = true; // Toggle for edit/view mode

  // Relationship state
  CueCard? _relationshipParentA;
  CueCard? _relationshipParentB;
  CueCard? _relationshipChild;

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var appState = context.watch<AppState>();
    if (appState.selectedCard != null) {
      _selectedCard = appState.selectedCard!;
      _controllers.loadCard(_selectedCard!, appState);
      setState(() {
        image = _selectedCard!.iconFilePath != null
            ? XFile(_selectedCard!.iconFilePath!)
            : null;
        _currentSelectedCardType = appState.cardTypes.firstWhere(
          (element) => element.id == _selectedCard!.type,
          orElse: () => CardType(id: -1, name: 'Unknown', color: Colors.white),
        );
        _currentSelectedRarity = appState.rarities.firstWhere(
          (element) => element.id == _selectedCard!.rarity,
          orElse: () => Rarity(id: -1, name: 'Unknown', color: Colors.white),
        );
      });
    } else if (_selectedCard != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        clearCueCard();
      });
    }
  }

  void clearCueCard() {
    _controllers.clearCueCard(context.read<AppState>());
    clearState();
  }

  void clearState() {
    setState(() {
      image = null;
      _currentSelectedCardType = null;
      _currentSelectedRarity = null;
      _selectedCard = null;
    });
  }

  void _viewCard(CueCard card) {
    setState(() {
      _selectedTab = 0;
    });
    context.read<AppState>().selectCard(card);
  }

  Future<void> _openInitiativeTrackerInNewWindow() async {
    final args = jsonEncode({
      'route': 'initiative',
      'campaign_id': context.read<AppState>().activeCampaignId,
    });
    final controller = await WindowController.create(
      WindowConfiguration(arguments: args),
    );
    await controller.show();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabHeader(),
        Expanded(
          child: _selectedTab == 0
              ? _buildCardCreatorSection()
              : _buildRelationshipSection(),
        ),
      ],
    );
  }

  Widget _buildTabHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            OutlinedButton(
              onPressed: _openInitiativeTrackerInNewWindow,
              child: const Text('Initiative Tracker'),
            ),
            OutlinedButton(
              onPressed: _handleManageCategories,
              child: const Text('Manage Categories'),
            ),
            if (_selectedTab == 0) _buildViewEditModeToggle(),
          ];
          if (constraints.maxWidth < 900) {
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [_buildTabs(), ...actions],
            );
          }
          return Row(
            children: [
              _buildTabs(),
              const Spacer(),
              ...actions.expand(
                (action) => [action, const SizedBox(width: 12)],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildTab('Cards', 0), _buildTab('Relationships', 1)],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _selectedTab == index;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.matcha : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() => _selectedTab = index);
            context.read<AppState>().isRelationshipMode = index == 1;
          },
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.ground : AppColors.tabInactive,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewEditModeToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('View', style: TextStyle(color: AppColors.muted)),
        Switch(
          value: _isEditMode,
          onChanged: (value) {
            setState(() {
              _isEditMode = value;
            });
          },
        ),
        const Text('Edit', style: TextStyle(color: AppColors.muted)),
      ],
    );
  }

  Widget _buildCardCreatorSection() {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 600 ? 16 : 40,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, cardConstraints) {
                        final cardHeight = (cardConstraints.maxWidth / 1.78)
                            .clamp(360.0, double.infinity)
                            .toDouble();
                        return SizedBox(
                          height: cardHeight,
                          child: _buildCueCardView(readOnly: !_isEditMode),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    _buildControlsPanel(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.rule),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          CardOptions(
            controllers: _controllers,
            onCardTypeChanged: (value) {
              setState(() => _currentSelectedCardType = value);
            },
            onRarityChanged: (value) {
              setState(() => _currentSelectedRarity = value);
            },
            readOnly: !_isEditMode,
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final appState = context.watch<AppState>();
    final hasActiveCampaign = appState.activeCampaignId != null;
    final selectedCard = _selectedCard;
    final shareStatus = selectedCard != null
        ? appState.getCardShareStatus(selectedCard)
        : CardShareStatus.notShared;

    final secondaryActions = <Widget>[
      OutlinedButton(onPressed: _handleNewCard, child: const Text('New Card')),
      if (selectedCard != null && hasActiveCampaign)
        OutlinedButton.icon(
          icon: Icon(
            shareStatus == CardShareStatus.changesNotPushed
                ? Icons.cloud_upload
                : shareStatus == CardShareStatus.upToDate
                ? Icons.check_circle_outline
                : Icons.share,
            size: 18,
          ),
          label: Text(
            shareStatus == CardShareStatus.changesNotPushed
                ? 'Push Update'
                : shareStatus == CardShareStatus.upToDate
                ? 'Shared (Up to date)'
                : 'Share to Players',
          ),
          onPressed: shareStatus == CardShareStatus.upToDate
              ? null
              : () async {
                  try {
                    Set<String>? recipientIds;
                    if (shareStatus == CardShareStatus.notShared) {
                      final campaign = appState.activeCampaign;
                      if (campaign == null) return;
                      recipientIds = await showCampaignPlayerSelectionDialog(
                        context,
                        campaign: campaign,
                        cardTitle: selectedCard.title ?? 'Untitled',
                      );
                      if (recipientIds == null) return;
                    }
                    await appState.shareCard(
                      selectedCard,
                      recipientIds: recipientIds,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Card synced with players!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sync failed: ${CloudSharingException.userMessage(e)}',
                          ),
                        ),
                      );
                    }
                  }
                },
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(onPressed: _handleSave, child: const Text('Save')),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: secondaryActions),
              if (selectedCard != null &&
                  shareStatus != CardShareStatus.notShared &&
                  selectedCard.uuid != null &&
                  appState.activeCampaign != null)
                IconButton(
                  tooltip: 'Manage player access for this card',
                  icon: const Icon(Icons.people_outline),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => CampaignPlayerAccessDialog(
                      campaign: appState.activeCampaign!,
                      sourceCardUuid: selectedCard.uuid,
                    ),
                  ),
                ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _handleSave,
                child: const Text('Save'),
              ),
            ),
            const SizedBox(width: 10),
            ...secondaryActions.expand(
              (action) => [action, const SizedBox(width: 8)],
            ),
            if (selectedCard != null && hasActiveCampaign) ...[
              if (shareStatus != CardShareStatus.notShared &&
                  selectedCard.uuid != null &&
                  appState.activeCampaign != null)
                IconButton(
                  tooltip: 'Manage player access for this card',
                  icon: const Icon(Icons.people_outline),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => CampaignPlayerAccessDialog(
                      campaign: appState.activeCampaign!,
                      sourceCardUuid: selectedCard.uuid,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRelationshipSection() {
    return RelationshipView(
      parentA: _relationshipParentA,
      parentB: _relationshipParentB,
      child: _relationshipChild,
      onParentAChanged: (c) => setState(() => _relationshipParentA = c),
      onParentBChanged: (c) => setState(() => _relationshipParentB = c),
      onChildChanged: (c) => setState(() => _relationshipChild = c),
      onViewCard: _viewCard,
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      await _controllers.saveCueCard(context.read<AppState>(), image);
      clearState();
    }
  }

  void _handleNewCard() {
    clearCueCard();
  }

  void _handleManageCategories() {
    var appState = context.read<AppState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManagementModalView(
          refreshCardTypes: appState.loadCardTypes,
          refreshRarities: appState.loadRarities,
          refreshTags: appState.loadTags,
        );
      },
    );
  }

  Widget _buildCueCardView({bool readOnly = false}) {
    return CueCardView(
      controllers: _controllers,
      currentSelectedCardType: _currentSelectedCardType,
      currentSelectedRarity: _currentSelectedRarity,
      image: image,
      onImageSelected: (XFile? image) {
        setState(() {
          this.image = image;
        });
      },
      readOnly: readOnly,
    );
  }
}
