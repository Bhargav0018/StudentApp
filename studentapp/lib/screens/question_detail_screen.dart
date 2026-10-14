import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/question_service.dart';

class QuestionDetailScreen extends StatefulWidget {
  final int questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  Map<String, dynamic>? question;

  List<Map<String, dynamic>> answers = [];

  final TextEditingController answerController = TextEditingController();

  bool loading = true;
  bool submittingAnswer = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD QUESTION + ANSWERS + SAVE STATUS
  // ============================================================

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final loadedQuestion = await QuestionService.instance.getQuestion(
        widget.questionId,
      );

      final loadedAnswers = await QuestionService.instance.getAnswers(
        widget.questionId,
      );

      final userId = AuthService.instance.currentUserId;

      bool saved = false;

      if (userId != null) {
        saved = await QuestionService.instance.isQuestionSaved(
          userId: userId,
          questionId: widget.questionId,
        );
      }

      if (!mounted) return;

      setState(() {
        question = loadedQuestion;
        answers = loadedAnswers;
        isSaved = saved;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load question: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SAVE / UNSAVE QUESTION
  // ============================================================

  Future<void> toggleSaveQuestion() async {
    final userId = AuthService.instance.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save questions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    try {
      if (isSaved) {
        await QuestionService.instance.unsaveQuestion(
          userId: userId,
          questionId: widget.questionId,
        );
      } else {
        await QuestionService.instance.saveQuestion(
          userId: userId,
          questionId: widget.questionId,
        );
      }

      if (!mounted) return;

      setState(() {
        isSaved = !isSaved;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'Question saved!' : 'Question removed from saved.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update saved question: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT ANSWER
  // ============================================================

  Future<void> submitAnswer() async {
    final answer = answerController.text.trim();

    final userId = AuthService.instance.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to submit an answer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write an answer first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (answer.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer should contain at least 5 characters.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      submittingAnswer = true;
    });

    try {
      await QuestionService.instance.addAnswer(
        questionId: widget.questionId,
        userId: userId,
        answer: answer,
      );

      answerController.clear();

      await loadData();

      if (!mounted) return;

      setState(() {
        submittingAnswer = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer added successfully! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        submittingAnswer = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit answer: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // HELPFUL
  // ============================================================

  Future<void> toggleHelpful(Map<String, dynamic> answer) async {
    try {
      await QuestionService.instance.toggleAnswerHelpful(answer['id']);

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update helpful status.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final date = DateTime.parse(value.toString());

      final day = date.day.toString().padLeft(2, '0');

      final month = date.month.toString().padLeft(2, '0');

      final year = date.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Question Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!loading && question != null)
            IconButton(
              tooltip: isSaved ? 'Remove from saved' : 'Save question',
              onPressed: toggleSaveQuestion,
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : question == null
          ? _buildQuestionNotFound(theme)
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  _buildQuestionCard(theme),

                  const SizedBox(height: 24),

                  _buildAnswerHeader(theme),

                  const SizedBox(height: 12),

                  _buildAnswers(theme),

                  const SizedBox(height: 24),

                  _buildAnswerForm(theme),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // QUESTION CARD
  // ============================================================

  Widget _buildQuestionCard(ThemeData theme) {
    final title = question!['title']?.toString() ?? 'Untitled Question';

    final description = question!['description']?.toString() ?? '';

    final category = question!['category']?.toString() ?? 'General';

    final userName = question!['user_name']?.toString() ?? 'Student';

    final date = formatDate(question!['created_at']);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CATEGORY
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const Spacer(),

                if (date.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // TITLE
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            // DESCRIPTION
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 12),

            // USER
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asked by',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const Spacer(),

                // SAVE BUTTON
                OutlinedButton.icon(
                  onPressed: toggleSaveQuestion,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(isSaved ? 'Saved' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANSWER HEADER
  // ============================================================

  Widget _buildAnswerHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.forum_outlined, color: theme.colorScheme.primary),

        const SizedBox(width: 8),

        Text(
          'Answers (${answers.length})',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ============================================================
  // ANSWERS
  // ============================================================

  Widget _buildAnswers(ThemeData theme) {
    if (answers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 55,
                color: theme.colorScheme.onSurfaceVariant,
              ),

              const SizedBox(height: 12),

              const Text(
                'No answers yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Be the first student to help!',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: answers.map((answer) {
        return _buildAnswerCard(theme, answer);
      }).toList(),
    );
  }

  // ============================================================
  // ANSWER CARD
  // ============================================================

  Widget _buildAnswerCard(ThemeData theme, Map<String, dynamic> answer) {
    final userName = answer['user_name']?.toString() ?? 'Student';

    final answerText = answer['answer']?.toString() ?? '';

    final helpful = answer['is_helpful'] == 1;

    final date = formatDate(answer['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER INFO
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ANSWER TEXT
            Text(answerText, style: const TextStyle(fontSize: 15, height: 1.5)),

            const SizedBox(height: 12),

            const Divider(),

            // HELPFUL BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => toggleHelpful(answer),
                icon: Icon(
                  helpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                ),
                label: Text(helpful ? 'Helpful' : 'Mark Helpful'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANSWER FORM
  // ============================================================

  Widget _buildAnswerForm(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_outlined, color: theme.colorScheme.primary),

                const SizedBox(width: 8),

                const Text(
                  'Write an Answer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Share your knowledge and help another student.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: answerController,
              maxLines: 6,
              maxLength: 1000,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Write your answer here...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.chat_outlined),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 6),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: submittingAnswer ? null : submitAnswer,
                icon: submittingAnswer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  submittingAnswer ? 'Submitting...' : 'Submit Answer',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUESTION NOT FOUND
  // ============================================================

  Widget _buildQuestionNotFound(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 16),

            const Text(
              'Question not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'This question may have been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
