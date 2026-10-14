import 'package:flutter/material.dart';
import '../widgets/student_navigation.dart';

import '../services/auth_service.dart';
import '../services/question_service.dart';
import '../services/notification_service.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final titleController = TextEditingController();

  final descriptionController = TextEditingController();

  String selectedCategory = 'Programming';

  bool loading = false;

  final categories = [
    'Programming',
    'Academics',
    'Projects',
    'Placements',
    'Career',
    'General',
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitQuestion() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));

      return;
    }

    final userId = AuthService.instance.currentUserId;

    if (userId == null) {
      return;
    }

    setState(() {
      loading = true;
    });

    await QuestionService.instance.addQuestion(
      userId: userId,
      title: titleController.text,
      description: descriptionController.text,
      category: selectedCategory,
    );

    await NotificationService.instance.createNotification(
      userId: userId,
      title: 'Question Posted',
      message: 'Your question was successfully posted.',
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question posted successfully!')),
    );

    Navigator.pop(context, true);
  }

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _navigateFromShell(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.pushNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ask a Question',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFFFF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 60,
                      color: Color(0xFF4F46E5),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'What do you need help with?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: titleController,
                      decoration: decoration('Question Title', Icons.title),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: decoration('Category', Icons.category),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: descriptionController,
                      maxLines: 7,
                      decoration: decoration(
                        'Describe your question',
                        Icons.description,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : submitQuestion,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(loading ? 'Posting...' : 'Post Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? StudentBottomNavigation(selectedIndex: 2, onSelected: _navigateFromShell)
          : null,
    );
  }
}
