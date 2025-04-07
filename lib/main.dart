import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/shared/welcome_page.dart';
import 'package:bus_app/features/user/user_home/home_page.dart';
import 'package:bus_app/features/user/ask_location.dart';
import 'package:bus_app/features/shared/role_selection.dart';
import 'package:bus_app/features/driver/auth/add_information.dart';
import 'package:bus_app/features/driver/driver_home/home_page2.dart';
import 'package:bus_app/features/user/login_page.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bus_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:bus_app/providers/settings_provider.dart';
import 'package:bus_app/features/driver/driver_home/realtime_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global function to test database connection and permissions
Future<void> testDatabaseConnection() async {
  try {
    print('Testing Supabase database connection...');
    final supabase = Supabase.instance.client;
    
    // Test 1: Check if we can query the user_profiles table
    print('Test 1: Querying user_profiles table...');
    try {
      final result = await supabase.from('user_profiles').select('count').limit(1);
      print('User_profiles table query result: $result');
    } catch (e) {
      print('Error querying user_profiles table: $e');
    }
    
    // Test 2: Check database schema
    print('Test 2: Checking database schema...');
    try {
      final tables = await supabase
          .from('information_schema.tables')
          .select('table_name, table_schema')
          .eq('table_schema', 'public');
      print('Available tables: $tables');
    } catch (e) {
      print('Error checking schema: $e');
    }
    
    // Test 3: Check RLS policies
    print('Test 3: Checking RLS policies...');
    try {
      final policies = await supabase
          .from('pg_policies')
          .select('tablename, policyname, cmd, qual')
          .limit(10);
      print('RLS policies: $policies');
    } catch (e) {
      print('Error checking RLS policies: $e');
    }
    
    // Test 4: Try to insert a test record
    print('Test 4: Attempting test insert...');
    try {
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await supabase.from('user_profiles').insert({
        'id': testId,
        'email': 'test@example.com',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Test insert successful');
      
      // Clean up test record
      await supabase.from('user_profiles').delete().eq('id', testId);
      print('Test record deleted');
    } catch (e) {
      print('Error with test insert: $e');
      if (e is PostgrestException) {
        print('PostgrestException code: ${e.code}');
        print('PostgrestException message: ${e.message}');
        print('PostgrestException details: ${e.details}');
      }
    }
    
    print('Database tests completed');
  } catch (e) {
    print('Error during database tests: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rirtlktsgqoadapzhcuk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpcnRsa3RzZ3FvYWRhcHpoY3VrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNjA5MzIsImV4cCI6MjA1NTYzNjkzMn0.WhfE6GhKsofb_BFmWQ_du3K1a1LdlSZnB3U1_OEPYtM',
  );
  
  // Run database tests
  await testDatabaseConnection();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => RealtimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        await Supabase.instance.client.auth.refreshSession();
        if (user.emailConfirmedAt != null) {
          final userData = user.userMetadata;
          final role = userData?['role'] as String?;

          if (role == null) {
            _setInitialScreen(RoleSelectionPage(
              userId: user.id,
              userEmail: user.email ?? '',
              userPhone: userData?['phone'] as String? ?? '',
            ));
          } else {
            if (role == 'driver') {
              // Check if driver has already completed registration
              try {
                // First, check SharedPreferences for a flag indicating the driver is registered
                final prefs = await SharedPreferences.getInstance();
                final isDriverRegistered = prefs.getBool('driver_${user.id}_registered') ?? false;
                
                if (isDriverRegistered) {
                  // If we have a local record that the driver is registered, go directly to HomePage2
                  _setInitialScreen(const HomePage2());
                  print('Driver registered (from SharedPreferences), redirecting to HomePage2');
                  return;
                }
                
                // If no local record, try a direct query to check if the driver exists
                final response = await Supabase.instance.client
                    .from('drivers')
                    .select('id')
                    .eq('id', user.id);
                
                // If we get a non-empty response, the driver exists
                if (response != null && response.isNotEmpty) {
                  // Driver exists in the database, go to HomePage2
                  _setInitialScreen(const HomePage2());
                  print('Driver exists, redirecting to HomePage2');
                  
                  // Save this information to SharedPreferences for future app launches
                  await prefs.setBool('driver_${user.id}_registered', true);
                } else {
                  // Driver doesn't exist in database, show registration page
                  _setInitialScreen(const AddInformationPage());
                  print('Driver does not exist, redirecting to AddInformationPage');
                }
              } catch (e) {
                print('Error checking driver existence: $e');
                
                // If there's an error, try direct navigation to HomePage2
                // This is a safer default since we want to avoid making the user
                // register multiple times
                _setInitialScreen(const HomePage2());
              }
            } else if (role == 'passenger') {
              _setInitialScreen(const AskLocationScreen());
            }
          }
        } else {
          _setInitialScreen(const WelcomePage());
        }
      } catch (e) {
        print('Error refreshing session: $e');
        // If session refresh fails, go to login page
        _setInitialScreen(const LoginPage());
      }
    } else {
      _setInitialScreen(const LoginPage());
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
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          title: 'Busway',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Instrument Sans',
            brightness: settingsProvider.darkMode ? Brightness.dark : Brightness.light,
          ),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', ''), // English, no country code
            const Locale('ar', ''), // Arabic, no country code
          ],
          locale: Locale(settingsProvider.language, ''),
          home: _initialScreen,
          routes: {
            '/location': (context) => const AskLocationScreen(),
            '/home': (context) => const HomePage(),
          },
        );
      }
    );
  }
}