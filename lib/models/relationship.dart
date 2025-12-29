class Relationship {
  final int parent1Id;
  final int parent2Id;
  final int childId;

  Relationship({
    required this.parent1Id,
    required this.parent2Id,
    required this.childId,
  }) : assert(parent1Id != parent2Id, 'Parents must be different'),
       assert(parent1Id < parent2Id, 'Parent1Id must be less than parent2Id for ordering');

  Map<String, dynamic> toMap() {
    return {
      'parent1_id': parent1Id,
      'parent2_id': parent2Id,
      'child_id': childId,
    };
  }

  factory Relationship.fromMap(Map<String, dynamic> map) {
    return Relationship(
      parent1Id: map['parent1_id'] as int,
      parent2Id: map['parent2_id'] as int,
      childId: map['child_id'] as int,
    );
  }
}