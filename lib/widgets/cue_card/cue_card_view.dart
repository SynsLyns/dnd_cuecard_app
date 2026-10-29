import 'dart:io';

import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:dnd_cuecard_app/theme/app_theme.dart';
import 'package:dnd_cuecard_app/theme/contrast.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../logic/cue_card_creator.dart';

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
    final typeColor = widget.currentSelectedCardType?.color ?? AppColors.matcha;
    final rarityColor = widget.currentSelectedRarity?.color ?? AppColors.ground;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          CardBanner(
            typeColor: typeColor,
            rarityColor: rarityColor,
            titleController: widget.controllers.titleController,
            requirementsController: widget.controllers.requirementsController,
            image: widget.image,
            readOnly: widget.readOnly,
            onAddImage: _showIconSelectionDialog,
          ),
          Expanded(
            child: CardBody(
              controller: widget.controllers.descriptionController,
              readOnly: widget.readOnly,
            ),
          ),
          CardFooter(
            notesController: widget.controllers.notesController,
            firstValueController: widget.controllers.box1Controller,
            secondValueController: widget.controllers.box2Controller,
            readOnly: widget.readOnly,
          ),
        ],
      ),
    );
  }

  Future<void> _pickNewImage() async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(source: ImageSource.gallery);
    widget.onImageSelected(selected);
  }

  void _selectExistingImage(String imagePath) {
    widget.onImageSelected(XFile(imagePath));
  }

  Future<void> _showIconSelectionDialog() async {
    final existingIconPaths = await CueCardCreator.getAllIconFilePaths();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: 400,
          height: 320,
          child: Column(
            children: [
              if (existingIconPaths.isNotEmpty)
                Expanded(child: _buildIconGrid(existingIconPaths)),
              if (existingIconPaths.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No existing icons. Add a new one!'),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
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
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 88,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: existingIconPaths.length,
      itemBuilder: (context, index) {
        final iconPath = existingIconPaths[index];
        return InkWell(
          onTap: () {
            _selectExistingImage(iconPath);
            Navigator.pop(context);
          },
          child: Image.file(
            File(iconPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.matcha,
            ),
          ),
        );
      },
    );
  }
}

class CardBanner extends StatelessWidget {
  const CardBanner({
    super.key,
    required this.typeColor,
    required this.rarityColor,
    required this.titleController,
    required this.requirementsController,
    required this.image,
    required this.readOnly,
    required this.onAddImage,
  });

  final Color typeColor;
  final Color rarityColor;
  final TextEditingController titleController;
  final TextEditingController requirementsController;
  final XFile? image;
  final bool readOnly;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context)
        .extension<AppTypography>()!
        .fraunces
        .copyWith(fontSize: 28, color: readableOn(rarityColor));
    final costStyle = Theme.of(context)
        .extension<AppTypography>()!
        .fraunces
        .copyWith(fontSize: 30, color: readableOn(typeColor));

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: typeColor,
      child: Row(
        children: [
          _CardImage(
            image: image,
            typeColor: typeColor,
            readOnly: readOnly,
            onAddImage: onAddImage,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: OvalTitle(
              controller: titleController,
              backgroundColor: rarityColor,
              textColor: readableOn(rarityColor),
              readOnly: readOnly,
              style: titleStyle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            // Requirements is the existing top-row value in this app.
            child: Tooltip(
              message: 'Requirements',
              child: readOnly
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        requirementsController.text,
                        maxLines: 1,
                        style: costStyle,
                      ),
                    )
                  : TextField(
                      controller: requirementsController,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: costStyle.copyWith(fontSize: 17),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.image,
    required this.typeColor,
    required this.readOnly,
    required this.onAddImage,
  });

  final XFile? image;
  final Color typeColor;
  final bool readOnly;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final ringColor = readableOn(typeColor);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: ringColor, width: 2),
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.file(
                File(image!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.matcha,
                ),
              )
            else
              const Icon(
                Icons.water_drop_outlined,
                size: 22,
                color: AppColors.matcha,
              ),
            if (!readOnly)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddImage,
                  child: const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OvalTitle extends StatelessWidget {
  const OvalTitle({
    super.key,
    required this.controller,
    required this.backgroundColor,
    required this.textColor,
    required this.readOnly,
    required this.style,
  });

  final TextEditingController controller;
  final Color backgroundColor;
  final Color textColor;
  final bool readOnly;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: OvalBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: OvalBorder(
              side: BorderSide(
                color: AppColors.ink.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
          ),
          child: Center(
            child: readOnly
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(controller.text, maxLines: 1, style: style),
                    ),
                  )
                : TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: style,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class CardBody extends StatelessWidget {
  const CardBody({super.key, required this.controller, required this.readOnly});

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 190),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Center(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            minLines: 3,
            maxLines: null,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              height: 1.5,
              color: AppColors.ink,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class CardFooter extends StatelessWidget {
  const CardFooter({
    super.key,
    required this.notesController,
    required this.firstValueController,
    required this.secondValueController,
    required this.readOnly,
  });

  final TextEditingController notesController;
  final TextEditingController firstValueController;
  final TextEditingController secondValueController;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.footer,
        border: Border(top: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: notesController,
              readOnly: readOnly,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                color: AppColors.inkSoft,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ValueChip(controller: firstValueController, readOnly: readOnly),
              const SizedBox(height: 6),
              _ValueChip(controller: secondValueController, readOnly: readOnly),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.controller, required this.readOnly});

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 58, maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(10),
      ),
      child: readOnly
          ? Text(
              controller.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.matcha,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            )
          : IntrinsicWidth(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.matcha,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
    );
  }
}
