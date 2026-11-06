import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../providers/course_provider.dart';
import '../models/lesson.dart';
import '../theme/app_colors.dart';
import '../models/course.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;
  final int totalLessons;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.course,
    required this.totalLessons,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  bool _isVideoLoading = false;
  bool _hasVideoError = false;
  bool _hasHandledVideoEnd = false;
  void _videoListener() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isCompleted && !_hasHandledVideoEnd) {
      _hasHandledVideoEnd = true;

      _resetVideoToBeginning();

      if (mounted) {
        setState(() {});
      }
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resetVideoToBeginning() async {
    final controller = _videoController;

    if (controller == null) return;

    await controller.pause();
    await controller.seekTo(Duration.zero);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeLessonVideo();
  }

  void _initializeLessonVideo() {
    final videoUrl = widget.lesson.videoUrl.trim();

    if (videoUrl.isEmpty) return;

    final uri = Uri.tryParse(videoUrl);
    final host = uri?.host.toLowerCase() ?? '';

    final isYoutubeUrl =
        host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be' ||
        host.endsWith('.youtu.be');

    if (isYoutubeUrl) {
      final videoId = _extractYoutubeVideoId(videoUrl);

      if (videoId == null) {
        _hasVideoError = true;
        return;
      }

      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
        ),
      );
    } else {
      _initializeMp4Player(videoUrl);
    }
  }

  String? _extractYoutubeVideoId(String videoUrl) {
    final uri = Uri.tryParse(videoUrl);

    if (uri == null) return null;

    if (uri.host == 'youtu.be' || uri.host.endsWith('.youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    final videoId = uri.queryParameters['v'];

    if (videoId != null && videoId.isNotEmpty) {
      return videoId;
    }

    final segments = uri.pathSegments;

    for (final type in ['embed', 'shorts', 'live']) {
      final index = segments.indexOf(type);

      if (index != -1 && index + 1 < segments.length) {
        return segments[index + 1];
      }
    }

    return null;
  }

  Future<void> _initializeMp4Player(String videoUrl) async {
    setState(() {
      _isVideoLoading = true;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      _videoController = controller;

      await controller.initialize();
      await controller.setLooping(false);
      controller.addListener(_videoListener);

      if (!mounted) return;

      setState(() {
        _isVideoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVideoLoading = false;
        _hasVideoError = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      _hasHandledVideoEnd = false;
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  Widget _buildVideoSection(bool isDark) {
    final videoUrl = widget.lesson.videoUrl.trim();
    final controller = _videoController;

    if (videoUrl.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF7C6CFF).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.play_circle_outline,
          size: 80,
          color: Color(0xFF7C6CFF),
        ),
      );
    }

    if (_hasVideoError) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 45, color: Color(0xFF7C6CFF)),
              SizedBox(height: 10),
              Text('Unable to load video. Check your video URL or connection.'),
            ],
          ),
        ),
      );
    }

    // YouTube video player
    if (_youtubeController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: YoutubePlayer(
          controller: _youtubeController!,
          aspectRatio: 16 / 9,
        ),
      );
    }

    // MP4 loading state
    if (_isVideoLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C6CFF)),
        ),
      );
    }

    // MP4 error state
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('Unable to load video. Check your connection.'),
        ),
      );
    }

    // Existing MP4 player
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: _togglePlayback,
                  color: Colors.white,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    size: 32,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF7C6CFF),
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(controller.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(controller.value.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lesson Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildVideoSection(isDark)),
            const SizedBox(height: 24),

            Text(
              'Lesson ${widget.lesson.order}',
              style: const TextStyle(
                color: Color(0xFF7C6CFF),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              widget.lesson.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFF7C6CFF),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.lesson.duration,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text(
              'About this lesson',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text(
              widget.lesson.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.7,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

            if (widget.lesson.videoUrl.trim().isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF7C6CFF)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Video content is not available for this lesson yet.',
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            Consumer<CourseProvider>(
              builder: (context, provider, child) {
                final userId = FirebaseAuth.instance.currentUser?.uid;

                final isCompleted = provider.completedLessonIds.contains(
                  widget.lesson.id,
                );

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        userId == null ||
                            isCompleted ||
                            provider.isMarkingLessonCompleted
                        ? null
                        : () async {
                            final success = await provider.markLessonCompleted(
                              userId: userId,
                              courseId: widget.course.id,
                              lessonId: widget.lesson.id,
                              totalLessons: widget.totalLessons,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Lesson completed successfully!'
                                      : provider.lessonCompletionError ??
                                            'Unable to update progress.',
                                ),
                              ),
                            );
                          },
                    icon: provider.isMarkingLessonCompleted
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                          ),
                    label: Text(
                      provider.isMarkingLessonCompleted
                          ? 'Updating Progress...'
                          : isCompleted
                          ? 'Completed'
                          : 'Mark as Completed',
                    ),
                    style: isCompleted
                        ? ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.green,
                            disabledForegroundColor: Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
