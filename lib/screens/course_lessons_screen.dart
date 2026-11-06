import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/course.dart';
import '../providers/course_provider.dart';
import '../theme/app_colors.dart';
import 'lesson_detail_screen.dart';

class CourseLessonsScreen extends StatefulWidget {
  final Course course;

  const CourseLessonsScreen({super.key, required this.course});

  @override
  State<CourseLessonsScreen> createState() => _CourseLessonsScreenState();
}

class _CourseLessonsScreenState extends State<CourseLessonsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = context.read<CourseProvider>();

      provider.fetchLessons(widget.course.id);

      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        provider.fetchCompletedLessonIds(
          userId: userId,
          courseId: widget.course.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Course Lessons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingLessons) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.lessonsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(provider.lessonsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        provider.fetchLessons(widget.course.id);
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.lessons.isEmpty) {
            return const Center(child: Text('No lessons available yet.'));
          }

          final lessons = provider.lessons;
          final completedCount = lessons
              .where(
                (lesson) => provider.completedLessonIds.contains(lesson.id),
              )
              .length;

          final progress = lessons.isEmpty
              ? 0.0
              : completedCount / lessons.length;

          final progressPercentage = (progress * 100).round();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.course.title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${lessons.length} lessons • ${widget.course.duration}',
                style: TextStyle(
                  color: isDark
                      ? Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              Card(
                color: isDark ? AppColors.darkCard : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Progress',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$progressPercentage%',
                            style: const TextStyle(
                              color: Color(0xFF7C6CFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF7C6CFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$completedCount of ${lessons.length} lessons completed',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ...lessons.map((lesson) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonDetailScreen(
                            lesson: lesson,
                            course: widget.course,
                            totalLessons: lessons.length,
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7C6CFF)
                          .withValues(alpha: 0.15),
                      child: Text(
                        '${lesson.order}',
                        style: const TextStyle(
                          color: Color(0xFF7C6CFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.description),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                lesson.duration,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: provider.completedLessonIds.contains(lesson.id)
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 26,
                          )
                        : const Icon(
                            Icons.play_circle_outline,
                            color: Color(0xFF7C6CFF),
                          ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
