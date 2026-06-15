class NameRecord {
  final int id;
  final String name;
  final DateTime createdAt;

  const NameRecord({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Factory for parsing Supabase database map response into a strongly-typed model.
  factory NameRecord.fromJson(Map<String, dynamic> json) {
    return NameRecord(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  /// Converts the model instance back to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
