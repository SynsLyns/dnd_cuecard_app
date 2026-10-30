import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete/autocomplete_options.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete/autocomplete.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_chip.dart';
import 'package:flutter/material.dart'
    hide RawAutocomplete, AutocompleteOnSelected, OptionsViewOpenDirection;

class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.suggestions,
    required this.selectedTags,
    this.readOnly = false,
  });

  final List<Tag> suggestions;
  final List<Tag> selectedTags;
  final bool readOnly;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isFirstFocus = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _isFirstFocus = true;
    }
  }

  void _addTag(Tag tag) {
    _controller.clear();
    _focusNode.unfocus();
    if (widget.selectedTags.any((item) => item.name == tag.name)) return;
    setState(() => widget.selectedTags.add(tag));
  }

  void _removeTag(Tag tag) {
    setState(() => widget.selectedTags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly && widget.selectedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final inputWidth = constraints.maxWidth.clamp(0.0, 220.0);
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...widget.selectedTags.map(
              (tag) => TagChip(
                tag: tag.name,
                onRemove: widget.readOnly ? null : () => _removeTag(tag),
              ),
            ),
            if (!widget.readOnly)
              SizedBox(
                width: inputWidth,
                child: Container(
                  key: const ValueKey('add-tag-input-container'),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppColors.matcha
                          : AppColors.border,
                      width: _focusNode.hasFocus ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerLeft,
                  child: _buildAutocomplete(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAutocomplete() {
    return RawAutocomplete<Tag>(
      key: ValueKey(widget.suggestions.map((tag) => tag.id).join(',')),
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.name,
      onSelected: _addTag,
      optionsBuilder: (TextEditingValue value) {
        final available = widget.suggestions.where(
          (option) =>
              !widget.selectedTags.any((tag) => tag.name == option.name),
        );
        if (_isFirstFocus) {
          _isFirstFocus = false;
          return available;
        }
        return available.where(
          (option) =>
              value.text.isEmpty ||
              option.name.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<Tag> onSelected,
            Iterable<Tag> options,
          ) {
            return AutocompleteOptions<Tag>(
              displayStringForOption: (option) => option.name,
              onSelected: onSelected,
              options: options,
              openDirection: OptionsViewOpenDirection.down,
              optionsMaxHeight: 200,
            );
          },
      fieldViewBuilder:
          (context, textEditingController, textFocusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: textFocusNode,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Add a tag',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                final match = widget.suggestions.where(
                  (tag) => tag.name.toLowerCase() == value.toLowerCase(),
                );
                if (match.isNotEmpty) _addTag(match.first);
              },
            );
          },
    );
  }
}
