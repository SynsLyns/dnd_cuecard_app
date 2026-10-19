class CardShare {
  final String cardUuid;
  final String campaignId;
  final String sharedCardId;
  final int pushedVersion;
  final String pushedHash;
  final DateTime pushedAt;

  CardShare({
    required this.cardUuid,
    required this.campaignId,
    required this.sharedCardId,
    required this.pushedVersion,
    required this.pushedHash,
    required this.pushedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'card_uuid': cardUuid,
      'campaign_id': campaignId,
      'shared_card_id': sharedCardId,
      'pushed_version': pushedVersion,
      'pushed_hash': pushedHash,
      'pushed_at': pushedAt.toIso8601String(),
    };
  }

  factory CardShare.fromMap(Map<String, Object?> map) {
    return CardShare(
      cardUuid: map['card_uuid'] as String,
      campaignId: map['campaign_id'] as String,
      sharedCardId: map['shared_card_id'] as String,
      pushedVersion: map['pushed_version'] as int,
      pushedHash: map['pushed_hash'] as String,
      pushedAt: DateTime.parse(map['pushed_at'] as String),
    );
  }

  CardShare copyWith({
    String? cardUuid,
    String? campaignId,
    String? sharedCardId,
    int? pushedVersion,
    String? pushedHash,
    DateTime? pushedAt,
  }) {
    return CardShare(
      cardUuid: cardUuid ?? this.cardUuid,
      campaignId: campaignId ?? this.campaignId,
      sharedCardId: sharedCardId ?? this.sharedCardId,
      pushedVersion: pushedVersion ?? this.pushedVersion,
      pushedHash: pushedHash ?? this.pushedHash,
      pushedAt: pushedAt ?? this.pushedAt,
    );
  }

  @override
  String toString() {
    return 'CardShare{cardUuid: $cardUuid, campaignId: $campaignId, sharedCardId: $sharedCardId, pushedVersion: $pushedVersion, pushedHash: $pushedHash, pushedAt: $pushedAt}';
  }
}
