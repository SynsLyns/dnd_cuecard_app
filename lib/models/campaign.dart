class Campaign {
  final String id;
  final String dmId;
  final String name;
  final String joinCode;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.dmId,
    required this.name,
    required this.joinCode,
    required this.createdAt,
  });

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'] as String,
      dmId: map['dm_id'] as String,
      name: map['name'] as String,
      joinCode: map['join_code'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dm_id': dmId,
      'name': name,
      'join_code': joinCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Campaign{id: $id, name: $name, joinCode: $joinCode}';
  }
}
