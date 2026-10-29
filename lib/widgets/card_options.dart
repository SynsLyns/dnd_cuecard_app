import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/theme/app_colors.dart';
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
    this.readOnly = false,
  }) : _controllers = controllers,
       _onCardTypeChanged = onCardTypeChanged,
       _onRarityChanged = onRarityChanged;

  final CueCardFormControllers _controllers;
  final Function(CardType?) _onCardTypeChanged;
  final Function(Rarity?) _onRarityChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final cardType = CategorizableDropdownMenu<CardType>(
      label: 'Card Type',
      controller: _controllers.cardTypeController,
      values: appState.cardTypes,
      onValueChanged: _onCardTypeChanged,
      getColor: (item) => item.color,
      readOnly: readOnly,
    );
    final rarity = CategorizableDropdownMenu<Rarity>(
      label: 'Rarity',
      controller: _controllers.rarityController,
      values: appState.rarities,
      onValueChanged: _onRarityChanged,
      getColor: (item) => item.color,
      readOnly: readOnly,
    );
    final tags = TagInputField(
      selectedTags: _controllers.tags,
      suggestions: appState.tags,
      readOnly: readOnly,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field('CARD TYPE', cardType),
              const SizedBox(height: 12),
              _field('RARITY', rarity),
              const SizedBox(height: 12),
              _field('TAGS', tags, height: null),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 190,
              child: Column(
                children: [
                  _field('CARD TYPE', cardType),
                  const SizedBox(height: 12),
                  _field('RARITY', rarity),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _field('TAGS', tags, height: null)),
          ],
        );
      },
    );
  }

  Widget _field(String label, Widget child, {double? height = 44}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.48,
            ),
          ),
        ),
        if (height == null) child else SizedBox(height: height, child: child),
      ],
    );
  }
}
