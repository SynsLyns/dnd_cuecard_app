import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final bool isHovered;
  final VoidCallback onRemove;

  const TagChip({
    super.key,
    required this.tag,
    required this.isHovered,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(color: colorScheme.onSecondaryContainer),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 100),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isHovered ? 1 : 0),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              builder: (context, width, child) {
                bool showIcon = width >= 1;
                if (isHovered) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 6),
                      AnimatedOpacity(
                        opacity: showIcon ? 1 : 0,
                        duration: const Duration(milliseconds: 100),
                        child: GestureDetector(
                          onTap: onRemove,
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
