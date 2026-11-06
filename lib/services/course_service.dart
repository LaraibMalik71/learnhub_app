import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course.dart';
import '../models/lesson.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the courses collection.
  CollectionReference<Map<String, dynamic>> get _coursesCollection =>
      _firestore.collection('courses');

  // Get all courses from Firestore.
  Future<List<Course>> getCourses() async {
    final snapshot = await _coursesCollection.get();

    return snapshot.docs.map((doc) {
      return Course.fromMap(doc.id, doc.data());
    }).toList();
  }

  // Get featured courses.
  Future<List<Course>> getFeaturedCourses() async {
    final snapshot = await _coursesCollection
        .where('isFeatured', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      return Course.fromMap(doc.id, doc.data());
    }).toList();
  }

  // Add a new course to Firestore.
  Future<void> addCourse(Course course) async {
    await _coursesCollection.doc(course.id).set(course.toMap());
  }

  // Enroll a student in a course without allowing duplicates.
  Future<bool> enrollInCourse(String userId, Course course) async {
    final enrollmentRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(course.id);

    final courseRef = _firestore.collection('courses').doc(course.id);

    return await _firestore.runTransaction((transaction) async {
      // Check whether the student is already enrolled.
      final enrollmentSnapshot = await transaction.get(enrollmentRef);

      if (enrollmentSnapshot.exists) {
        return false;
      }

      // Get the current course information.
      final courseSnapshot = await transaction.get(courseRef);

      if (!courseSnapshot.exists) {
        return false;
      }

      // Get the current enrollment count.
      final currentCount =
          (courseSnapshot.data()?['enrollmentCount'] as num?)?.toInt() ?? 0;

      // Create the student's enrollment.
      transaction.set(enrollmentRef, {
        'courseId': course.id,
        'courseTitle': course.title,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0,
        'completedLessons': 0,
        'status': 'active',
      });

      // Increase the course enrollment count.
      transaction.update(courseRef, {'enrollmentCount': currentCount + 1});

      return true;
    });
  }

  // Check whether a student is already enrolled in a course.
  Future<bool> isEnrolled(String userId, String courseId) async {
    final enrollmentDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId)
        .get();

    return enrollmentDoc.exists;
  }

  // Get one course by its document ID.
  Future<Course?> getCourseById(String courseId) async {
    final doc = await _coursesCollection.doc(courseId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Course.fromMap(doc.id, doc.data()!);
  }

  // Get all courses enrolled by a student.
  Future<List<Course>> getEnrolledCourses(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .get();

    final courseIds = snapshot.docs.map((doc) => doc.id).toList();

    final courses = await Future.wait(
      courseIds.map((courseId) => getCourseById(courseId)),
    );

    return courses.whereType<Course>().toList();
  }

  // Get saved progress for all enrolled courses.
  Future<Map<String, int>> getEnrolledCourseProgress(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .get();

    final progressMap = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      progressMap[doc.id] = (data['progress'] as num?)?.toInt() ?? 0;
    }

    return progressMap;
  }

  // Get all lessons for a specific course.
  //
  // Get all lessons for a specific course.

  Future<List<Lesson>> getLessons(String courseId) async {
    final snapshot = await _coursesCollection
        .doc(courseId)
        .collection('lessons')
        .get();

    final lessons = snapshot.docs.map((doc) {
      return Lesson.fromMap(doc.id, doc.data());
    }).toList();

    // Sort lessons by their order field in Dart.
    lessons.sort((a, b) => a.order.compareTo(b.order));

    return lessons;
  }

  // Mark a lesson as completed and update course progress.
  Future<void> markLessonCompleted({
    required String userId,
    required String courseId,
    required String lessonId,
    required int totalLessons,
  }) async {
    final enrollmentRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId);

    await _firestore.runTransaction((transaction) async {
      final enrollmentSnapshot = await transaction.get(enrollmentRef);

      if (!enrollmentSnapshot.exists) {
        throw Exception('Course enrollment not found.');
      }

      final data = enrollmentSnapshot.data()!;

      final completedLessonIds = List<String>.from(
        data['completedLessonIds'] ?? [],
      );

      // Prevent counting the same lesson more than once.
      if (completedLessonIds.contains(lessonId)) {
        return;
      }

      completedLessonIds.add(lessonId);

      final completedCount = completedLessonIds.length;
      final progress = totalLessons > 0
          ? ((completedCount / totalLessons) * 100).round()
          : 0;

      transaction.update(enrollmentRef, {
        'completedLessonIds': completedLessonIds,
        'completedLessons': completedCount,
        'progress': progress,
        'status': completedCount >= totalLessons ? 'completed' : 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get the IDs of lessons completed by a student.
  Future<List<String>> getCompletedLessonIds({
    required String userId,
    required String courseId,
  }) async {
    final enrollmentRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId);

    final snapshot = await enrollmentRef.get();

    if (!snapshot.exists) {
      return [];
    }

    final data = snapshot.data();
    final completedLessonIds = data?['completedLessonIds'];

    if (completedLessonIds is List) {
      return completedLessonIds.whereType<String>().toList();
    }

    return [];
  }
}
