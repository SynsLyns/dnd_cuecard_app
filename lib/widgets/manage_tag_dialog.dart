import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:flutter/material.dart';

class ManageTagDialog extends StatefulWidget {
  const ManageTagDialog({
    super.key,
    this.item,
    required this.label,
    required this.createFunction,
    required this.updateFunction,
    required this.deleteFunction,
    required this.refreshFunction,
  });

  final Tag? item;
  final String label;
  final Future<bool> Function(String) createFunction;
  final Future<bool> Function(int, String) updateFunction;
  final Function(int) deleteFunction;
  final Function() refreshFunction;

  @override
  State<ManageTagDialog> createState() => _ManageTagDialogState();
}

class _ManageTagDialogState extends State<ManageTagDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.item == null;

    void handleDelete() {
      if (widget.item != null && widget.item!.id != null) {
        widget.deleteFunction(widget.item!.id!);
        Navigator.pop(context);
        widget.refreshFunction();
      }
    }

    Future<void> handleSave() async {
      if (_nameController.text.isNotEmpty) {
        bool success;
        if (isNew) {
          success = await widget.createFunction(_nameController.text);
        } else {
          if (widget.item!.id != null) {
            success = await widget.updateFunction(widget.item!.id!, _nameController.text);
          } else {
            success = false;
          }
        }

        if (success) {
          if (context.mounted) Navigator.pop(context);
          widget.refreshFunction();
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