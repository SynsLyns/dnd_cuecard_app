import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:flutter/material.dart';

class CategorizableDropdownMenu<T extends Nameable> extends StatelessWidget {
  const CategorizableDropdownMenu({
    super.key,
    required this.label,
    required this.controller,
    required this.values,
    required this.selectedValue,
    required this.onValueChanged,
    required this.createFunction,
    required this.updateFunction,
    required this.deleteFunction,
    required this.refreshFunction,
    required this.appState,
  });

  final String label;
  final TextEditingController controller;
  final List<T> values;
  final T? selectedValue;
  final Function(T?) onValueChanged;
  final Future<bool> Function(String, Color) createFunction;
  final Future<bool> Function(int, String, Color) updateFunction;
  final Function(int) deleteFunction;
  final Function() refreshFunction;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    void handleFocusChange(bool hasFocus) {
      if (!hasFocus) {
        final name = selectedValue?.name ?? '';
        if (controller.text != name) {
          controller.text = name;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Focus(
          onFocusChange: handleFocusChange,
          child: DropdownMenu<T>(
            width: constraints.maxWidth,
            label: Text(label),
            controller: controller,
            requestFocusOnTap: true,
            enableFilter: true,
            menuHeight: 200,
            dropdownMenuEntries: values
                .map(
                  (T value) => DropdownMenuEntry<T>(
                    value: value,
                    label: value.name,
                  ),
                )
                .toList(),
            onSelected: onValueChanged
          ),
        );
      },
    );
  }
}