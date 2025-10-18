import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete_options.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete.dart' hide OptionsViewOpenDirection;
import 'package:flutter/material.dart' hide RawAutocomplete, AutocompleteOnSelected;

class CategorizableDropdownMenu<T extends Nameable> extends StatefulWidget {
  const CategorizableDropdownMenu({
    super.key,
    required this.label,
    required this.controller,
    required this.values,
    required this.onValueChanged,
  });

  final String label;
  final TextEditingController controller;
  final List<T> values;
  final Function(T?) onValueChanged;

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
    _focusNode.addListener(() {
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
    });
  }
  

  @override
  Widget build(BuildContext context) {
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
      onSelected: handleSelect,
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
        );
      },
      fieldViewBuilder:
          (context, textEditingController, textFocusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: textFocusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (String value) {
            if (!widget.values.any((x) => x.name == value)) {
              return;
            }
            
            final val = widget.values.firstWhere(
                (element) => element.name.toLowerCase() == value.toLowerCase());
            handleSelect(val);
          }
        );
      },
    );
  }
}