import 'package:flutter/material.dart';

import '../../core/utils/path_rules.dart';
import '../../models/storage_item.dart';
import '../../services/file_delete_service.dart';
import 'delete_confirm_dialog.dart';

/// The full delete interaction: protection check, confirmation, background deletion
/// behind a progress dialog, and an honest result message.
class DeleteFlow {
  DeleteFlow._();

  /// Returns true if a deletion was attempted (the caller should rescan).
  static Future<bool> run(
    BuildContext context,
    List<StorageItem> selectedItems,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    void say(String text) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
        );
    }

    final deletable = selectedItems
        .where((i) => !PathRules.isProtectedForDelete(i.path))
        .toList();
    if (deletable.isEmpty) {
      say(
        'Storage roots and the Android folder are protected and cannot be deleted.',
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmDialog(
        selectedItems: deletable,
        protectedCount: selectedItems.length - deletable.length,
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    // Deleting can take a while for big folders, so it runs in the background behind a progress dialog.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Text('Deleting...'),
            ],
          ),
        ),
      ),
    );

    final result = await FileDeleteService.deleteItems(
      deletable.map((e) => e.path).toList(),
    );
    navigator.pop();

    if (result.hasFailures) {
      say(
        'Deleted ${result.deleted}. ${result.failed.length} could not be deleted '
        '(read-only storage, in use, or removed).',
      );
    } else {
      say(
        'Deleted ${result.deleted} ${result.deleted == 1 ? 'item' : 'items'}.',
      );
    }
    return true;
  }
}
