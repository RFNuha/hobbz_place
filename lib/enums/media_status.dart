// Status of a media item (Planning, Ongoing, Completed, etc.)
enum MediaStatus {
  planning,
  ongoing,
  completed,
  onHold,
  dropped;

  String get displayName {
    switch (this) {
      case MediaStatus.planning:  return 'Plan to Read/Watch';
      case MediaStatus.ongoing:   return 'Ongoing';
      case MediaStatus.completed: return 'Completed';
      case MediaStatus.onHold:    return 'On Hold';
      case MediaStatus.dropped:   return 'Dropped (DNF)';
    }
  }

  String get shortLabel {
    switch (this) {
      case MediaStatus.planning:  return 'Planned';
      case MediaStatus.ongoing:   return 'Ongoing';
      case MediaStatus.completed: return 'Done';
      case MediaStatus.onHold:    return 'On Hold';
      case MediaStatus.dropped:   return 'DNF';
    }
  }
}