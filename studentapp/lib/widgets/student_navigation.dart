import 'package:flutter/material.dart';

class StudentNavigation extends StatelessWidget {
  const StudentNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.userName,
    required this.userInitial,
    this.notificationCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String userName;
  final String userInitial;
  final int notificationCount;

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.grid_view_rounded, label: 'Dashboard'),
    (icon: Icons.forum_rounded, label: 'Community'),
    (icon: Icons.add_circle_outline_rounded, label: 'Ask Question'),
    (icon: Icons.library_books_rounded, label: 'Resources'),
    (icon: Icons.insights_rounded, label: 'My Activity'),
    (icon: Icons.notifications_rounded, label: 'Notifications'),
    (icon: Icons.person_rounded, label: 'Profile'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 204,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? const Color(0xFF11132B)
            : const Color(0xFF171A3A),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 22)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 6, 26),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Student Help\nCommunity',
                    style: TextStyle(color: Colors.white, height: 1.05, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: selected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 18, color: selected ? Colors.white : Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item.label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
                        if (index == 5 && notificationCount > 0)
                          Container(
                            width: 17,
                            height: 17,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Color(0xFFFB7185), shape: BoxShape.circle),
                            child: Text(notificationCount > 9 ? '9+' : '$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(13)),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: scheme.secondary, child: Text(userInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(userName.isEmpty ? 'Student' : userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.forum_rounded, 'Community'),
      (Icons.add_rounded, 'Ask'),
      (Icons.notifications_rounded, 'Alerts'),
      (Icons.person_rounded, 'Profile'),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: scheme.brightness == Brightness.dark ? const Color(0xFF171936) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.16), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = selectedIndex == index;
            return GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(horizontal: selected ? 15 : 10, vertical: 9),
                decoration: BoxDecoration(color: selected ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [Icon(items[index].$1, size: 19, color: selected ? Colors.white : scheme.onSurfaceVariant), if (selected) ...[const SizedBox(width: 5), Text(items[index].$2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]]),
              ),
            );
          }),
        ),
      ),
    );
  }
}
