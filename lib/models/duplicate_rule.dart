/// Criteria options used to determine if two or more files are duplicates.
enum DuplicateMatchMode {
  nameAndSize('Same Name & Same Size', 'Matches files with exact identical filename and byte size.'),
  sizeOnly('Same Size Only', 'Matches files with exact same byte count (catches renamed clones).'),
  nameOnly('Same Name Only', 'Matches files sharing identical names across different folders.'),
  timestampOnly('Same Timestamp Only', 'Matches files modified at the identical timestamp.'),
  nameSizeAndTimestamp('Same Name, Size & Timestamp', 'Strict match on filename, bytes, and timestamp (ideal for photos).');

  final String label;
  final String description;

  const DuplicateMatchMode(this.label, this.description);
}

/// Helper model for clustered duplicates.
class DuplicateGroup {
  final String groupId;
  final String key;
  final List<String> filePaths;
  final int individualSizeBytes;

  const DuplicateGroup({
    required this.groupId,
    required this.key,
    required this.filePaths,
    required this.individualSizeBytes,
  });

  int get totalWastedBytes => (filePaths.length - 1) * individualSizeBytes;
}
