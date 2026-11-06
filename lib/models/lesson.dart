class Lesson {
  final String id;
  final String title;
  final String description;
  final String duration;
  final int order;
  final String videoUrl;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.order,
    this.videoUrl = '',
  });

  factory Lesson.fromMap(String id, Map<String, dynamic> data) {
    return Lesson(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      duration: data['duration'] ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      videoUrl: data['videoUrl'] ?? '',
    );
  }
}
