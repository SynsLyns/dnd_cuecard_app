import 'dart:io';

import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../logic/cue_card_creator.dart';
import 'cue_card_section.dart';

class CueCardView extends StatefulWidget {
  const CueCardView({
    super.key,
    required this.controllers,
    required this.currentSelectedCardType,
    required this.currentSelectedRarity,
    required this.image,
    required this.onImageSelected,
    this.readOnly = false,
  });

  final CueCardFormControllers controllers;
  final CardType? currentSelectedCardType;
  final Rarity? currentSelectedRarity;
  final XFile? image;
  final void Function(XFile?) onImageSelected;
  final bool readOnly;

  @override
  State<CueCardView> createState() => _CueCardViewState();
}

class _CueCardViewState extends State<CueCardView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildTopRow(), _buildDescriptionSection(), _buildBottomRow()],
    );
  }

  Widget _buildTopRow() {
    return Expanded(
      flex: 1,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildImageSection(),
            _buildTitleSection(),
            CueCardSection(
              sectionName: 'Requirements',
              flex: 1,
              controller: widget.controllers.requirementsController,
              readOnly: widget.readOnly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Expanded(
      flex: 1,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: const Color.fromARGB(255, 255, 255, 255),
          image: widget.image != null
              ? DecorationImage(
                  image:
                      FileImage(File(widget.image!.path))
                          as ImageProvider<Object>,
                )
              : null,
        ),
        child: widget.readOnly ? null : IconButton(
          onPressed: _showIconSelectionDialog,
          icon: Icon(
            Icons.add_a_photo,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    Color cardTypeColor = widget.currentSelectedCardType?.color ?? Colors.white;
    Color rarityColor = widget.currentSelectedRarity?.color ?? Colors.white;

    return Expanded(
      flex: 6,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: rarityColor,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Container(
                decoration: BoxDecoration(
                color: cardTypeColor,
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.all(Radius.elliptical(constraints.maxWidth / 2, constraints.maxHeight / 2))
              ),
              child: TextField(
                controller: widget.controllers.titleController,
                readOnly: widget.readOnly,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                  alignLabelWithHint: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickNewImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    widget.onImageSelected(image);
  }

  void _selectExistingImage(String imagePath) {
    widget.onImageSelected(XFile(imagePath));
  }

  Future<void> _showIconSelectionDialog() async {
    List<String> existingIconPaths = await CueCardCreator.getAllIconFilePaths();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existingIconPaths.isNotEmpty)
                _buildIconGrid(existingIconPaths),
              if (existingIconPaths.isEmpty)
                const Text('No existing icons. Add a new one!'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _pickNewImage();
                },
                child: const Text('Add New Icon'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid(List<String> existingIconPaths) {
    return Expanded(
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: existingIconPaths.length,
        itemBuilder: (context, index) {
          String iconPath = existingIconPaths[index];
          return GestureDetector(
            onTap: () {
              _selectExistingImage(iconPath);
              Navigator.pop(context);
            },
            child: Image.file(File(iconPath), fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return CueCardSection(
      sectionName: 'Description',
      flex: 3,
      controller: widget.controllers.descriptionController,
      readOnly: widget.readOnly,
    );
  }

  Widget _buildBottomRow() {
    return Expanded(
      flex: 1,
      child: Row(
        children: [
          CueCardSection(
            sectionName: 'Notes',
            flex: 7,
            controller: widget.controllers.notesController,
            readOnly: widget.readOnly,
          ),
          _buildBoxesColumn(),
        ],
      ),
    );
  }

  Widget _buildBoxesColumn() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          CueCardSection(
            sectionName: 'Box 1',
            flex: 1,
            controller: widget.controllers.box1Controller,
            readOnly: widget.readOnly,
          ),
          CueCardSection(
            sectionName: 'Box 2',
            flex: 1,
            controller: widget.controllers.box2Controller,
            readOnly: widget.readOnly,
          ),
        ],
      ),
    );
  }
}
