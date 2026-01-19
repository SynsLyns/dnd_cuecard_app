import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete/autocomplete_options.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete/autocomplete.dart';
import 'package:dnd_cuecard_app/widgets/labeled_value.dart';
import 'package:flutter/material.dart' hide RawAutocomplete, AutocompleteOnSelected, OptionsViewOpenDirection, AutocompleteHighlightedOption;

class CategorizableDropdownMenu<T extends Nameable> extends StatefulWidget {
  const CategorizableDropdownMenu({
    super.key,
    required this.label,
    required this.controller,
    required this.values,
    required this.onValueChanged,
    this.getColor,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final List<T> values;
  final Function(T?) onValueChanged;
  final Color? Function(T)? getColor;
  final bool readOnly;

  @override
  State<CategorizableDropdownMenu<T>> createState() => _CategorizableDropdownMenuState<T>();
}

class _CategorizableDropdownMenuState<T extends Nameable> extends State<CategorizableDropdownMenu<T>> {
  String? _selectedName;
  final FocusNode _focusNode = FocusNode();
  bool _isFirstFocus = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant CategorizableDropdownMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final name = _selectedName ?? '';
      if (widget.controller.text != name) {
        widget.controller.text = name;
      }
      _isFirstFocus = true;
    } else {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  void _handleControllerChange() {
    setState(() {
      if (widget.controller.text.isEmpty) {
        _selectedName = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.readOnly
        ? _buildViewMode()
        : _buildEditMode();
  }

  Widget _buildViewMode() {
    return LabeledValue(label: widget.label, value: widget.controller.text);
  }

  Widget _buildEditMode() {
    void handleSelect(T val) {
      widget.onValueChanged(val);
      _selectedName = val.name;
      _focusNode.unfocus();
    }

    return RawAutocomplete<T>(
      key: ObjectKey(widget.values),
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.name,
      onSelected: widget.readOnly ? null : handleSelect,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (_isFirstFocus) {
          _isFirstFocus = false;
          return widget.values;
        }
        return widget.values.where((option) =>
            option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
        return AutocompleteOptions<T>(
          displayStringForOption: (option) => option.name,
          onSelected: onSelected,
          options: options,
          openDirection: OptionsViewOpenDirection.down,
          optionsMaxHeight: 200,
          getColor: widget.getColor,
        );
      },
      fieldViewBuilder:
          (context, textEditingController, textFocusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: textFocusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(),
          ),
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
    );
  }
}