class Program {
  final int id;
  final int version;
  final DateTime? archivedAt;

  const Program({
    required this.id,
    required this.version,
    this.archivedAt,
  });

  bool get isActive => archivedAt == null;

  Program copyWith({DateTime? archivedAt}) => Program(
        id: id,
        version: version,
        archivedAt: archivedAt ?? this.archivedAt,
      );

  Map<String, Object?> toMap() => {
        'version': version,
        'archived_at': archivedAt?.millisecondsSinceEpoch,
      };

  factory Program.fromMap(Map<String, Object?> m) => Program(
        id: m['id'] as int,
        version: m['version'] as int,
        archivedAt: m['archived_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['archived_at'] as int)
            : null,
      );
}
