import 'package:dnd_cuecard_app/interfaces/nameable.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:flutter/material.dart';

class CategoryManagementTab<T extends Nameable> extends StatelessWidget {
  const CategoryManagementTab({
    super.key,
    required this.categoryLabel,
    required this.values,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onRefresh,
    required this.showCreateEditDialog,
  });

  final String categoryLabel;
  final List<T> values;
  final Future<bool> Function(String name, Color? color) onCreate;
  final Future<bool> Function(int id, String name, Color? color) onUpdate;
  final Function(int) onDelete;
  final Function() onRefresh;
  final Function<U extends Nameable>({
    required String label,
    required Future<bool> Function(String name, Color? color) onCreate,
    required Future<bool> Function(int id, String name, Color? color) onUpdate,
    required Function(int) onDelete,
    required Function() onRefresh,
    U? item,
    bool supportsColor
  }) showCreateEditDialog;

  @override
  Widget build(BuildContext context) {

    void showManageDialog(T? item) {
      showCreateEditDialog(
        label: categoryLabel,
        onCreate: onCreate,
        onUpdate: onUpdate,
        onDelete: onDelete,
        onRefresh: onRefresh,
        item: item,
        supportsColor: T == CardType || T == Rarity,
      );
    }

    ListTile buildListTile(BuildContext context, int index) {
      final T item = values[index];
      return ListTile(
        title: Text(item.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => showManageDialog(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                if (item.id != null) {
                  onDelete(item.id!);
                  onRefresh();
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
          onPressed: () => showManageDialog(null),
          child: Text('Add New $categoryLabel'),
        ),
        SizedBox(height: 5)
      ],
    );
  }
}