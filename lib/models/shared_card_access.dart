class CampaignPlayer {
  final String userId;
  final String displayName;

  const CampaignPlayer({required this.userId, required this.displayName});
}

class SharedCardAccess {
  final String id;
  final String sourceCardUuid;
  final String title;
  final Set<String> playerIds;

  const SharedCardAccess({
    required this.id,
    required this.sourceCardUuid,
    required this.title,
    required this.playerIds,
  });
}
