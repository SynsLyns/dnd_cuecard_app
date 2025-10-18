import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete_options.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_chip.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete.dart' hide OptionsViewOpenDirection;
import 'package:flutter/material.dart' hide RawAutocomplete, AutocompleteOnSelected;

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
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isFirstFocus = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildTagList()),
        const SizedBox(height: 8),
        Expanded(flex: 2, child: _buildAutocomplete()),
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

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      } else {
        _isFirstFocus = true;
      }
    });
  }

  Widget _buildAutocomplete() {
    void addTag(Tag tag) {
      _controller.clear();
      _focusNode.unfocus();
      if (widget.selectedTags.any((t) => t.name == tag.name)) return;
      setState(() {
        widget.selectedTags.add(tag);
      });
    }

    return RawAutocomplete<Tag>(
      key: ValueKey(widget.suggestions.hashCode),
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.name,
      onSelected: addTag,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (_isFirstFocus) {
          _isFirstFocus = false;
          return widget.suggestions.where((option) =>
            !widget.selectedTags.any((t) => t.name == option.name));
        }
        return widget.suggestions.where((option) =>
            !widget.selectedTags.any((t) => t.name == option.name) &&
            (textEditingValue.text.isEmpty ||
                option.name.toLowerCase().contains(textEditingValue.text.toLowerCase())));
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Tag> onSelected, Iterable<Tag> options) {
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
          decoration: InputDecoration(
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

