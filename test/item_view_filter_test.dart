import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/models/user_settings.dart';
import 'package:freedatadiet_mobile/services/item_view_filter.dart';

StorageItem _file(String name, int size, {DateTime? date, bool dup = false}) {
  final dot = name.lastIndexOf('.');
  return StorageItem(
    path: '/t/$name',
    name: name,
    isDirectory: false,
    size: size,
    extension: dot == -1 ? '' : name.substring(dot).toLowerCase(),
    lastModified: date,
    isDuplicate: dup,
  );
}

StorageItem _dir(String name, {int size = 0, bool scanning = false}) =>
    StorageItem(
      path: '/t/$name',
      name: name,
      isDirectory: true,
      size: size,
      isScanning: scanning,
    );

void main() {
  final items = [
    _file('photo.jpg', 300),
    _file('clip.mp4', 900),
    _file('song.mp3', 50),
    _file('doc.pdf', 20),
    _file('bundle.zip', 70),
    _file('.hidden', 1),
    _dir('folder', size: 400),
  ];

  List<String> names(UserSettings s, {String q = ''}) => ItemViewFilter.apply(
    items: items,
    settings: s,
    searchQuery: q,
  ).map((i) => i.name).toList();

  test(
    'default shows everything except hidden, largest first, folders on top',
    () {
      expect(names(const UserSettings()), [
        'folder',
        'clip.mp4',
        'photo.jpg',
        'bundle.zip',
        'song.mp3',
        'doc.pdf',
      ]);
    },
  );

  test('opt-out switches hide their file types only', () {
    final n = names(const UserSettings(showImages: false, showVideos: false));
    expect(n.contains('photo.jpg'), false);
    expect(n.contains('clip.mp4'), false);
    expect(n.contains('song.mp3'), true);
    expect(n.contains('folder'), true);
  });

  test('hidden files appear when enabled', () {
    expect(
      names(const UserSettings(showHiddenFiles: true)).contains('.hidden'),
      true,
    );
  });

  test('search matches name or extension', () {
    expect(names(const UserSettings(), q: 'pdf'), ['doc.pdf']);
    expect(names(const UserSettings(), q: 'PHOTO'), ['photo.jpg']);
  });

  test('only duplicates hides unique files and folders', () {
    final dupItems = [
      _file('a.bin', 1, dup: true),
      _file('b.bin', 2),
      _dir('d'),
    ];
    final result = ItemViewFilter.apply(
      items: dupItems,
      settings: const UserSettings(showDuplicatesOnly: true),
    );
    expect(result.map((i) => i.name), ['a.bin']);
  });

  test('name sort toggles direction', () {
    final asc = ItemViewFilter.apply(
      items: items,
      settings: const UserSettings(
        sortColumn: SortColumn.name,
        sortDescending: false,
      ),
    );
    expect(asc.first.name, 'folder'); // folders stay grouped on top
    expect(asc[1].name, 'bundle.zip');
  });

  test('folders still being measured stay on top when sorting by size', () {
    final withScanning = [..._dirsAndFiles(), _dir('big', scanning: true)];
    final result = ItemViewFilter.apply(
      items: withScanning,
      settings: const UserSettings(),
    );
    expect(result.first.name, 'big');
  });
}

List<StorageItem> _dirsAndFiles() => [
  _dir('small', size: 5),
  _file('f.txt', 10),
];
