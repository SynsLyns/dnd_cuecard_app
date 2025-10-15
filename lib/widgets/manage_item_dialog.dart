import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ManageItemDialog extends StatefulWidget {
  const ManageItemDialog({
    super.key,
    this.id,
    this.initialName,
    this.initialColor,
    this.supportsColor = false,
    required this.label,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onRefresh,
  });

  final String label;
  final String? initialName;
  final Color? initialColor;
  final bool supportsColor;
  final Future<bool> Function(String name, Color? color) onCreate;
  final Future<bool> Function(int id, String name, Color? color) onUpdate;
  final void Function(int) onDelete;
  final void Function() onRefresh;
  final int? id;

  @override
  State<ManageItemDialog> createState() => _ManageItemDialogState();
}

class _ManageItemDialogState extends State<ManageItemDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = widget.initialColor ?? Colors.white;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.id == null;

    void handleDelete() {
      if (widget.id != null) {
        widget.onDelete(widget.id!);
        Navigator.pop(context);
        widget.onRefresh();
      }
    }

    Future<void> handleSave() async {
      if (_nameController.text.isNotEmpty) {
        bool success;
        if (isNew) {
          success = await widget.onCreate(_nameController.text, widget.supportsColor ? _selectedColor : null);
        } else {
          if (widget.id != null) {
            success = await widget.onUpdate(widget.id!, _nameController.text, _selectedColor);
          } else {
            success = false;
          }
        }

        if (success) {
          if (context.mounted) Navigator.pop(context);
          widget.onRefresh();
        } else {
            if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('A ${widget.label} with this name already exists.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    return AlertDialog(
      title: Text(isNew ? 'Create New ${widget.label}' : 'Edit ${widget.label}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.supportsColor) ...[
            const SizedBox(height: 16),
            ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) => setState(() => _selectedColor = color),
              paletteType: PaletteType.hueWheel,
              enableAlpha: false,
              labelTypes: const [],
              hexInputBar: true,
            )
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!isNew)
        TextButton(
          onPressed: handleDelete,
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: handleSave,
          child: Text(isNew ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}