import 'package:flutter/material.dart';

import '../services/question_service.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';
import '../widgets/premium_ui.dart';
import '../widgets/student_navigation.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allQuestions = [];
  List<Map<String, dynamic>> questions = [];

  List<String> categories = ['All Categories'];

  String selectedCategory = 'All Categories';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD QUESTIONS
  // =========================================================

  Future<void> loadQuestions() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final result = await QuestionService.instance.getQuestions();

      if (!mounted) return;

      setState(() {
        allQuestions = result;
        _buildCategories();
        _applyFilters();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        allQuestions = [];
        questions = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load questions: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // BUILD CATEGORY LIST
  // =========================================================

  void _buildCategories() {
    final Set<String> uniqueCategories = {};

    for (final question in allQuestions) {
      final category = question['category']?.toString().trim();

      if (category != null && category.isNotEmpty) {
        uniqueCategories.add(category);
      }
    }

    final sortedCategories = uniqueCategories.toList()..sort();

    categories = ['All Categories', ...sortedCategories];

    // If the selected category was deleted / no longer exists,
    // reset the filter.
    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'All Categories';
    }
  }

  // =========================================================
  // SEARCH + CATEGORY FILTER
  // =========================================================

  void _applyFilters() {
    final searchText = searchController.text.trim().toLowerCase();

    questions = allQuestions.where((question) {
      final title = question['title']?.toString().toLowerCase() ?? '';

      final description =
          question['description']?.toString().toLowerCase() ?? '';

      final category = question['category']?.toString().toLowerCase() ?? '';

      final userName = question['user_name']?.toString().toLowerCase() ?? '';

      // Search condition
      final matchesSearch =
          searchText.isEmpty ||
          title.contains(searchText) ||
          description.contains(searchText) ||
          category.contains(searchText) ||
          userName.contains(searchText);

      // Category condition
      final matchesCategory =
          selectedCategory == 'All Categories' ||
          question['category']?.toString() == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void onSearchChanged(String value) {
    setState(() {
      _applyFilters();
    });
  }

  // =========================================================
  // CATEGORY CHANGE
  // =========================================================

  void onCategoryChanged(String? value) {
    if (value == null) return;

    setState(() {
      selectedCategory = value;
      _applyFilters();
    });
  }

  // =========================================================
  // CLEAR SEARCH + FILTER
  // =========================================================

  void clearFilters() {
    setState(() {
      searchController.clear();
      selectedCategory = 'All Categories';
      _applyFilters();
    });
  }

  // =========================================================
  // ASK QUESTION
  // =========================================================

  Future<void> openAskQuestion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AskQuestionScreen()),
    );

    await loadQuestions();
  }

  // =========================================================
  // QUESTION DETAIL
  // =========================================================

  void openQuestion(Map<String, dynamic> question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionDetailScreen(questionId: question['id']),
      ),
    );
  }

  void _navigateFromShell(int index) {
    switch (index) {
      case 0:
        Navigator.popUntil(context, (route) => route.isFirst);
      case 1:
        return;
      case 2:
        openAskQuestion();
      case 3:
        Navigator.pushNamed(context, '/dashboard');
      case 4:
        Navigator.pushNamed(context, '/dashboard');
      case 5:
        Navigator.pushNamed(context, '/dashboard');
      case 6:
        Navigator.pushNamed(context, '/dashboard');
      case 7:
        Navigator.pushNamed(context, '/dashboard');
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Questions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Ask Question',
            onPressed: openAskQuestion,
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      // =====================================================
      // FLOATING BUTTON
      // =====================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAskQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: Column(
        children: [
          // =================================================
          // SEARCH + FILTER SECTION
          // =================================================

          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                // SEARCH BOX
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search questions...',
                    prefixIcon: const Icon(Icons.search),

                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                _applyFilters();
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,

                    filled: true,

                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // CATEGORY FILTER
                Row(
                  children: [
                    Icon(Icons.filter_list, color: theme.colorScheme.primary),

                    const SizedBox(width: 8),

                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,

                          fillColor: isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.white,

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: onCategoryChanged,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // RESULT COUNT + CLEAR FILTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${questions.length} question${questions.length == 1 ? '' : 's'} found',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (searchController.text.isNotEmpty ||
                        selectedCategory != 'All Categories')
                      TextButton.icon(
                        onPressed: clearFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear Filters'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // =================================================
          // QUESTION LIST
          // =================================================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : questions.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: loadQuestions,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];

                        return AnimatedReveal(
                          delay: Duration(milliseconds: index * 45),
                          child: _buildQuestionCard(question, theme),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? StudentBottomNavigation(selectedIndex: 1, onSelected: _navigateFromShell)
          : null,
    );
  }

  // =========================================================
  // QUESTION CARD
  // =========================================================

  Widget _buildQuestionCard(Map<String, dynamic> question, ThemeData theme) {
    final title = question['title']?.toString() ?? 'Untitled Question';

    final category = question['category']?.toString() ?? 'General';

    final userName = question['user_name']?.toString() ?? 'Student';

    final description = question['description']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openQuestion(question),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QUESTION ICON
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.question_mark,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 14),

              // QUESTION CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // DESCRIPTION
                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                    const SizedBox(height: 10),

                    // CATEGORY + USER
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Text(
                          'Asked by $userName',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ARROW
              Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState(ThemeData theme) {
    final hasFilter =
        searchController.text.trim().isNotEmpty ||
        selectedCategory != 'All Categories';

    return RefreshIndicator(
      onRefresh: loadQuestions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),

          Icon(
            hasFilter
                ? Icons.search_off_rounded
                : Icons.question_answer_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),

          const SizedBox(height: 18),

          Text(
            hasFilter ? 'No matching questions' : 'No questions found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            hasFilter
                ? 'Try a different search keyword or category.'
                : 'Be the first student to ask a question!',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 20),

          if (hasFilter)
            Center(
              child: OutlinedButton.icon(
                onPressed: clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ),
        ],
      ),
    );
  }
}
