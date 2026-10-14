import 'package:flutter/material.dart';

void main() {
  runApp(const StudentHelpPortfolioApp());
}

class StudentHelpPortfolioApp extends StatelessWidget {
  const StudentHelpPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Help Community Portfolio',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF7F7FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6858E8),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const PortfolioHome(),
    );
  }
}

class PortfolioHome extends StatefulWidget {
  const PortfolioHome({super.key});

  @override
  State<PortfolioHome> createState() => _PortfolioHomeState();
}

class _PortfolioHomeState extends State<PortfolioHome> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey homeKey = GlobalKey();
  final GlobalKey aboutKey = GlobalKey();
  final GlobalKey featuresKey = GlobalKey();
  final GlobalKey workflowKey = GlobalKey();
  final GlobalKey screensKey = GlobalKey();
  final GlobalKey techKey = GlobalKey();

  int activeNav = 0;

  final navItems = const [
    'Home',
    'About',
    'Features',
    'Workflow',
    'Screens',
    'Tech',
  ];

  final navIcons = const [
    Icons.home_rounded,
    Icons.info_outline_rounded,
    Icons.auto_awesome_rounded,
    Icons.alt_route_rounded,
    Icons.phone_android_rounded,
    Icons.code_rounded,
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void goTo(int index) {
    final keys = [
      homeKey,
      aboutKey,
      featuresKey,
      workflowKey,
      screensKey,
      techKey,
    ];

    final targetContext = keys[index].currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.06,
      );
    }

    setState(() => activeNav = index);
  }

  void showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 15),
                for (int i = 0; i < navItems.length; i++)
                  ListTile(
                    leading: Icon(navIcons[i], color: const Color(0xFF6858E8)),
                    title: Text(
                      navItems[i],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    selected: activeNav == i,
                    selectedTileColor: const Color(0xFFEDEAFC),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      goTo(i);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 820;

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Container(key: homeKey, child: _heroSection(isMobile)),
                    Container(key: aboutKey, child: _aboutSection(isMobile)),
                    Container(
                      key: featuresKey,
                      child: _featuresSection(isMobile),
                    ),
                    Container(
                      key: workflowKey,
                      child: _workflowSection(isMobile),
                    ),
                    Container(
                      key: screensKey,
                      child: _screensSection(isMobile),
                    ),
                    _adminSection(isMobile),
                    Container(key: techKey, child: _techSection(isMobile)),
                    _architectureSection(isMobile),
                    _highlightsSection(isMobile),
                    _futureSection(isMobile),
                    _footerSection(isMobile),
                  ],
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: _navBar(isMobile)),
            ],
          );
        },
      ),
      floatingActionButton: MediaQuery.sizeOf(context).width < 820
          ? FloatingActionButton(
              onPressed: showMenu,
              backgroundColor: const Color(0xFF6858E8),
              foregroundColor: Colors.white,
              child: const Icon(Icons.menu_rounded),
            )
          : null,
    );
  }

  Widget _navBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 42,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _brand(),
            const SizedBox(width: 11),
            const Expanded(
              child: Text(
                'Student Help Community',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF20213E),
                ),
              ),
            ),
            if (!isMobile)
              Row(
                children: List.generate(
                  navItems.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: TextButton(
                      onPressed: () => goTo(index),
                      style: TextButton.styleFrom(
                        foregroundColor: activeNav == index
                            ? const Color(0xFF6858E8)
                            : const Color(0xFF666879),
                        backgroundColor: activeNav == index
                            ? const Color(0xFFEDEAFC)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        navItems[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _brand() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6858E8), Color(0xFF8B7FF4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _heroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 70,
        isMobile ? 115 : 145,
        isMobile ? 20 : 70,
        70,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11132E), Color(0xFF2D275B), Color(0xFF6858E8)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroText(isMobile),
                    const SizedBox(height: 40),
                    _devicePreview(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _heroText(isMobile)),
                    const SizedBox(width: 45),
                    Expanded(child: Center(child: _devicePreview())),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _heroText(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
          ),
          child: const Text(
            'FLUTTER • DART • SQLITE • ANDROID • CHROME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 21),
        Text(
          'Student Help\nCommunity',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 46 : 66,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 21),
        Text(
          'A cross-platform peer-learning application where students can ask questions, answer discussions, share learning resources, save useful content and build reputation through community participation.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.77),
            fontSize: isMobile ? 16 : 18,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 27),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroBadge(icon: Icons.storage_rounded, text: 'SQLite only'),
            _HeroBadge(icon: Icons.devices_rounded, text: 'Mobile + Web'),
            _HeroBadge(
              icon: Icons.admin_panel_settings_outlined,
              text: 'Admin control',
            ),
          ],
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => goTo(2),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5142CF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Explore Features',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => goTo(4),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.phone_android_rounded),
              label: const Text(
                'View Screens',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _devicePreview() {
    return Container(
      width: 294,
      height: 585,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B14),
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 48,
            offset: const Offset(0, 23),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(34),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 32,
              color: const Color(0xFF6858E8),
              child: Center(
                child: Container(
                  width: 78,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFE6E2FF),
                          child: Icon(
                            Icons.school_rounded,
                            color: Color(0xFF6858E8),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF75768B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEBFF),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF6858E8),
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Student Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF20213D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6858E8), Color(0xFF8A7CF3)],
                        ),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contribution Score',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '10 points',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '#2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B2C48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _phoneStat('Questions', '2', Icons.help_outline),
                        const SizedBox(width: 7),
                        _phoneStat('Answers', '4', Icons.forum_outlined),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _phoneStat('Resources', '2', Icons.menu_book_outlined),
                        const SizedBox(width: 7),
                        _phoneStat('Saved', '3', Icons.bookmark_outline),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B2C48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _miniRank('1', 'Akhil', '18'),
                    _miniRank('2', 'Padmini', '10', selected: true),
                    _miniRank('3', 'Meena', '8'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneStat(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE8E7F3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF6858E8)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniRank(
    String rank,
    String name,
    String points, {
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEDEAFC) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selected ? const Color(0xFFC9C3FF) : const Color(0xFFE8E7F3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFE7E3FF),
            child: Text(
              rank,
              style: const TextStyle(
                color: Color(0xFF6858E8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '$points pts',
            style: const TextStyle(
              color: Color(0xFF6858E8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutSection(bool isMobile) {
    return _section(
      isMobile: isMobile,
      eyebrow: 'ABOUT THE PROJECT',
      title: 'One place to learn, ask, answer and contribute',
      subtitle: 'Student Help Community is a Flutter-based peer-learning application created to make student-to-student academic support organized and accessible.',
      child: isMobile
          ? Column(
              children: [
                _aboutCopy(),
                const SizedBox(height: 25),
                _statsPanel(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _aboutCopy()),
                const SizedBox(width: 36),
                Expanded(child: _statsPanel()),
              ],
            ),
    );
  }

  Widget _aboutCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project objective',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Color(0xFF22243F),
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'The platform brings together questions, answers, learning resources, saved content, notifications and community reputation in a single student-focused experience.',
          style: TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF6D6F81)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Key idea',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2C2D49),
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Students do not only consume information. They can contribute knowledge, earn points for useful participation and see how they rank within the community.',
          style: TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF717387)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: const [
            _SoftPill(text: 'Questions'),
            _SoftPill(text: 'Answers'),
            _SoftPill(text: 'Resources'),
            _SoftPill(text: 'Saved Content'),
            _SoftPill(text: 'Notifications'),
            _SoftPill(text: 'Leaderboard'),
          ],
        ),
      ],
    );
  }

  Widget _statsPanel() {
    return Wrap(
      spacing: 13,
      runSpacing: 13,
      children: const [
        _StatTile(value: '2', label: 'User roles', icon: Icons.groups_rounded),
        _StatTile(
          value: '8+',
          label: 'Core modules',
          icon: Icons.view_quilt_outlined,
        ),
        _StatTile(
          value: 'SQLite',
          label: 'Local database',
          icon: Icons.storage_rounded,
        ),
        _StatTile(
          value: '2',
          label: 'Target platforms',
          icon: Icons.devices_rounded,
        ),
      ],
    );
  }

  Widget _featuresSection(bool isMobile) {
    const items = [
      _FeatureData(
        Icons.lock_outline_rounded,
        'Authentication',
        'Local registration and login flow backed by SQLite.',
      ),
      _FeatureData(
        Icons.help_outline_rounded,
        'Questions',
        'Students can post, browse, search and open questions.',
      ),
      _FeatureData(
        Icons.forum_outlined,
        'Answers',
        'Community members can answer questions and mark helpful answers.',
      ),
      _FeatureData(
        Icons.library_books_outlined,
        'Resource Hub',
        'Share URLs, photos, PDFs, documents, videos and other files.',
      ),
      _FeatureData(
        Icons.bookmark_outline_rounded,
        'Saved Content',
        'Save useful questions and resources for quick access.',
      ),
      _FeatureData(
        Icons.notifications_none_rounded,
        'Notifications',
        'Show local updates when relevant community actions happen.',
      ),
      _FeatureData(
        Icons.emoji_events_outlined,
        'Contribution Score',
        'Earn points through questions, answers, resources and helpful votes.',
      ),
      _FeatureData(
        Icons.leaderboard_outlined,
        'Leaderboard',
        'Display rankings and highlight top community contributors.',
      ),
      _FeatureData(
        Icons.settings_outlined,
        'Settings',
        'Manage theme and notification preferences.',
      ),
      _FeatureData(
        Icons.admin_panel_settings_outlined,
        'Admin Dashboard',
        'Manage users, questions, answers, resources and analytics.',
      ),
    ];

    return _section(
      isMobile: isMobile,
      eyebrow: 'CORE FEATURES',
      title: 'Complete features already built into the app',
      subtitle: 'This portfolio describes the actual modules developed in the Student Help Community project.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1120
              ? 3
              : constraints.maxWidth >= 720
              ? 2
              : 1;
          final width = (constraints.maxWidth - ((columns - 1) * 15)) / columns;

          return Wrap(
            spacing: 15,
            runSpacing: 15,
            children: items.map((item) {
              return SizedBox(
                width: width,
                child: _FeatureCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _workflowSection(bool isMobile) {
    const steps = [
      _WorkflowData(
        '01',
        'Register / Login',
        Icons.person_add_alt_1_rounded,
        'Create a student account and enter the community.',
      ),
      _WorkflowData(
        '02',
        'Ask a Question',
        Icons.help_outline_rounded,
        'Post an academic doubt with title, category and description.',
      ),
      _WorkflowData(
        '03',
        'Answer & Help',
        Icons.forum_rounded,
        'Community members open questions and share useful answers.',
      ),
      _WorkflowData(
        '04',
        'Share Resources',
        Icons.upload_file_rounded,
        'Add useful links, images, PDFs, documents, videos or files.',
      ),
      _WorkflowData(
        '05',
        'Save & Get Notified',
        Icons.notifications_active_outlined,
        'Save useful content and receive relevant in-app updates.',
      ),
      _WorkflowData(
        '06',
        'Earn Points',
        Icons.emoji_events_outlined,
        'Contribution points build reputation and affect the leaderboard.',
      ),
    ];

    return _section(
      isMobile: isMobile,
      eyebrow: 'USER WORKFLOW',
      title: 'How the community works',
      subtitle:
          'The main flow is designed around continuous student participation.',
      child: Column(
        children: List.generate(steps.length, (index) {
          return _WorkflowRow(
            data: steps[index],
            showLine: index != steps.length - 1,
            isMobile: isMobile,
          );
        }),
      ),
    );
  }

  Widget _screensSection(bool isMobile) {
    const screens = [
      _ScreenData(
        Icons.login_rounded,
        'Login / Register',
        'Secure entry point for students using local account data.',
      ),
      _ScreenData(
        Icons.dashboard_rounded,
        'User Dashboard',
        'Welcome, activity cards, contribution score, leaderboard and recent questions.',
      ),
      _ScreenData(
        Icons.help_outline_rounded,
        'Questions',
        'Browse and search the community question feed.',
      ),
      _ScreenData(
        Icons.forum_outlined,
        'Question Details',
        'Open a question and see its complete answer discussion.',
      ),
      _ScreenData(
        Icons.menu_book_rounded,
        'Resources',
        'Explore links and stored learning files with save options.',
      ),
      _ScreenData(
        Icons.bookmark_rounded,
        'Saved Resources',
        'Manage resources saved by the current student.',
      ),
      _ScreenData(
        Icons.notifications_rounded,
        'Notifications',
        'View local notifications generated by community activity.',
      ),
      _ScreenData(
        Icons.person_outline_rounded,
        'Profile',
        'Edit student profile, view contribution score and leaderboard options.',
      ),
      _ScreenData(
        Icons.leaderboard_rounded,
        'Leaderboard',
        'Show current rank, top contributors and point rules.',
      ),
      _ScreenData(
        Icons.admin_panel_settings_rounded,
        'Admin Dashboard',
        'Review users, questions, answers, resources and analytics.',
      ),
    ];

    return _section(
      isMobile: isMobile,
      eyebrow: 'SCREEN SHOWCASE',
      title: 'Built for phone screens and Chrome',
      subtitle: 'Responsive layouts keep the same project story readable on mobile, tablet and desktop browser sizes.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 700
              ? 2
              : 1;
          final width = (constraints.maxWidth - ((columns - 1) * 15)) / columns;

          return Wrap(
            spacing: 15,
            runSpacing: 15,
            children: screens.asMap().entries.map((entry) {
              return SizedBox(
                width: width,
                child: _ScreenCard(number: entry.key + 1, data: entry.value),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _adminSection(bool isMobile) {
    const items = [
      _AdminData(Icons.people_outline, 'Users'),
      _AdminData(Icons.help_outline, 'Questions'),
      _AdminData(Icons.question_answer_outlined, 'Answers'),
      _AdminData(Icons.menu_book_outlined, 'Resources'),
      _AdminData(Icons.analytics_outlined, 'Analytics'),
      _AdminData(Icons.visibility_outlined, 'View details'),
      _AdminData(Icons.delete_outline, 'Delete content'),
      _AdminData(Icons.refresh_rounded, 'Refresh data'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 70,
        vertical: 70,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDEAFC), Color(0xFFF7F7FC)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _adminCopy(),
                    const SizedBox(height: 26),
                    _adminCards(items),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _adminCopy()),
                    const SizedBox(width: 44),
                    Expanded(child: _adminCards(items)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _adminCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ADMIN PANEL',
          style: TextStyle(
            color: Color(0xFF6858E8),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Centralized moderation & monitoring',
          style: TextStyle(
            fontSize: 35,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: Color(0xFF21233F),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'The administrator can inspect registered users and community content, open detailed views and remove questions, answers or resources when required.',
          style: TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF6C6E81)),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E0F4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF6858E8), size: 27),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Administrative actions stay connected to the same local SQLite application data.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF66687C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminCards(List<_AdminData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFE3E1F3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEAFC),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(item.icon, color: const Color(0xFF6858E8)),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF31324C),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF6858E8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _techSection(bool isMobile) {
    const tech = [
      _TechData('Flutter', Icons.flutter_dash_rounded),
      _TechData('Dart', Icons.code_rounded),
      _TechData('SQLite', Icons.storage_rounded),
      _TechData('sqflite', Icons.table_chart_outlined),
      _TechData('Android', Icons.android_rounded),
      _TechData('Chrome/Web', Icons.language_rounded),
      _TechData('File Picker', Icons.attach_file_rounded),
      _TechData('URL Launcher', Icons.open_in_new_rounded),
    ];

    return _section(
      isMobile: isMobile,
      eyebrow: 'TECH STACK',
      title: 'Technology used',
      subtitle: 'The project uses a compact cross-platform Flutter stack with SQLite as the main local data store.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tech.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE5E4EF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 21, color: const Color(0xFF6858E8)),
                const SizedBox(width: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E304A),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _architectureSection(bool isMobile) {
    final cards = [
      _ArchitectureCard(
        '01',
        'Presentation Layer',
        Icons.phone_android_rounded,
        'Flutter screens provide responsive interfaces for students and administrators.',
      ),
      _ArchitectureCard(
        '02',
        'Service Layer',
        Icons.miscellaneous_services_outlined,
        'Authentication, question, resource, notification, settings and leaderboard services organize application logic.',
      ),
      _ArchitectureCard(
        '03',
        'Database Layer',
        Icons.storage_outlined,
        'SQLite stores users, questions, answers, resources, saved items, notifications and settings.',
      ),
    ];

    return _section(
      isMobile: isMobile,
      eyebrow: 'ARCHITECTURE',
      title: 'Clean local-first structure',
      subtitle: 'The project separates UI, services and database responsibilities while keeping the application self-contained.',
      child: isMobile
          ? Column(children: cards)
          : Row(
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _highlightsSection(bool isMobile) {
    final cards = [
      _HighlightData(
        Icons.devices_other_rounded,
        'Responsive',
        'The portfolio adapts to Android, tablet and Chrome screen widths.',
      ),
      _HighlightData(
        Icons.offline_bolt_outlined,
        'SQLite-first',
        'Core community data is kept in the application database instead of Firebase.',
      ),
      _HighlightData(
        Icons.auto_awesome_rounded,
        'More than CRUD',
        'The final project includes reputation, saved content, notifications and moderation.',
      ),
    ];

    return _section(
      isMobile: isMobile,
      eyebrow: 'PROJECT HIGHLIGHTS',
      title: 'What makes the project stand out',
      subtitle: 'The finished application demonstrates both UI work and application-level functionality.',
      child: isMobile
          ? Column(
              children: List.generate(cards.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == cards.length - 1 ? 0 : 14,
                  ),
                  child: _HighlightCard(data: cards[index]),
                );
              }),
            )
          : Row(
              children: cards
                  .map(
                    (data) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: _HighlightCard(data: data),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _futureSection(bool isMobile) {
    const improvements = [
      'Cloud synchronization between devices',
      'Email / push notification integration',
      'Advanced file preview and sharing',
      'More detailed admin reports',
      'Role-based moderation permissions',
      'Expanded student profiles and achievements',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 70,
        vertical: 70,
      ),
      color: const Color(0xFFF0EFF8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FUTURE ENHANCEMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Color(0xFF6858E8),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Next ideas for the project',
                style: TextStyle(
                  fontSize: isMobile ? 31 : 40,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF21233F),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The current application is a strong local-first foundation. Possible next iterations can add the following capabilities.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.65,
                  color: Color(0xFF6B6D80),
                ),
              ),
              const SizedBox(height: 27),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: improvements.map((item) {
                  return Container(
                    width: isMobile ? double.infinity : 390,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: const Color(0xFFE0DEEE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF6858E8),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF44465F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 70,
        44,
        isMobile ? 20 : 70,
        35,
      ),
      color: const Color(0xFF11132E),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _brand(),
                  const SizedBox(width: 10),
                  const Text(
                    'Student Help Community',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Flutter • Dart • SQLite • Android • Chrome',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Learn together. Contribute together.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.36),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required bool isMobile,
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 70,
        vertical: 70,
      ),
      color: const Color(0xFFF7F7FC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.45,
                  color: Color(0xFF6858E8),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 31 : 41,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF21233F),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.65,
                    color: Color(0xFF6B6D80),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String text;

  const _SoftPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5648CF),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 225,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E3EF)),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF6858E8)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF252640),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF77798C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureData(this.icon, this.title, this.body);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 192,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E5EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: const Color(0xFF6858E8), size: 23),
          ),
          const SizedBox(height: 13),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A2C47),
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Text(
              data.body,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.55,
                color: Color(0xFF707286),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowData {
  final String step;
  final String title;
  final IconData icon;
  final String body;

  const _WorkflowData(this.step, this.title, this.icon, this.body);
}

class _WorkflowRow extends StatelessWidget {
  final _WorkflowData data;
  final bool showLine;
  final bool isMobile;

  const _WorkflowRow({
    required this.data,
    required this.showLine,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, color: const Color(0xFF6858E8)),
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: isMobile ? 57 : 48,
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  color: const Color(0xFFD9D5F6),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 13),
            padding: const EdgeInsets.fromLTRB(17, 15, 18, 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFE5E4EF)),
            ),
            child: Row(
              children: [
                Text(
                  data.step,
                  style: const TextStyle(
                    color: Color(0xFFB6B3C8),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2A2C47),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data.body,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.55,
                          color: Color(0xFF707286),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenData {
  final IconData icon;
  final String title;
  final String body;

  const _ScreenData(this.icon, this.title, this.body);
}

class _ScreenCard extends StatelessWidget {
  final int number;
  final _ScreenData data;

  const _ScreenCard({required this.number, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 213,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE5E4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEDEAFC),
                child: Icon(data.icon, color: const Color(0xFF6858E8)),
              ),
              const Spacer(),
              Text(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB7B5C5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A2C47),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            data.body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.55,
              color: Color(0xFF707286),
            ),
          ),
          const Spacer(),
          const Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 15,
                color: Color(0xFF6858E8),
              ),
              SizedBox(width: 5),
              Text(
                'Responsive module',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6858E8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminData {
  final IconData icon;
  final String title;

  const _AdminData(this.icon, this.title);
}

class _TechData {
  final String name;
  final IconData icon;

  const _TechData(this.name, this.icon);
}

class _ArchitectureCard extends StatelessWidget {
  final String step;
  final String title;
  final IconData icon;
  final String body;

  const _ArchitectureCard(this.step, this.title, this.icon, this.body);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 246,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF6858E8)),
              ),
              const Spacer(),
              Text(
                step,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB9B7C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A2C47),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: Color(0xFF707286),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightData {
  final IconData icon;
  final String title;
  final String body;

  const _HighlightData(this.icon, this.title, this.body);
}

class _HighlightCard extends StatelessWidget {
  final _HighlightData data;

  const _HighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 29, color: const Color(0xFF6858E8)),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A2C47),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF707286),
            ),
          ),
        ],
      ),
    );
  }
}
