import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/utils/course.dart';
import '../providers/data_providers.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(adminCoursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Course')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Course title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price (USD)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = _titleController.text.trim();
                    final description = _descriptionController.text.trim();
                    final price = double.tryParse(_priceController.text.trim());
                    final profile = ref.read(profileProvider);

                    if (title.isEmpty || description.isEmpty || price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fill all fields.')),
                      );
                      return;
                    }
                    if (profile == null) return;

                    await ref.read(adminCoursesProvider.notifier).createCourse(
                          title: title,
                          description: description,
                          price: price,
                          createdBy: profile.id,
                        );

                    _titleController.clear();
                    _descriptionController.clear();
                    _priceController.clear();
                  },
                  child: const Text('Create Course'),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Manage Courses',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              courses.when(
                data: (items) => _CourseList(items: items),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseList extends ConsumerWidget {
  const _CourseList({required this.items});

  final List<Course> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('No courses created yet.'),
      );
    }

    return Column(
      children: [
        for (final course in items)
          Card(
            child: ListTile(
              title: Text(course.title),
              subtitle: Text(course.description),
              trailing: Switch(
                value: course.isPublished,
                onChanged: (value) async {
                  await ref
                      .read(adminCoursesProvider.notifier)
                      .setPublished(course.id, value);
                },
              ),
            ),
          ),
      ],
    );
  }
}
