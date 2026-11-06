class Course {
  final String id;
  final String title;
  final String instructor;
  final String description;
  final String thumbnail;
  final String duration;
  final String category;
  final bool isFeatured;
  final int totalLessons;
  final int enrollmentCount;

  const Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.description,
    required this.thumbnail,
    required this.duration,
    required this.category,
    this.isFeatured = false,
    this.totalLessons = 0,
    this.enrollmentCount = 0,
  });

  // Convert Firestore document data into a Course object.
  factory Course.fromMap(String id, Map<String, dynamic> data) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      instructor: data['instructor'] ?? '',
      description: data['description'] ?? '',
      thumbnail: data['thumbnail'] ?? '',
      duration: data['duration'] ?? '',
      category: data['category'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      totalLessons: data['totalLessons'] ?? 0,
      enrollmentCount: data['enrollmentCount'] ?? 0,
    );
  }

  // Convert a Course object into Firestore-compatible data.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'instructor': instructor,
      'description': description,
      'thumbnail': thumbnail,
      'duration': duration,
      'category': category,
      'isFeatured': isFeatured,
      'totalLessons': totalLessons,
      'enrollmentCount': enrollmentCount,
    };
  }
}
