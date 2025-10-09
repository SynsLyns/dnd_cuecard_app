import 'dart:math';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/card_type.dart';
import '../models/rarity.dart';
import '../widgets/card_options.dart';
import '../widgets/cue_card_widgets/cue_card_view.dart';

class CueCardCreatorView extends StatefulWidget {
  const CueCardCreatorView({super.key});

  @override
  State<CueCardCreatorView> createState() => _CueCardCreatorViewState();
}

class _CueCardCreatorViewState extends State<CueCardCreatorView> {
  final _formKey = GlobalKey<FormState>();
  final CueCardFormControllers _controllers = CueCardFormControllers();
  XFile? image;
  CardType? _currentSelectedCardType;
  Rarity? _currentSelectedRarity;

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
      CueCard cueCard = appState.selectedCard!;
      _controllers.loadCard(cueCard, appState);
      setState(() {
        image = cueCard.iconFilePath != null
            ? XFile(cueCard.iconFilePath!)
            : null;
        _currentSelectedCardType = appState.cardTypes.firstWhere(
          (element) => element.id == cueCard.type,
        );
        _currentSelectedRarity = appState.rarities.firstWhere(
          (element) => element.id == cueCard.rarity,
        );
      });
    }
  }

  void clearCueCard() {
    _controllers.clearCueCard(context.read<AppState>());
    setState(() {
      image = null;
      _currentSelectedCardType = null;
      _currentSelectedRarity = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var minConstraint = min(constraints.maxWidth, constraints.maxHeight);
        return Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(minConstraint * 0.04),
            child: Column(
              children: [
                _buildCueCardView(minConstraint: minConstraint * 0.7),
                SizedBox(height: minConstraint * 0.02),
                CardOptions(
                  controllers: _controllers,
                  currentSelectedCardType: _currentSelectedCardType,
                  currentSelectedRarity: _currentSelectedRarity,
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
                ),
                SizedBox(height: minConstraint * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _controllers.saveCueCard(
                          context.read<AppState>(),
                          image,
                        );
                        setState(() {
                          image = null;
                        });
                      },
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 16), // Add spacing between buttons
                    ElevatedButton(
                      onPressed: () {
                        clearCueCard();
                        context.read<AppState>().selectCard(null);
                      },
                      child: const Text('New Card'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCueCardView({required double minConstraint}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          width: minConstraint / 0.5625,
          height: minConstraint,
          child: CueCardView(
            controllers: _controllers,
            image: image,
            onImageSelected: (XFile? image) {
              setState(() {
                this.image = image;
              });
            },
          ),
        );
      },
    );
  }
}
