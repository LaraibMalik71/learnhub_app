import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/lesson.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _courseService = CourseService();
  // Stores lessons for the selected course.
  List<Lesson> _lessons = [];
  // Stores IDs of lessons completed by the current student.
  List<String> _completedLessonIds = [];

  List<String> get completedLessonIds => _completedLessonIds;

  bool _isLoadingLessons = false;
  String? _lessonsError;

  List<Lesson> get lessons => _lessons;

  bool get isLoadingLessons => _isLoadingLessons;

  String? get lessonsError => _lessonsError;
  // Stores enrollment status for each course.
  final Map<String, bool> _enrollmentStatus = {};

  bool? enrollmentStatusFor(String courseId) {
    return _enrollmentStatus[courseId];
  }

  bool _isCheckingEnrollment = false;

  bool get isCheckingEnrollment => _isCheckingEnrollment;

  bool _isEnrolling = false;
  String? _enrollmentError;

  bool get isEnrolling => _isEnrolling;
  String? get enrollmentError => _enrollmentError;
  bool _isMarkingLessonCompleted = false;
  String? _lessonCompletionError;

  bool get isMarkingLessonCompleted => _isMarkingLessonCompleted;

  String? get lessonCompletionError => _lessonCompletionError;

  List<Course> _courses = [];
  List<Course> _featuredCourses = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Get all courses.
  List<Course> get courses => _courses;
  // Courses filtered by the selected category.
  List<Course> _filteredCourses = [];
  String? _selectedCategory;

  List<Course> get filteredCourses => _filteredCourses;
  String? get selectedCategory => _selectedCategory;

  // Get featured courses.
  List<Course> get featuredCourses => _featuredCourses;
  // Courses enrolled by the current student.
  List<Course> _enrolledCourses = [];
  // Stores progress for each enrolled course.
  Map<String, int> _enrolledCourseProgress = {};

  Map<String, int> get enrolledCourseProgress => _enrolledCourseProgress;

  bool _isLoadingEnrolledCourses = false;
  String? _enrolledCoursesError;

  List<Course> get enrolledCourses => _enrolledCourses;

  bool get isLoadingEnrolledCourses => _isLoadingEnrolledCourses;

  String? get enrolledCoursesError => _enrolledCoursesError;

  // Get loading status.
  bool get isLoading => _isLoading;

  // Get error message.
  String? get errorMessage => _errorMessage;

  // Fetch all courses from Firestore.
  Future<void> fetchCourses() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _courses = await _courseService.getCourses();

      _featuredCourses = _courses.where((course) => course.isFeatured).toList();
    } catch (e) {
      _errorMessage = 'Unable to load courses. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  List<Course> get popularCourses {
    final sortedCourses = List<Course>.from(_courses);

    sortedCourses.sort(
      (a, b) => b.enrollmentCount.compareTo(a.enrollmentCount),
    );

    return sortedCourses.take(3).toList();
  }

  // Fetch featured courses separately.
  Future<void> fetchFeaturedCourses() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _featuredCourses = await _courseService.getFeaturedCourses();
    } catch (e) {
      _errorMessage = 'Unable to load featured courses.';
    } finally {
      _setLoading(false);
    }
  }

  // Refresh course data.
  Future<void> refreshCourses() async {
    await fetchCourses();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Filter courses by category.
  void filterCoursesByCategory(String category) {
    _selectedCategory = category;

    _filteredCourses = _courses
        .where(
          (course) => course.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();

    notifyListeners();
  }

  // Clear category filter.
  void clearCategoryFilter() {
    _selectedCategory = null;
    _filteredCourses = [];
    notifyListeners();
  }

  // Fetch all courses enrolled by the current student.
  Future<void> fetchEnrolledCourses(String userId) async {
    _isLoadingEnrolledCourses = true;
    _enrolledCoursesError = null;
    notifyListeners();

    try {
      _enrolledCourses = await _courseService.getEnrolledCourses(userId);
      _enrolledCourseProgress = await _courseService.getEnrolledCourseProgress(
        userId,
      );
    } catch (e) {
      _enrolledCoursesError = 'Unable to load your enrolled courses.';
    } finally {
      _isLoadingEnrolledCourses = false;
      notifyListeners();
    }
  }

  // Check whether the student is already enrolled.
  Future<void> checkEnrollment(String userId, String courseId) async {
    _isCheckingEnrollment = true;
    notifyListeners();

    try {
      final enrolled = await _courseService.isEnrolled(userId, courseId);

      _enrollmentStatus[courseId] = enrolled;
    } catch (e) {
      _enrollmentStatus.remove(courseId);
    } finally {
      _isCheckingEnrollment = false;
      notifyListeners();
    }
  }

  // Enroll the current student in a course.
  Future<bool> enrollInCourse(String userId, Course course) async {
    _isEnrolling = true;
    _enrollmentError = null;
    notifyListeners();

    try {
      final isEnrolled = await _courseService.enrollInCourse(userId, course);
      _enrollmentStatus[course.id] = true;
      if (isEnrolled) {
        _enrolledCourses = [..._enrolledCourses, course];
      }

      return isEnrolled;
    } catch (e) {
      _enrollmentError = 'Unable to enroll. Please try again.';
      rethrow;
    } finally {
      _isEnrolling = false;
      notifyListeners();
    }
  }

  // Fetch lessons for a specific course.
  Future<void> fetchLessons(String courseId) async {
    _isLoadingLessons = true;
    _lessonsError = null;
    notifyListeners();

    try {
      _lessons = await _courseService.getLessons(courseId);
    } catch (e) {
      _lessonsError = 'Unable to load lessons. Please try again.';
    } finally {
      _isLoadingLessons = false;
      notifyListeners();
    }
  }

  // Mark a lesson as completed.
  Future<bool> markLessonCompleted({
    required String userId,
    required String courseId,
    required String lessonId,
    required int totalLessons,
  }) async {
    _isMarkingLessonCompleted = true;
    _lessonCompletionError = null;
    notifyListeners();

    try {
      await _courseService.markLessonCompleted(
        userId: userId,
        courseId: courseId,
        lessonId: lessonId,
        totalLessons: totalLessons,
      );

      // Update the local completion list immediately.
      if (!_completedLessonIds.contains(lessonId)) {
        _completedLessonIds = [..._completedLessonIds, lessonId];
      }

      // Refresh enrolled course progress from Firestore.
      await fetchEnrolledCourses(userId);

      return true;
    } catch (e) {
      _lessonCompletionError =
          'Unable to update lesson progress. Please try again.';
      return false;
    } finally {
      _isMarkingLessonCompleted = false;
      notifyListeners();
    }
  }

  // Fetch completed lesson IDs for a specific course.
  Future<void> fetchCompletedLessonIds({
    required String userId,
    required String courseId,
  }) async {
    try {
      _completedLessonIds = await _courseService.getCompletedLessonIds(
        userId: userId,
        courseId: courseId,
      );
    } catch (e) {
      _completedLessonIds = [];
    }

    notifyListeners();
  }
}
