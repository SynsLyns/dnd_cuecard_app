import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/cue_card_creator.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/screens/management_modal_view.dart';
import 'package:dnd_cuecard_app/widgets/categorizable_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CardOptions extends StatelessWidget {
  const CardOptions({
    super.key,
    required CueCardFormControllers controllers,
    required CardType? currentSelectedCardType,
    required Rarity? currentSelectedRarity,
    required Function(CardType?) onCardTypeChanged,
    required Function(Rarity?) onRarityChanged,
  })  : _controllers = controllers,
        _currentSelectedCardType = currentSelectedCardType,
        _currentSelectedRarity = currentSelectedRarity,
        _onCardTypeChanged = onCardTypeChanged,
        _onRarityChanged = onRarityChanged;

  final CueCardFormControllers _controllers;
  final CardType? _currentSelectedCardType;
  final Rarity? _currentSelectedRarity;
  final Function(CardType?) _onCardTypeChanged;
  final Function(Rarity?) _onRarityChanged;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    CategorizableDropdownMenu<CardType> cardTypeDropdown =
        CategorizableDropdownMenu<CardType>(
      label: 'Card Type',
      controller: _controllers.cardTypeController,
      values: appState.cardTypes,
      selectedValue: _currentSelectedCardType,
      onValueChanged: _onCardTypeChanged,
      createFunction: CueCardCreator.createCardType,
      updateFunction: CueCardCreator.updateCardType,
      deleteFunction: CueCardCreator.deleteCardType,
      refreshFunction: appState.loadCardTypes,
      appState: appState,
    );

    CategorizableDropdownMenu<Rarity> rarityDropdown =
        CategorizableDropdownMenu<Rarity>(
      label: 'Rarity',
      controller: _controllers.rarityController,
      values: appState.rarities,
      selectedValue: _currentSelectedRarity,
      onValueChanged: _onRarityChanged,
      createFunction: CueCardCreator.createRarity,
      updateFunction: CueCardCreator.updateRarity,
      deleteFunction: CueCardCreator.deleteRarity,
      refreshFunction: appState.loadRarities,
      appState: appState,
    );

    void handleManageCategories() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ManagementModalView(
            refreshCardTypes: appState.loadCardTypes,
            refreshRarities: appState.loadRarities,
          );
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              cardTypeDropdown,
              const SizedBox(height: 8),
              rarityDropdown,
            ],
          ),
        ),
        Expanded(
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: handleManageCategories,
          ),
        ),
        const Spacer(flex: 10)
      ],
    );
  }
}