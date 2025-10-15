import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:flutter/material.dart';

class TagManagementTab extends StatelessWidget {
  const TagManagementTab({
    super.key,
    required this.categoryLabel,
    required this.values,
    required this.createFunction,
    required this.updateFunction,
    required this.deleteFunction,
    required this.refreshFunction,
    required this.showCreateEditDialog,
  });

  final String categoryLabel;
  final List<Tag> values;
  final Future<bool> Function(String) createFunction;
  final Future<bool> Function(int, String) updateFunction;
  final Function(int) deleteFunction;
  final Function() refreshFunction;
  final Function({
    required BuildContext context,
    required String label,
    required Future<bool> Function(String) createFunction,
    required Future<bool> Function(int, String) updateFunction,
    required Function(int) deleteFunction,
    required Function() refreshFunction,
    Tag item,
  }) showCreateEditDialog;

  @override
  Widget build(BuildContext context) {
    ListTile buildListTile(BuildContext context, int index) {
      final Tag item = values[index];
      return ListTile(
        title: Text(item.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => showCreateEditDialog(
                context: context,
                label: categoryLabel,
                createFunction: createFunction,
                updateFunction: updateFunction,
                deleteFunction: deleteFunction,
                refreshFunction: refreshFunction,
                item: item,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                if (item.id != null) {
                  deleteFunction(item.id!);
                  refreshFunction();
                }
              },
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: values.length,
            itemBuilder: buildListTile,
          ),
        ),
        ElevatedButton(
          onPressed: () => showCreateEditDialog(
            context: context,
            label: categoryLabel,
            createFunction: createFunction,
            updateFunction: updateFunction,
            deleteFunction: deleteFunction,
            refreshFunction: refreshFunction,
          ),
          child: Text('Add New $categoryLabel'),
        ),
        SizedBox(height: 1)
      ],
    );
  }
}