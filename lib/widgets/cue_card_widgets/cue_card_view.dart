import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cue_card_section.dart';

class CueCardView extends StatefulWidget {
  CueCardView({
    super.key,
    required this.titleController,
    required this.requirementsController,
    required this.descriptionController,
    required this.notesController,
    required this.box1Controller,
    required this.box2Controller,
    required this.onImageChanged,
  });

  final TextEditingController titleController;
  final TextEditingController requirementsController;
  final TextEditingController descriptionController;
  final TextEditingController notesController;
  final TextEditingController box1Controller;
  final TextEditingController box2Controller;
  final void Function(String? imagePath) onImageChanged;

  @override
  State<CueCardView> createState() => _CueCardViewState();
}

class _CueCardViewState extends State<CueCardView> {

  XFile? image;

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
                sectionName: 'Title', flex: 6, controller: widget.titleController),
            CueCardSection(
                sectionName: 'Requirements',
                flex: 1,
                controller: widget.requirementsController),
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
          image: image != null ? DecorationImage(
            image: FileImage(File(image!.path)) as ImageProvider<Object>,
          ) : null,
        ),
        child: IconButton(
          onPressed: _pickImage,
          icon: Icon(Icons.add_a_photo, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.image = image;
    });
    widget.onImageChanged(image?.path);
  }

  Widget _buildDescriptionSection() {
    return CueCardSection(
        sectionName: 'Description',
        flex: 3,
        controller: widget.descriptionController);
  }

  Widget _buildBottomRow() {
    return Expanded(
      flex: 2,
      child: Row(
        children: [
          CueCardSection(
              sectionName: 'Notes', flex: 7, controller: widget.notesController),
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
              controller: widget.box1Controller),
          CueCardSection(
              sectionName: 'Box 2',
              flex: 1,
              controller: widget.box2Controller),
        ],
      ),
    );
  }
}