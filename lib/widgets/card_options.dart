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

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 560 ? 96.0 : 180.0;
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

        return Column(
          children: [
            _settingRow(
              'TYPE',
              cardType,
              labelWidth: labelWidth,
              constrainValue: true,
            ),
            _rowDivider(),
            _settingRow(
              'RARITY',
              rarity,
              labelWidth: labelWidth,
              constrainValue: true,
            ),
            _rowDivider(),
            _settingRow(
              'TAGS',
              tags,
              labelWidth: labelWidth,
              bottomPadding: readOnly ? 0 : 12,
              centerValue: readOnly,
              key: const ValueKey('card-options-tags-row'),
            ),
          ],
        );
      },
    );
  }

  Widget _settingRow(
    String label,
    Widget value, {
    required double labelWidth,
    bool constrainValue = false,
    double bottomPadding = 12,
    bool centerValue = false,
    Key? key,
  }) {
    return Padding(
      key: key,
      padding: EdgeInsets.only(top: 12, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.48,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: constrainValue
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: SizedBox(height: 44, child: value),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: centerValue
                        ? Align(alignment: Alignment.centerLeft, child: value)
                        : value,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider() =>
      const Divider(height: 1, thickness: 1, color: AppColors.rule);
}
