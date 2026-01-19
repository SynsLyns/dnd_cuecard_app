import 'dart:math';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/screens/management_modal_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'relationship_view.dart';
import 'package:provider/provider.dart';

import '../models/card_type.dart';
import '../models/rarity.dart';
import '../widgets/card_options.dart';
import '../widgets/cue_card/cue_card_view.dart';

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
    } else if (_selectedCard != null)  {
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

  void _viewCard(CueCard card,) {
    setState(() {
      _selectedTab = 0;
    });
    context.read<AppState>().selectCard(card);
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
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          ToggleButtons(
            isSelected: [_selectedTab == 0, _selectedTab == 1],
            onPressed: (index) {
              setState(() => _selectedTab = index);
              context.read<AppState>().isRelationshipMode = index == 1;
            },
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Cards')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Relationships')),
            ],
          ),
          const Spacer(),
          if (_selectedTab == 0) _buildViewEditModeToggle(),
        ],
      ),
    );
  }

  Widget _buildViewEditModeToggle() {
    return Row(
      children: [
        const Text('View Mode'),
        Switch(
          value: _isEditMode,
          onChanged: (value) {
            setState(() {
              _isEditMode = value;
            });
          },
        ),
        const Text('Edit Mode'),
      ],
    );
  }

  Widget _buildCardCreatorSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        var minConstraint = min(constraints.maxWidth, constraints.maxHeight);
        return Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(minConstraint * 0.04),
            child: Column(
              children: [
                _buildCueCardView(minConstraint: minConstraint * 0.66, readOnly: !_isEditMode),
                SizedBox(height: minConstraint * 0.02),
                _buildCardOptions(minConstraint),
                SizedBox(height: minConstraint * 0.02),
                if (_isEditMode) _buildActionButtons(minConstraint),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardOptions(double minConstraint) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: minConstraint * 0.11),
      child: CardOptions(
        controllers: _controllers,
        onCardTypeChanged: (value) {
          setState(() {
            _currentSelectedCardType = value;
          });
        },
        onRarityChanged: (value) {
          setState(() {
            _currentSelectedRarity = value;
          });
        },
        readOnly: !_isEditMode,
      ),
    );
  }

  Widget _buildActionButtons(double minConstraint) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: minConstraint * 0.11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Save'),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _handleNewCard,
            child: const Text('New Card'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _handleManageCategories,
            child: const Text('Manage Categories'),
          ),
        ],
      ),
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

  Widget _buildCueCardView({required double minConstraint, bool readOnly = false}) {
    return SizedBox(
      width: minConstraint / 0.5625,
      height: minConstraint,
      child: CueCardView(
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
      ),
    );
  }
}
