/// Represents a location or favorite folder in the top-left menu.
class SavedLocation {
  final String id;
  final String name;
  final String path;
  final String type; // 'internal', 'external', 'favorite', 'apps_diet'

  const SavedLocation({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
  });

  bool get isAppsDiet => type == 'apps_diet';
  bool get isFavorite => type == 'favorite';
  bool get isExternal => type == 'external';
  bool get isInternal => type == 'internal';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type,
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Folder',
      path: map['path'] as String? ?? '',
      type: map['type'] as String? ?? 'favorite',
    );
  }

  SavedLocation copyWith({
    String? id,
    String? name,
    String? path,
    String? type,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
