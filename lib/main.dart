import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_app/features/shared/welcome_page.dart';
import 'package:bus_app/features/user/user_home/home_page.dart';
import 'package:bus_app/features/user/ask_location.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rirtlktsgqoadapzhcuk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpcnRsa3RzZ3FvYWRhcHpoY3VrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNjA5MzIsImV4cCI6MjA1NTYzNjkzMn0.WhfE6GhKsofb_BFmWQ_du3K1a1LdlSZnB3U1_OEPYtM',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  bool _isAppReady = false;
  Widget _initialScreen = const CircularProgressIndicator();

  @override
  void initState() {
    super.initState();
    _initAppLinks();
    _determineInitialScreen();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAppLink(appLink);
      });
    }

    _appLinks.uriLinkStream.listen((uri) {
      if (mounted) {
        _handleAppLink(uri);
      }
    });

    setState(() {
      _isAppReady = true;
    });
  }

  void _handleAppLink(Uri uri) {
    if (uri.path == '/auth/callback' && _isAppReady) {
      Navigator.pushNamedAndRemoveUntil(context, '/location', (route) => false);
    }
  }

  Future<void> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      await Supabase.instance.client.auth.refreshSession();
      if (user.emailConfirmedAt != null) {
        if (isFirstTime) {
          prefs.setBool('isFirstTime', false);
          _setInitialScreen(const WelcomePage());
        } else {
          _setInitialScreen(const HomePage());
        }
      } else {
        _setInitialScreen(const WelcomePage());
      }
    } else {
      _setInitialScreen(const WelcomePage());
    }
  }

  void _setInitialScreen(Widget screen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initialScreen = screen;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Busway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Instrument Sans',
      ),
      home: _initialScreen,
      routes: {
        '/location': (context) => const AskLocationScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
