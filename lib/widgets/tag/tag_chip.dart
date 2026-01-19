import 'package:flutter/material.dart';

class TagChip extends StatefulWidget {
  final String tag;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.tag,
    this.onRemove,
  });

  @override
  State<TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<TagChip> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onHover: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.tag,
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 100),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: (isHovered && widget.onRemove != null) ? 1 : 0),
                duration: const Duration(milliseconds: 100),
                builder: (context, width, child) {
                  bool showIcon = width >= 1;
                  if (isHovered && widget.onRemove != null) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 3),
                        AnimatedOpacity(
                          opacity: showIcon ? 1 : 0,
                          duration: const Duration(milliseconds: 100),
                          child: GestureDetector(
                            onTap: widget.onRemove,
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
      ),
    );
  }
}
