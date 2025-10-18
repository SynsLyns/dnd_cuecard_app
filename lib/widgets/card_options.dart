import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/widgets/categorizable_dropdown_menu.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CardOptions extends StatelessWidget {
  const CardOptions({
    super.key,
    required CueCardFormControllers controllers,
    required Function(CardType?) onCardTypeChanged,
    required Function(Rarity?) onRarityChanged,
  })  : _controllers = controllers,
        _onCardTypeChanged = onCardTypeChanged,
        _onRarityChanged = onRarityChanged;

  final CueCardFormControllers _controllers;
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
      onValueChanged: _onCardTypeChanged,
    );

    CategorizableDropdownMenu<Rarity> rarityDropdown =
        CategorizableDropdownMenu<Rarity>(
      label: 'Rarity',
      controller: _controllers.rarityController,
      values: appState.rarities,
      onValueChanged: _onRarityChanged,
    );
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(flex: 2, child: cardTypeDropdown),
              const SizedBox(height: 8),
              Expanded(flex: 2, child: rarityDropdown),
            ],
          )
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 10,
          child: TagInputField(
            selectedTags: _controllers.tags,
            suggestions: appState.tags,
          )
        )
      ],
    );
  }
}