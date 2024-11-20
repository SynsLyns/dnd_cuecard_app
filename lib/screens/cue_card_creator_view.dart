import 'package:flutter/material.dart';
import '../enums/card_type.dart';
import '../enums/rarity.dart';
import '../logic/cue_card_creator.dart';
import '../widgets/cue_card_widgets/cue_card_view.dart';
import 'tag_editor.dart';

class CueCardCreatorView extends StatefulWidget {
  const CueCardCreatorView({super.key});

  @override
  State<CueCardCreatorView> createState() => _CueCardCreatorViewState();
}

class _CueCardCreatorViewState extends State<CueCardCreatorView> {
  final titleController = TextEditingController();
  final requirementsController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  final box1Controller = TextEditingController();
  final box2Controller = TextEditingController();
  final cardTypeController = TextEditingController();
  final rarityController = TextEditingController();
  String? imagePath;

  @override
  void dispose() {
    titleController.dispose();
    requirementsController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    box1Controller.dispose();
    box2Controller.dispose();
    cardTypeController.dispose();
    rarityController.dispose();
    super.dispose();
  }

  void saveCueCard() {
    CueCardCreator.createCueCard(
        titleController.text,
        requirementsController.text,
        descriptionController.text,
        box1Controller.text,
        box2Controller.text,
        notesController.text,
        [],
        cardTypeController.text,
        rarityController.text,
        imagePath
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          _buildCueCardView(),
          const SizedBox(height: 40),
          _buildCardOptions(),
          ElevatedButton(
            onPressed: saveCueCard,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCueCardView() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          width: constraints.maxWidth * 0.8,
          height: constraints.maxWidth * 0.8 * 0.5625,
          child: CueCardView(
            titleController: titleController,
            requirementsController: requirementsController,
            descriptionController: descriptionController,
            notesController: notesController,
            box1Controller: box1Controller,
            box2Controller: box2Controller,
            onImageChanged: (imagePath) => setState(() => this.imagePath = imagePath),
          ),
        );
      },
    );
  }

  Widget _buildCardOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDropdownMenu<CardType>(
          label: 'Card Type',
          controller: cardTypeController,
          values: CardType.values,
        ),
        const SizedBox(width: 10),
        _buildDropdownMenu<Rarity>(
          label: 'Rarity',
          controller: rarityController,
          values: Rarity.values,
        ),
        const SizedBox(width: 100),
        const TagEditor(),
      ],
    );
  }

  Widget _buildDropdownMenu<T extends Enum>({
    required String label,
    required TextEditingController controller,
    required List<T> values,
  }) {
    return DropdownMenu<T>(
      label: Text(label),
      controller: controller,
      requestFocusOnTap: true,
      dropdownMenuEntries: values
          .map((T value) => DropdownMenuEntry<T>(
              value: value, label: value.name))
          .toList(),
    );
  }
}