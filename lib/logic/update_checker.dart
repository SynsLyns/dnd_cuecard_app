import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const latestJsonUrl = 'https://synslyns.github.io/dnd_cuecard_app/latest.json';

class UpdateChecker {
  UpdateChecker({
    http.Client? client,
    Future<String> Function()? currentVersion,
    Uri? latestUri,
  }) : _client = client ?? http.Client(),
       _currentVersion = currentVersion ?? _getCurrentVersion,
       _latestUri = latestUri ?? Uri.parse(latestJsonUrl);

  final http.Client _client;
  final Future<String> Function() _currentVersion;
  final Uri _latestUri;

  Future<String?> checkForUpdate() async {
    final http.Response response;
    try {
      response = await _client
          .get(_latestUri)
          .timeout(const Duration(seconds: 10));
    } on Exception {
      return null;
    }

    if (response.statusCode != 200) return null;

    final Object? payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      return null;
    }
    if (payload is! Map<String, dynamic>) return null;

    final latestVersion = payload['version'];
    if (latestVersion is! String) return null;
    final latestParts = _parseVersion(latestVersion);
    if (latestParts == null) return null;

    final String currentVersion;
    try {
      currentVersion = await _currentVersion();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }

    return isVersionNewer(latestVersion, currentVersion)
        ? latestParts.join('.')
        : null;
  }

  void dispose() => _client.close();

  static Future<String> _getCurrentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  static bool isVersionNewer(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);
    if (latestParts == null || currentParts == null) return false;

    for (var index = 0; index < 3; index++) {
      if (latestParts[index] != currentParts[index]) {
        return latestParts[index] > currentParts[index];
      }
    }
    return false;
  }

  static List<int>? _parseVersion(String version) {
    final numericVersion = version.split('+').first;
    final segments = numericVersion.split('.');
    if (segments.length < 3) return null;

    final parts = <int>[];
    for (final segment in segments.take(3)) {
      final value = int.tryParse(segment);
      if (value == null || value < 0) return null;
      parts.add(value);
    }
    return parts;
  }
}
