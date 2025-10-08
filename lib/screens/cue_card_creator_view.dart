import 'dart:math';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../logic/cue_card_creator.dart';
import '../models/card_type.dart';
import '../models/rarity.dart';
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
        image = cueCard.iconFilePath != null ? XFile(cueCard.iconFilePath!) : null;
      });
    }
  }

  void clearCueCard() {
    _controllers.clearCueCard(context.read<AppState>());
    setState(() {
      image = null;
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
            padding: EdgeInsets.all(minConstraint * 0.02),
            child: Column(
              children: [
                _buildCueCardView(minConstraint: minConstraint * 0.7),
                SizedBox(height: minConstraint * 0.04),
                _buildCardOptions(),
                SizedBox(height: minConstraint * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _controllers.saveCueCard(context.read<AppState>(), image);
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
                      child: const Text('Clear'),
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

  Widget _buildCardOptions() {
    var appState = context.watch<AppState>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildDropdownMenu<CardType>(
            label: 'Card Type',
            controller: _controllers.cardTypeController,
            values: appState.cardTypes,
            createFunction: CueCardCreator.createCardType,
            refreshFunction: appState.loadCardTypes,
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: _buildDropdownMenu<Rarity>(
            label: 'Rarity',
            controller: _controllers.rarityController,
            values: appState.rarities,
            createFunction: CueCardCreator.createRarity,
            refreshFunction: appState.loadRarities,
          ),
        )
      ],
    );
  }

  Widget _buildDropdownMenu<T extends Nameable>({
    required String label,
    required TextEditingController controller,
    required List<T> values,
    required Function(String, Color) createFunction,
    required Function() refreshFunction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            DropdownMenu<T>(
              width: max(constraints.maxWidth - 48, 0),
              label: Text(label),
              controller: controller,
              requestFocusOnTap: true,
              dropdownMenuEntries: values
                  .map((T value) => DropdownMenuEntry<T>(
                        value: value,
                        label: value.name,
                      ))
                  .toList(),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateDialog(
                context: context,
                label: label,
                createFunction: createFunction,
                refreshFunction: refreshFunction,
              ),
            ),
          ],
        );
      }
    );
  }

  void _showCreateDialog({
    required BuildContext context,
    required String label,
    required Function(String, Color) createFunction,
    required Function() refreshFunction,
  }) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.white;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Create New $label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) => setState(() => selectedColor = color),
                paletteType: PaletteType.hueWheel,
                enableAlpha: false,
                labelTypes: [],
                hexInputBar: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  createFunction(nameController.text, selectedColor);
                  Navigator.pop(context);
                  refreshFunction();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
