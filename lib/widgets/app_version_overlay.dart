import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionOverlay extends StatelessWidget {
  AppVersionOverlay({
    required this.child,
    Future<String> Function()? versionLoader,
    super.key,
  }) : _version = (versionLoader ?? _loadVersion)();

  final Widget child;
  final Future<String> _version;

  static Future<String> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber.isEmpty
        ? packageInfo.version
        : '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      Positioned(
        left: 8,
        bottom: 8,
        child: IgnorePointer(
          child: FutureBuilder<String>(
            future: _version,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Text(
                'v${snapshot.data}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}
