import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aptitude_quiz/pages/home_page.dart';
import 'pages/auth_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const MyApp());
}

const _brandBlue = Color(0xFF1E88E5);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: _brandBlue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _brandBlue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Aptitude Quiz',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              shadowColor: lightColorScheme.shadow.withValues(alpha: 0.1),
              surfaceTintColor: lightColorScheme.surfaceTint,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shadowColor: lightColorScheme.shadow.withValues(alpha: 0.2),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 4,
              shadowColor: darkColorScheme.shadow.withValues(alpha: 0.3),
              surfaceTintColor: darkColorScheme.surfaceTint,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                shadowColor: darkColorScheme.shadow.withValues(alpha: 0.4),
              ),
            ),
          ),
          home: const AuthCheckPage(),
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
    // Show splash for a moment
    await Future.delayed(const Duration(seconds: 5));

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon with background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.quiz,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Title
              Text(
                'QuickQuiz',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Test Your Knowledge',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator with modern styling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
