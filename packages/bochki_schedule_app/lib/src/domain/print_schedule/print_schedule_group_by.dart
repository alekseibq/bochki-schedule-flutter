enum PrintScheduleGroupBy {
  byNames(label: 'По фамилиям', fileSlug: 'po-familiyam'),
  byTime(label: 'По времени', fileSlug: 'po-vremeni');

  const PrintScheduleGroupBy({
    required this.label,
    required this.fileSlug,
  });

  final String label;
  final String fileSlug;
}
