import 'dart:io';

import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../logic/cue_card_creator.dart';
import 'cue_card_section.dart';

class CueCardView extends StatefulWidget {
  const CueCardView({
    super.key,
    required this.controllers,
    required this.image,
    required this.onImageSelected,
  });

  final CueCardFormControllers controllers;
  final XFile? image;
  final void Function(XFile?) onImageSelected;
  @override
  State<CueCardView> createState() => _CueCardViewState();
}

class _CueCardViewState extends State<CueCardView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopRow(),
        _buildDescriptionSection(),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildTopRow() {
    return Expanded(
      flex: 1,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildImageSection(),
            CueCardSection(
                sectionName: 'Title', flex: 6, controller: widget.controllers.titleController),
            CueCardSection(
                sectionName: 'Requirements',
                flex: 1,
                controller: widget.controllers.requirementsController),
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
          image: widget.image != null ? DecorationImage(
            image: FileImage(File(widget.image!.path)) as ImageProvider<Object>,
          ) : null,
        ),
        child: IconButton(
          onPressed: _showIconSelectionDialog,
          icon: Icon(Icons.add_a_photo, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
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
              if (existingIconPaths.isNotEmpty) _buildIconGrid(existingIconPaths),
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
        controller: widget.controllers.descriptionController);
  }

  Widget _buildBottomRow() {
    return Expanded(
      flex: 2,
      child: Row(
        children: [
          CueCardSection(
              sectionName: 'Notes', flex: 7, controller: widget.controllers.notesController),
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
              controller: widget.controllers.box1Controller),
          CueCardSection(
              sectionName: 'Box 2',
              flex: 1,
              controller: widget.controllers.box2Controller),
        ],
      ),
    );
  }
}
