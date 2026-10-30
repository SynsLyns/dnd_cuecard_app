String? campaignJoinCodeFromUri(Uri uri) {
  final fragment = Uri.tryParse(uri.fragment);
  return fragment?.queryParameters['code'] ?? uri.queryParameters['join_code'];
}
