import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/course_thumbnail.dart';
import 'profile_screen.dart';
import 'courses_screen.dart';
import 'course_details_screen.dart';

import 'package:provider/provider.dart';

import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    context.read<CourseProvider>().fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _titles = [
    'LearnHub',
    'Courses',
    'My Learning',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(context),
          const CoursesScreen(),
          _buildMyLearning(context),
          const ProfileScreen(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.read<CourseProvider>().clearCategoryFilter();
          }

          if (index == 2) {
            final userId = context.read<AuthProvider>().user?.uid;

            if (userId != null) {
              context.read<CourseProvider>().fetchEnrolledCourses(userId);
            }
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'My Learning',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Learner! 👋',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to learn today?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Course Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search courses by name, instructor or category',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSearchResults(context),
            ],

            const SizedBox(height: 28),

            // Featured learning card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Learn Something New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore courses, develop new skills and grow your future.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CourseProvider>().clearCategoryFilter();

                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Explore Courses'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // Featured Courses section
            Text(
              'Featured Courses',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildFeaturedCourses(context),

            const SizedBox(height: 30),
            // Popular Courses section
            Text(
              'Popular Courses',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildPopularCourses(context),

            const SizedBox(height: 30),

            // Categories section
            Text(
              'Explore Categories',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.45,
              children: [
                _CategoryCard(
                  title: 'Programming',
                  icon: Icons.code_rounded,
                  onTap: () => _openCategory('Programming'),
                ),
                _CategoryCard(
                  title: 'Design',
                  icon: Icons.palette_rounded,
                  onTap: () => _openCategory('Design'),
                ),
                _CategoryCard(
                  title: 'Marketing',
                  icon: Icons.campaign_rounded,
                  onTap: () => _openCategory('Marketing'),
                ),
                _CategoryCard(
                  title: 'Data Science',
                  icon: Icons.analytics_rounded,
                  onTap: () => _openCategory('Data Science'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final query = _searchQuery.trim().toLowerCase();

        final results = courseProvider.courses.where((course) {
          return course.title.toLowerCase().contains(query) ||
              course.instructor.toLowerCase().contains(query) ||
              course.category.toLowerCase().contains(query);
        }).toList();

        if (courseProvider.isLoading && courseProvider.courses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No courses found. Try another search.')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...results.map(
              (course) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: CourseThumbnail(
                    imagePath: course.thumbnail,
                    width: 54,
                    height: 54,
                    borderRadius: 27,
                  ),
                  title: Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${course.instructor} • ${course.category}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailsScreen(course: course),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCategory(String category) {
    context.read<CourseProvider>().filterCoursesByCategory(category);

    setState(() {
      _selectedIndex = 1;
    });
  }

  Widget _buildFeaturedCourses(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        if (courseProvider.isLoading &&
            courseProvider.featuredCourses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (courseProvider.featuredCourses.isEmpty) {
          return const Text('No featured courses available yet.');
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courseProvider.featuredCourses.length,
            itemBuilder: (context, index) {
              final course = courseProvider.featuredCourses[index];

              return SizedBox(
                width: 270,
                child: Card(
                  margin: const EdgeInsets.only(right: 14),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseDetailsScreen(course: course),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CourseThumbnail(
                            imagePath: course.thumbnail,
                            width: 70,
                            height: 70,
                            borderRadius: 12,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            course.category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      course.instructor,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(course.duration),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularCourses(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final courses = courseProvider.popularCourses;

        if (courses.isEmpty) {
          return const Text('No popular courses available yet.');
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];

              return SizedBox(
                width: 270,
                child: Card(
                  margin: const EdgeInsets.only(right: 14),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseDetailsScreen(course: course),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CourseThumbnail(
                            imagePath: course.thumbnail,
                            width: 70,
                            height: 70,
                            borderRadius: 12,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            course.category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_outline_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text('${course.enrollmentCount} enrolled'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(course.duration),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyLearning(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        if (courseProvider.isLoadingEnrolledCourses) {
          return const Center(child: CircularProgressIndicator());
        }

        if (courseProvider.enrolledCoursesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 55,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(courseProvider.enrolledCoursesError!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final userId = context.read<AuthProvider>().user?.uid;

                    if (userId != null) {
                      courseProvider.fetchEnrolledCourses(userId);
                    }
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (courseProvider.enrolledCourses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 65,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No Enrolled Courses Yet',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Courses you enroll in will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CourseProvider>().clearCategoryFilter();
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: const Text('Explore Courses'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Continue Your Learning',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${courseProvider.enrolledCourses.length} enrolled course(s)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            ...courseProvider.enrolledCourses.map(
              (course) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                color: Theme.of(context).cardColor,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CourseThumbnail(
                    imagePath: course.thumbnail,
                    width: 54,
                    height: 54,
                    borderRadius: 27,
                  ),
                  title: Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${course.instructor}\n${course.duration}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Progress',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${courseProvider.enrolledCourseProgress[course.id] ?? 0}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value:
                                (courseProvider.enrolledCourseProgress[course
                                        .id] ??
                                    0) /
                                100,
                            minHeight: 7,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white12
                                : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: false,
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailsScreen(course: course),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _CategoryCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
