import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../theme/app_colors.dart';
import '../widgets/course_thumbnail.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import 'course_lessons_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEnrollment();
    });
  }

  Future<void> _checkEnrollment() async {
    final userId = context.read<AuthProvider>().user?.uid;

    if (userId != null) {
      await context.read<CourseProvider>().checkEnrollment(
        userId,
        widget.course.id,
      );
    }
  }

  Future<void> _enroll() async {
    final userId = context.read<AuthProvider>().user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to enroll in this course.'),
        ),
      );
      return;
    }

    try {
      final created = await context.read<CourseProvider>().enrollInCourse(
        userId,
        widget.course,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created
                ? 'Successfully enrolled in this course!'
                : 'You are already enrolled in this course.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to enroll. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Course Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course thumbnail
            CourseThumbnail(
              imagePath: widget.course.thumbnail,
              width: double.infinity,
              height: 210,
              borderRadius: 20,
            ),
            const SizedBox(height: 24),

            // Course category
            Text(
              widget.course.category,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            // Course title
            Text(
              widget.course.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Instructor
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instructor: ${widget.course.instructor}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Course information
            Text(
              'Course Information',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    icon: Icons.access_time_rounded,
                    label: 'Duration',
                    value: widget.course.duration,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    icon: Icons.play_lesson_rounded,
                    label: 'Total Lessons',
                    value: '${widget.course.totalLessons}',
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Description
            Text(
              'About This Course',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              widget.course.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.7,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // Enrollment button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Consumer<CourseProvider>(
            builder: (context, courseProvider, child) {
              final enrollmentStatus = courseProvider.enrollmentStatusFor(
                widget.course.id,
              );

              if (courseProvider.isCheckingEnrollment ||
                  enrollmentStatus == null) {
                return SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: courseProvider.isCheckingEnrollment
                        ? null
                        : _checkEnrollment,
                    child: courseProvider.isCheckingEnrollment
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Check Enrollment Again'),
                  ),
                );
              }

              if (enrollmentStatus) {
                return SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseLessonsScreen(course: widget.course),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Continue Learning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: courseProvider.isEnrolling ? null : _enroll,
                  child: courseProvider.isEnrolling
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enroll Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 25),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
