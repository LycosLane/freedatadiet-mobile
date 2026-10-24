/// Represents a user-bookmarked or default favorite folder.
class FavoriteFolder {
  final String name;
  final String path;
  final bool isDefaultStartup;

  const FavoriteFolder({
    required this.name,
    required this.path,
    this.isDefaultStartup = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'isDefaultStartup': isDefaultStartup,
    };
  }

  factory FavoriteFolder.fromMap(Map<String, dynamic> map) {
    return FavoriteFolder(
      name: map['name'] as String? ?? 'Folder',
      path: map['path'] as String? ?? '',
      isDefaultStartup: map['isDefaultStartup'] as bool? ?? false,
    );
  }

  FavoriteFolder copyWith({
    String? name,
    String? path,
    bool? isDefaultStartup,
  }) {
    return FavoriteFolder(
      name: name ?? this.name,
      path: path ?? this.path,
      isDefaultStartup: isDefaultStartup ?? this.isDefaultStartup,
    );
  }
}
