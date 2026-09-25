/// القسم 26 — Case Timeline. Append-only، لا حذف من الأحداث.
class TimelineEvent {
  final String label;
  final DateTime at;
  final String? actorName;
  final String? note;

  const TimelineEvent({
    required this.label,
    required this.at,
    this.actorName,
    this.note,
  });
}

class CaseTimelineSection {
  final List<TimelineEvent> events;

  const CaseTimelineSection({required this.events});
}
