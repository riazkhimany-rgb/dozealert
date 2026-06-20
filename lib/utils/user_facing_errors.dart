abstract final class UserFacingErrors {
  static String from(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timed out') ||
        message.contains('timeout')) {
      return 'No network connection. Check your internet and try again.';
    }

    if (message.contains('zip') ||
        message.contains('archive') ||
        message.contains('invalid') && message.contains('file')) {
      return 'Invalid GTFS zip file. Choose a valid transit feed archive.';
    }

    if (message.contains('404') || message.contains('not found')) {
      return 'Feed unavailable. The download link may have changed.';
    }

    if (message.contains('403') || message.contains('forbidden')) {
      return 'Feed download blocked. Open the agency data page instead.';
    }

    if (message.contains('permission') || message.contains('denied')) {
      return 'Permission denied. Check app permissions and try again.';
    }

    if (message.contains('parse') || message.contains('format')) {
      return 'Could not read this transit feed. The file may be incomplete.';
    }

    return 'Something went wrong. Please try again.';
  }
}
