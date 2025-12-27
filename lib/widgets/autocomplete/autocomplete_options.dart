import 'package:flutter/material.dart' hide AutocompleteOptionToString, AutocompleteOnSelected, AutocompleteHighlightedOption, OptionsViewOpenDirection;
import 'package:flutter/scheduler.dart';
import 'package:dnd_cuecard_app/widgets/autocomplete/autocomplete.dart';

// taken from https://github.com/flutter/flutter/blob/c07ba3f8b6236535d58906f4a4ec4cc17a98df2c/packages/flutter/lib/src/material/autocomplete.dart
class AutocompleteOptions<T extends Object> extends StatelessWidget {
  const AutocompleteOptions({
    super.key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.openDirection,
    required this.options,
    required this.optionsMaxHeight,
    this.getColor
  });

  final AutocompleteOptionToString<T> displayStringForOption;
  final AutocompleteOnSelected<T> onSelected;
  final OptionsViewOpenDirection openDirection;
  final Iterable<T> options;
  final double optionsMaxHeight;
  final Color? Function(T)? getColor;

  @override
  Widget build(BuildContext context) {
    final int highlightedIndex = AutocompleteHighlightedOption.of(context);

    final AlignmentDirectional optionsAlignment = switch (openDirection) {
      OptionsViewOpenDirection.up => AlignmentDirectional.bottomStart,
      OptionsViewOpenDirection.down => AlignmentDirectional.topStart,
    };

    return Align(
      alignment: optionsAlignment,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: optionsMaxHeight),
          child: _AutocompleteOptionsList<T>(
            displayStringForOption: displayStringForOption,
            highlightedIndex: highlightedIndex,
            onSelected: onSelected,
            options: options,
            getColor: getColor,
          ),
        ),
      ),
    );
  }
}

class _AutocompleteOptionsList<T extends Object> extends StatefulWidget {
  const _AutocompleteOptionsList({
    required this.displayStringForOption,
    required this.highlightedIndex,
    required this.onSelected,
    required this.options,
    this.getColor,
  });

  final AutocompleteOptionToString<T> displayStringForOption;
  final int highlightedIndex;
  final AutocompleteOnSelected<T> onSelected;
  final Iterable<T> options;
  final Color? Function(T)? getColor;

  @override
  State<_AutocompleteOptionsList<T>> createState() => _AutocompleteOptionsListState<T>();
}

class _AutocompleteOptionsListState<T extends Object> extends State<_AutocompleteOptionsList<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_AutocompleteOptionsList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlightedIndex != oldWidget.highlightedIndex) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (!mounted) {
          return;
        }
        final BuildContext? highlightedContext = GlobalObjectKey(
          widget.options.elementAt(widget.highlightedIndex),
        ).currentContext;
        if (highlightedContext == null) {
          _scrollController.jumpTo(
            widget.highlightedIndex == 0 ? 0.0 : _scrollController.position.maxScrollExtent,
          );
        } else {
          Scrollable.ensureVisible(highlightedContext, alignment: 0.5);
        }
      }, debugLabel: 'AutocompleteOptions.ensureVisible');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: widget.options.length,
      itemBuilder: (BuildContext context, int index) {
        final T option = widget.options.elementAt(index);
        final Color? color = widget.getColor?.call(option);
        return Semantics(
          button: true,
          child: InkWell(
            key: GlobalObjectKey(option),
            onTap: () {
              widget.onSelected(option);
            },
            child: Builder(
              builder: (BuildContext context) {
                final bool highlight = widget.highlightedIndex == index;
                return Container(
                  color: highlight ? Theme.of(context).focusColor : null,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(widget.displayStringForOption(option)),
                      ),
                      if (color != null)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}