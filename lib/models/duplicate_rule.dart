/// Configurable duplicate matching criteria with independent toggles.
class DuplicateMatchCriteria {
  final bool matchSize;
  final bool matchName;
  final bool matchTimestamp;
  final bool verifyHash;

  const DuplicateMatchCriteria({
    this.matchSize = true,
    this.matchName = true,
    this.matchTimestamp = false,
    this.verifyHash = false,
  });

  bool get isEnabled => matchSize || matchName || matchTimestamp || verifyHash;

  DuplicateMatchCriteria copyWith({
    bool? matchSize,
    bool? matchName,
    bool? matchTimestamp,
    bool? verifyHash,
  }) {
    return DuplicateMatchCriteria(
      matchSize: matchSize ?? this.matchSize,
      matchName: matchName ?? this.matchName,
      matchTimestamp: matchTimestamp ?? this.matchTimestamp,
      verifyHash: verifyHash ?? this.verifyHash,
    );
  }
}
