/// Configurable duplicate matching criteria with independent toggles.
class DuplicateMatchCriteria {
  final bool matchSize;
  final bool matchName;
  final bool matchTimestamp;

  const DuplicateMatchCriteria({
    this.matchSize = true,
    this.matchName = true,
    this.matchTimestamp = false,
  });

  bool get isEnabled => matchSize || matchName || matchTimestamp;

  DuplicateMatchCriteria copyWith({
    bool? matchSize,
    bool? matchName,
    bool? matchTimestamp,
  }) {
    return DuplicateMatchCriteria(
      matchSize: matchSize ?? this.matchSize,
      matchName: matchName ?? this.matchName,
      matchTimestamp: matchTimestamp ?? this.matchTimestamp,
    );
  }
}
