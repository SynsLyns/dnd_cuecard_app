import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TagChip extends StatefulWidget {
  const TagChip({super.key, required this.tag, this.onRemove});

  final String tag;
  final VoidCallback? onRemove;

  @override
  State<TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<TagChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final showRemove = _isHovered || _isFocused;
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          key: ValueKey('tag-chip-${widget.tag}'),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: widget.onRemove == null
              ? const EdgeInsets.symmetric(horizontal: 12)
              : const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.matcha,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 4),
                AnimatedSize(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: showRemove ? 1 : 0),
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut,
                    builder: (context, progress, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Opacity(
                            opacity: progress,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: IgnorePointer(
                                ignoring: progress < 1,
                                child: IconButton(
                                  tooltip: 'Remove tag',
                                  onPressed: widget.onRemove,
                                  style: IconButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.matcha,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
