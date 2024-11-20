import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../enums/card_type.dart';
import '../enums/rarity.dart';
import '../logic/cue_card_creator.dart';

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
        null
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          LayoutBuilder(
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
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownMenu<CardType>(
                label: const Text('Card Type'),
                controller: cardTypeController,
                requestFocusOnTap: true,
                dropdownMenuEntries: CardType.values
                    .map((CardType type) => DropdownMenuEntry<CardType>(
                        value: type, label: type.name))
                    .toList(),
              ),
              const SizedBox(width: 10),
              DropdownMenu<Rarity>(
                label: const Text('Rarity'),
                controller: rarityController,
                requestFocusOnTap: true,
                dropdownMenuEntries: Rarity.values
                    .map((Rarity rarity) => DropdownMenuEntry<Rarity>(
                        value: rarity, label: rarity.name))
                    .toList(),
              ),
              const SizedBox(width: 100),
              TagEditor(),
            ],
          ),
          ElevatedButton(
            onPressed: saveCueCard,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class TagEditor extends StatelessWidget {
  const TagEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: const Color.fromARGB(255, 255, 255, 255),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          return ['test'];
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 300),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CueCardView extends StatefulWidget {
  CueCardView({
    super.key,
    required this.titleController,
    required this.requirementsController,
    required this.descriptionController,
    required this.notesController,
    required this.box1Controller,
    required this.box2Controller,
  });

  final TextEditingController titleController;
  final TextEditingController requirementsController;
  final TextEditingController descriptionController;
  final TextEditingController notesController;
  final TextEditingController box1Controller;
  final TextEditingController box2Controller;

  @override
  State<CueCardView> createState() => _CueCardViewState();
}

class _CueCardViewState extends State<CueCardView> {

  XFile? image;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      image: image != null ? DecorationImage(
                        image: FileImage(File(image!.path)) as ImageProvider<Object>,
                      ) : null,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        setState(() {
                          this.image = image;
                        });
                        if (image != null) {
                          print('Selected image path: ${image!.path}');
                        }
                      },
                      icon: Icon(Icons.add_a_photo, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                CueCardSection(
                    sectionName: 'Title', flex: 6, controller: widget.titleController),
                CueCardSection(
                    sectionName: 'Requirements',
                    flex: 1,
                    controller: widget.requirementsController),
              ],
            ),
          ),
        ),
        CueCardSection(
            sectionName: 'Description',
            flex: 3,
            controller: widget.descriptionController),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              CueCardSection(
                  sectionName: 'Notes', flex: 7, controller: widget.notesController),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    CueCardSection(
                        sectionName: 'Box 1',
                        flex: 1,
                        controller: widget.box1Controller),
                    CueCardSection(
                        sectionName: 'Box 2',
                        flex: 1,
                        controller: widget.box2Controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CueCardSection extends StatelessWidget {
  const CueCardSection({
    super.key,
    required this.sectionName,
    required this.flex,
    required this.controller,
  });

  final String sectionName;
  final int flex;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        child: TextField(
          controller: controller,
          expands: true,
          maxLines: null,
          textAlignVertical: TextAlignVertical.center,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
              alignLabelWithHint: true),
        ),
      ),
    );
  }
}
