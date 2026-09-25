const _monthAbbr = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// "1 sept." — day + abbreviated French month, no year (used for the
/// history list's "1 – 30 AOÛT" style period labels).
String formatShortFrDate(DateTime date) => '${date.day} ${_monthAbbr[date.month - 1]}';

/// "1 – 30 SEPT." when both dates fall in the same month, else
/// "1 SEPT. – 3 OCT." — the history card's period label.
String formatFrDateRange(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${start.day} – ${end.day} ${_monthAbbr[end.month - 1]}'.toUpperCase();
  }
  return '${formatShortFrDate(start)} – ${formatShortFrDate(end)}'.toUpperCase();
}
