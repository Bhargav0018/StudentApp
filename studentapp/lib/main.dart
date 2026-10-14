import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';

import 'theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StudentHelpCommunityApp());
}

class StudentHelpCommunityApp extends StatelessWidget {
  const StudentHelpCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'Student Help Community',

          // ======================================================
          // THEME MODE
          // ======================================================
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // ======================================================
          // LIGHT THEME
          // ======================================================
          theme: AppTheme.light, /* ThemeData(
            useMaterial3: true,

            fontFamily: 'Arial',

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),

            scaffoldBackgroundColor: const Color(0xFFF4F8F7),

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF173B3A),
              elevation: 0,
              centerTitle: false,
            ),

            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB)),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF0F766E),
                  width: 2,
                ),
              ),
            ),

            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF0F766E);
                }

                return Colors.grey.shade400;
              }),
            ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
              ),
            ),
          ),

          // ======================================================
          // DARK THEME
          // ======================================================
          darkTheme: ThemeData(
            useMaterial3: true,

            fontFamily: 'Arial',

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2DD4BF),
              brightness: Brightness.dark,
            ),

            scaffoldBackgroundColor: const Color(0xFF121212),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),

            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF172322),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            dividerTheme: const DividerThemeData(color: Color(0xFF333333)),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2DD4BF),
                  width: 2,
                ),
              ),
            ),

            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF2DD4BF);
                }  

                return Colors.grey;
              }),
            ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5EEAD4),
              ),
            ),
          ),

          */
          darkTheme: AppTheme.dark,

          // ======================================================
          // INITIAL ROUTE
          // ======================================================
          initialRoute: '/',

          // ======================================================
          // ROUTES
          // ======================================================
          routes: {
            '/': (context) => const SplashScreen(),

            '/login': (context) => const LoginScreen(),

            '/register': (context) => const RegisterScreen(),

            '/dashboard': (context) => const DashboardScreen(),

            // ADMIN LOGIN
            '/admin-login': (context) => const AdminLoginScreen(),

            // ADMIN DASHBOARD
            '/admin-dashboard': (context) => const AdminDashboardScreen(),
          },
        );
      },
    );
  }
}







