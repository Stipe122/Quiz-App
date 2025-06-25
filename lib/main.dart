import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quizapp/screens/auth/login_screen.dart';
import 'package:quizapp/screens/home/home_screen.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_wrapper.dart';

//password: quizapp2

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const QuizMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      navigatorObservers: [MyNavigatorObserver()],
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('PUSHED: ${route.settings.name ?? route.runtimeType}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('POPPED: ${route.settings.name ?? route.runtimeType}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('REMOVED: ${route.settings.name ?? route.runtimeType}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
        'REPLACED: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}
