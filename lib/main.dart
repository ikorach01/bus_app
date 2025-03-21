 import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/shared/welcome_page.dart';
import 'package:bus_app/features/user/user_home/home_page.dart';
import 'package:bus_app/features/user/ask_location.dart';
import 'package:bus_app/features/shared/role_selection.dart';
import 'package:bus_app/features/driver/auth/add_information.dart';
import 'package:app_links/app_links.dart';

// Global function to test database connection and permissions
Future<void> testDatabaseConnection() async {
  try {
    print('Testing Supabase database connection...');
    final supabase = Supabase.instance.client;
    
    // Test 1: Check if we can query the users table
    print('Test 1: Querying users table...');
    try {
      final result = await supabase.from('users').select('count').limit(1);
      print('Users table query result: $result');
    } catch (e) {
      print('Error querying users table: $e');
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
      await supabase.from('users').insert({
        'id': testId,
        'email': 'test@example.com',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Test insert successful');
      
      // Clean up test record
      await supabase.from('users').delete().eq('id', testId);
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
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
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
            _setInitialScreen(const AddInformationPage());
          } else if (role == 'passenger') {
            _setInitialScreen(const AskLocationScreen());
          }
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
