import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:quickquiz/services/theme_service.dart';
import 'package:quickquiz/services/auth_service.dart';
import 'package:quickquiz/pages/auth_page.dart';
import 'package:quickquiz/pages/home_page.dart';
import 'package:quickquiz/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Initialize theme service
  await ThemeService().loadThemeSettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final seedColor = themeService.primaryColor;
    
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            // Always use the user's selected color, not dynamic colors
            lightColorScheme = ColorScheme.fromSeed(seedColor: seedColor);
            darkColorScheme = ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            );

            return MaterialApp(
              title: 'QuickQuiz',
              debugShowCheckedModeBanner: false,
              themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                appBarTheme: AppBarTheme(
                  backgroundColor: seedColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  surfaceTintColor: seedColor,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  iconTheme: IconThemeData(color: Colors.white),
                ),
                cardTheme: CardThemeData(
                  elevation: 2,
                  shadowColor: lightColorScheme.shadow.withValues(alpha: 0.1),
                  surfaceTintColor: lightColorScheme.surfaceTint,
                  color: lightColorScheme.surface,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: seedColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: lightColorScheme.shadow.withValues(alpha: 0.2),
                  ),
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: lightColorScheme.primary,
                  foregroundColor: lightColorScheme.onPrimary,
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  backgroundColor: lightColorScheme.surface,
                  selectedItemColor: lightColorScheme.primary,
                  unselectedItemColor: lightColorScheme.onSurface.withOpacity(0.6),
                  type: BottomNavigationBarType.fixed,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                appBarTheme: AppBarTheme(
                  backgroundColor: seedColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  surfaceTintColor: seedColor,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  iconTheme: IconThemeData(color: Colors.white),
                ),
                cardTheme: CardThemeData(
                  elevation: 4,
                  shadowColor: darkColorScheme.shadow.withValues(alpha: 0.3),
                  surfaceTintColor: darkColorScheme.surfaceTint,
                  color: darkColorScheme.surface,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: seedColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: darkColorScheme.shadow.withValues(alpha: 0.3),
                  ),
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: darkColorScheme.primary,
                  foregroundColor: darkColorScheme.onPrimary,
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  backgroundColor: darkColorScheme.surface,
                  selectedItemColor: darkColorScheme.primary,
                  unselectedItemColor: darkColorScheme.onSurface.withOpacity(0.6),
                  type: BottomNavigationBarType.fixed,
                ),
              ),
              home: const SplashPage(),
              builder: (context, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                    systemNavigationBarColor: Theme.of(context).colorScheme.surface,
                    systemNavigationBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                );
                return child!;
              },
            );
          },
        );
      },
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
