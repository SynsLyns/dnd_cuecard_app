import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_chip.dart';
import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.suggestions,
    required this.selectedTags,
  });

  
  final List<Tag> suggestions;
  final List<Tag> selectedTags;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagList(),
        const SizedBox(height: 24),
        _buildAutocomplete(),
      ],
    );
  }

  Widget _buildTagList() {
    return widget.selectedTags.isEmpty ? const SizedBox(height: 32) :
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.selectedTags.map((tag) {
          void removeTag(Tag tag) {
            setState(() {
              widget.selectedTags.remove(tag);
            });
          }
          return TagChip(
            tag: tag.name,
            onRemove: () => removeTag(tag),
          );
        }).toList(),
      );
  }

  Widget _buildAutocomplete() {
    late final TextEditingController controller;
    late final FocusNode focusNode;

    void addTag(Tag tag) {
      controller.clear();
      focusNode.unfocus();
      if (widget.selectedTags.any((t) => t.name == tag.name)) return;
      setState(() {
        widget.selectedTags.add(tag);
      });
    }

    return Autocomplete<Tag>(
      key: ValueKey(widget.suggestions.hashCode),
      optionsBuilder: (TextEditingValue textEditingValue) {
        return widget.suggestions.where((option) =>
            !widget.selectedTags.any((t) => t.name == option.name) &&
            (textEditingValue.text.isEmpty ||
                option.name.toLowerCase().contains(textEditingValue.text.toLowerCase())));
      },
      displayStringForOption: (option) => option.name,
      onSelected: addTag,
      fieldViewBuilder:
          (context, textEditingController, textFocusNode, onFieldSubmitted) {
        controller = textEditingController;
        focusNode = textFocusNode;
        return TextField(
          controller: textEditingController,
          focusNode: textFocusNode,
          decoration: const InputDecoration(
            labelText: 'Add a tag',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (String value) {
            final tag = widget.suggestions.firstWhere(
                (element) => element.name.toLowerCase() == value.toLowerCase(),
                orElse: () => Tag(name: ''));
            if (tag.name.isNotEmpty) {
              addTag(tag);
            }
          },
        );
      },
    );
  }
}

